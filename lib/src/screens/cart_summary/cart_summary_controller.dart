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

  bool _isSummaryNat = false;

  // NAT: coordenadas explícitas de origen (ubicación real de la tienda seleccionada)
  double? _fromLtNat;
  double? _fromLgNat;

  // Evita dobles llamadas a finalize / buy cuando el usuario presiona varias veces
  bool _payphoneFinalizeInProgress = false;

  // Si el backend ya acreditó el saldo para un transactionId, permitimos reintentar el buy sin volver a finalizar
  final Set<String> _payphoneFinalizedTxIds = <String>{};

  CartSummaryController({
    bool isSumaryTaxi = false,
    bool isSummaryNat = false,
    double? fromLtNat,
    double? fromLgNat,
  }) {
    _isSumaryTaxi = isSumaryTaxi;
    _isSummaryNat = isSummaryNat;
    _fromLtNat = fromLtNat;
    _fromLgNat = fromLgNat;
    load();
  }

  List<CartSummaryModel> get summaries => _summaries;

  bool get inAsyncCall => _inAsyncCall;

  bool get isSumaryTaxi => _isSumaryTaxi;

  bool get isSummaryNat => _isSummaryNat;

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

    // Para Taxi: origen viene del primer producto.
    // Para NAT: origen debe venir desde NatScreen (ubicación real de la tienda seleccionada).
    bool useFromOverride = false;

    double fromLgTaxi = 0.0, fromLtTaxi = 0.0;

    if (_isSumaryTaxi) {
      useFromOverride = true;
      fromLtTaxi = _products[0].lt;
      fromLgTaxi = _products[0].lg;
    } else if (_isSummaryNat) {
      // Preferimos coordenadas explícitas; si no llegan, caemos al dummy product como fallback.
      useFromOverride = true;
      if (_fromLtNat != null && _fromLgNat != null) {
        fromLtTaxi = _fromLtNat!;
        fromLgTaxi = _fromLgNat!;
      } else {
        fromLtTaxi = _products[0].lt;
        fromLgTaxi = _products[0].lg;
      }
    }

    if (kDebugMode) {
      print(
          '[CartSummary] loadDeliveryFee -> isTaxi=$_isSumaryTaxi isNat=$_isSummaryNat '
          'fromLt=$fromLtTaxi fromLg=$fromLgTaxi useFromOverride=$useFromOverride');
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

    if (kDebugMode) {
      print('[CartSummary] deliveryCost -> companyIds=${companyIds.join(',')} '
          'to=(${_address!.location.x},${_address!.location.y})');
    }

    List<FeeModel> fees = await marketService.deliveryCost(
      companyIds.join(','),
      _address!.location.x,
      _address!.location.y,
      isSumaryTaxi: useFromOverride,
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
    // Seguridad: si no hay dirección cargada, no intentamos crear pedidos.
    if (_address == null) {
      _summaries.clear();
      return false;
    }

    // Si por alguna razón no hay resúmenes (por ejemplo, carga incompleta), reintenta cargar.
    if (_summaries.isEmpty) {
      await loadDeliveryFee();
      if (_address == null || _summaries.isEmpty) {
        return false;
      }
    }

    inAsyncCall = true;

    bool allOk = true;
    try {
      for (final CartSummaryModel cartSummary in _summaries) {
        try {
          // ✅ buy debe considerarse exitoso SOLO si el backend crea la orden.
          // MarketService.buy retorna típicamente OrderModel? (null si falló) o bool (legacy).
          final result =
              await marketService.buy(cartSummary, _address!, typePayment);

          // Caso recomendado: si no hay orden, falló.
          if (result == null) {
            allOk = false;
            if (kDebugMode) {
              print(
                  '❌ marketService.buy retornó null (no se creó la orden) (companyId=${cartSummary.fee.companyId})');
            }
            break;
          }

          // Compatibilidad: algunos flujos antiguos retornan bool.
          if (result is bool && result == false) {
            allOk = false;
            if (kDebugMode) {
              print(
                  '❌ marketService.buy retornó false (companyId=${cartSummary.fee.companyId})');
            }
            break;
          }

          if (kDebugMode) {
            print(
                '✅ Orden creada para companyId=${cartSummary.fee.companyId} (resultType=${result.runtimeType})');
          }
        } catch (e) {
          allOk = false;
          if (kDebugMode) {
            print(
                '❌ Error en marketService.buy (companyId=${cartSummary.fee.companyId}): $e');
          }
          break;
        }
      }

      // Solo borramos el carrito si TODOS los pedidos se crearon correctamente.
      if (allOk) {
        await DBProvider.db.deleteAllProduct(
            _isSumaryTaxi ? TypesCompany.taxi : TypesCompany.store);
      }

      return allOk;
    } finally {
      inAsyncCall = false;
    }
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

  /// ✅ Finaliza el pago PayPhone (API Sale) y crea el pedido usando saldo (money)
  ///
  /// Flujo:
  /// 1) Llama al backend: /payphone/sale/finalize (idempotente)
  /// 2) Si approved=true, refresca balance
  /// 3) Ejecuta buy(TypesPayment.money)
  Future<bool> confirmPayPhoneAndBuy(
      String transactionIdStr, String clientTxId) async {
    final token = PreferencesProvider().token;

    try {
      if (token.isEmpty) {
        if (kDebugMode) {
          print('❌ No hay token para finalizar PayPhone');
        }
        return false;
      }

      final tx = transactionIdStr.trim();
      final ctx = clientTxId.trim();

      if (tx.isEmpty) {
        if (kDebugMode) {
          print('❌ transactionId vacío');
        }
        return false;
      }

      // Si ya estamos finalizando, evitamos doble ejecución (doble tap / doble pantalla)
      if (_payphoneFinalizeInProgress) {
        if (kDebugMode) {
          print('⚠️ finalize en progreso, ignorando segundo intento (tx=$tx)');
        }
        return false;
      }

      inAsyncCall = true;
      _payphoneFinalizeInProgress = true;

      // Si este tx ya fue finalizado y acreditado previamente, no volvemos a llamar al backend;
      // solo intentamos crear el pedido usando saldo.
      if (_payphoneFinalizedTxIds.contains(tx)) {
        if (kDebugMode) {
          print(
              '♻️ tx ya finalizado localmente (tx=$tx). Reintentando buy con saldo.');
        }
        await loadBalance();
        // Asegura que address/summaries estén listos antes de comprar (evita casos donde se acredita money pero no se crea la orden)
        await loadDeliveryFee();
        return await buy(TypesPayment.money);
      }

      final uri = Uri.parse(
          'https://api.amaguexpress.com/api/client/payments/payphone/sale/finalize');

      final resp = await http
          .post(
            uri,
            headers: _authHeaders(token),
            body: jsonEncode({
              'transactionId': tx,
              'clientTxId': ctx,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (kDebugMode) {
        print(
            '✔️ PayPhone finalize response (${resp.statusCode}): ${resp.body}');
      }

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        return false;
      }

      bool approved = false;
      bool alreadyProcessed = false;

      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          final a = decoded['approved'];
          final ap = decoded['alreadyProcessed'];
          final s = decoded['success'];

          if (a is bool) approved = a;
          if (ap is bool) alreadyProcessed = ap;

          // Compatibilidad: si el backend devuelve success=true y statusCode=3
          if (!approved &&
              s is bool &&
              s == true &&
              decoded['statusCode'] == 3) {
            approved = true;
          }

          // Si el backend dice que ya fue procesado, el saldo ya está acreditado.
          if (!approved && alreadyProcessed && s is bool && s == true) {
            approved = true;
          }
        }
      } catch (_) {
        approved = false;
      }

      if (!approved) {
        return false;
      }

      // Marcar tx como finalizado localmente para permitir reintentos de buy sin re-finalizar.
      _payphoneFinalizedTxIds.add(tx);

      await loadBalance();
      // Asegura que address/summaries estén listos antes de comprar
      await loadDeliveryFee();

      // Crear pedido usando el flujo existente (no afecta efectivo)
      final ok = await buy(TypesPayment.money);
      return ok;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Excepción en confirmPayPhoneAndBuy: $e');
      }
      return false;
    } finally {
      _payphoneFinalizeInProgress = false;
      inAsyncCall = false;
    }
  }
}
