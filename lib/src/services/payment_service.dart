import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/models/product_model.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';

const _urlPayment = 'client/payments/payment';
const _urlConfirm = 'client/payments/confirm';
const _urlCancel = 'client/payments/cancel';
const _urlKushki =
    'client/payments/kushki'; // Ajusta si tu endpoint es diferente

class PaymentService {
  final prefs = PreferencesProvider();

  Future<Map<String, dynamic>?> payment(
      List<ProductModel> products, double money, String currency) async {
    var client = http.Client();
    try {
      final resp = await client.post(
        Uri.parse('$kDomain$_urlPayment'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          "currency": currency,
          "money": money,
          "products": List<dynamic>.from(
            products.map((x) => x.toJson()),
          ),
        }),
      );
      if (resp.statusCode == 201) return json.decode(resp.body);
    } catch (err) {
      if (kDebugMode) {
        print('PaymentService payment: $err');
      }
    } finally {
      client.close();
    }
    return null;
  }

  Future<bool> confirm(int paymentId) async {
    var client = http.Client();
    try {
      final resp = await client
          .patch(Uri.parse('$kDomain$_urlConfirm/$paymentId'), headers: {
        'Authorization': 'Bearer ${prefs.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      });
      if (resp.statusCode == 200) return true;
    } catch (err) {
      if (kDebugMode) {
        print('PaymentService confirm: $err');
      }
    } finally {
      client.close();
    }
    return false;
  }

  Future<bool> cancel(int paymentId) async {
    var client = http.Client();
    try {
      final resp = await client
          .patch(Uri.parse('$kDomain$_urlCancel/$paymentId'), headers: {
        'Authorization': 'Bearer ${prefs.token}',
        'Content-Type': 'application/json; charset=UTF-8',
      });
      if (resp.statusCode == 200) return true;
    } catch (err) {
      if (kDebugMode) {
        print('PaymentService cancel: $err');
      }
    } finally {
      client.close();
    }
    return false;
  }

  /// Método para pagos con Kushki
  Future<bool> payWithKushkiToken({
    required String token,
    required double amount,
    required String currency,
  }) async {
    var client = http.Client();
    try {
      final resp = await client.post(
        Uri.parse('$kDomain$_urlKushki'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'token': token,
          'amount': amount,
          'currency': currency,
        }),
      );
      if (resp.statusCode == 200) return true;
    } catch (err) {
      if (kDebugMode) {
        print('PaymentService payWithKushkiToken: $err');
      }
    } finally {
      client.close();
    }
    return false;
  }
}
