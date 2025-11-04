import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/models/balance_model.dart';
import 'package:amaguexpress/src/models/cart_summary_model.dart';
import 'package:amaguexpress/src/models/fee_model.dart';
import 'package:amaguexpress/src/models/product_model.dart';
import 'package:amaguexpress/src/provider/db_provider.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/src/services/balance_service.dart';
import 'package:amaguexpress/src/services/market_service.dart';
import 'package:amaguexpress/src/services/payment_service.dart';

class CartSummaryController extends ChangeNotifier {
  final MarketService marketService = MarketService();

  final List<CartSummaryModel> _summaries = [];

  double _money = 0.0;

  double get money => _money;

  set money(double money) {
    _money = money;
    notifyListeners();
  }

  bool _inAsyncCall = false;

  bool _isSumaryTaxi = false;

  CartSummaryController({bool isSumaryTaxi = false}) {
    _isSumaryTaxi = isSumaryTaxi;
    load();
  }

  List<CartSummaryModel> get summaries => _summaries;

  bool get inAsyncCall => _inAsyncCall;

  bool get isSumaryTaxi => _isSumaryTaxi;

  set inAsyncCall(bool asyncCall) {
    _inAsyncCall = asyncCall;
    notifyListeners();
  }

  load() async {
    inAsyncCall = true;
    await loadDeliveryFee();
    await loadBalance();
    inAsyncCall = false;
  }

  List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  loadDeliveryFee() async {
    _products = await DBProvider.db
        .loadProducts(_isSumaryTaxi ? TypesCompany.taxi : TypesCompany.store);

    if (_products.isEmpty) return;

    double fromLgTaxi = 0.0, fromLtTaxi = 0.0;
    if (_isSumaryTaxi) {
      fromLtTaxi = _products[0].lt;
      fromLgTaxi = _products[0].lg;
    }

    var companyIds = [];
    for (ProductModel product in products) {
      if (!companyIds.contains(product.companyId)) {
        companyIds.add(product.companyId);
      }
    }
    _address = await DBProvider.db.loadAddress();
    if (_address == null) {
      _summaries.clear();
      return;
    }
    List<FeeModel> fees = await marketService.deliveryCost(
      companyIds.join(','),
      _address!.location.x,
      _address!.location.y,
      isSumaryTaxi: _isSumaryTaxi,
      fromLtTaxi: fromLtTaxi,
      fromLgTaxi: fromLgTaxi,
    );
    _summaries.clear();
    for (FeeModel fee in fees) {
      _summaries.add(CartSummaryModel(
          fee: fee,
          products:
              products.where((pr) => pr.companyId == fee.companyId).toList()));
    }
  }

  AddressModel? _address;

  Future<bool> buy(int typePayment) async {
    if (_address == null) {
      _summaries.clear();
      return false;
    }
    inAsyncCall = true;
    for (CartSummaryModel cartSummary in _summaries) {
      await marketService.buy(cartSummary, _address!, typePayment);
    }
    await DBProvider.db.deleteAllProduct(
        _isSumaryTaxi ? TypesCompany.taxi : TypesCompany.store);
    inAsyncCall = false;
    return true;
  }

  double get total {
    double total = 0.0;
    for (CartSummaryModel summary in summaries) {
      total += summary.total;
    }
    return total;
  }

  final BalanceService balanceService = BalanceService();

  loadBalance() async {
    BalanceModel? balance = await balanceService.getBalance();
    if (balance == null) return;
    money = balance.money;
  }

  final PaymentService paymentService = PaymentService();

  // Cabeceras con token para peticiones autenticadas
  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// ✅ Confirmación del pago PayPhone y compra
  Future<bool> confirmPayPhoneAndBuy(
      String transactionIdStr, String clientTxId) async {
    try {
      final token = PreferencesProvider().token;
      if (token.isEmpty) {
        if (kDebugMode) {
          print('❌ No hay token para confirmar PayPhone');
        }
        return false;
      }

      inAsyncCall = true;

      // PayPhone CONFIRM espera: { id: string, clientTxId: string }
      final uri = Uri.parse(
          'https://api.amaguexpress.com/api/client/payments/payphone/confirm');

      final resp = await http.post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode({
          'id': transactionIdStr, // string
          'clientTxId': clientTxId, // string
        }),
      );

      if (kDebugMode) {
        print(
            '✔️ PayPhone confirm response (${resp.statusCode}): ${resp.body}');
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final ok = await buy(TypesPayment.money);
        return ok;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Excepción en confirmPayPhoneAndBuy: $e');
      }
      return false;
    } finally {
      inAsyncCall = false;
    }
  }
}
