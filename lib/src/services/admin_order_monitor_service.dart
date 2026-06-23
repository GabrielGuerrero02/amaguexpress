import 'dart:convert';

import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminOrderMonitorService {
  final PreferencesProvider prefs = PreferencesProvider();

  Future<Map<String, dynamic>?> _get(String path) async {
    final client = http.Client();

    try {
      final response = await client.get(
        Uri.parse('$kDomain$path'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.body.isEmpty) {
        return null;
      }

      return json.decode(response.body);
    } catch (error) {
      if (kDebugMode) {
        print('AdminOrderMonitorService $path: $error');
      }
    } finally {
      client.close();
    }

    return null;
  }

  Future<Map<String, dynamic>?> todaySummary() {
    return _get('admin/order-monitor/today-summary');
  }

  Future<Map<String, dynamic>?> deliverymenSummary() {
    return _get('admin/order-monitor/deliverymen-summary');
  }

  Future<Map<String, dynamic>?> storesSummary() {
    return _get('admin/order-monitor/stores-summary');
  }

  Future<Map<String, dynamic>?> clientsSummary() {
    return _get('admin/order-monitor/clients-summary');
  }

  Future<Map<String, dynamic>?> liveOrders() {
    return _get('admin/order-monitor/live');
  }
  Future<Map<String, dynamic>?> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = http.Client();

    try {
      final response = await client.patch(
        Uri.parse('$kDomain$path'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.body.isEmpty) {
        return {'ok': response.statusCode >= 200 && response.statusCode < 300};
      }

      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic>) {
        decoded['statusCode'] = response.statusCode;
        return decoded;
      }

      return {
        'ok': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
      };
    } catch (error) {
      if (kDebugMode) {
        print('AdminOrderMonitorService PATCH $path: $error');
      }
    } finally {
      client.close();
    }

    return null;
  }

  Future<Map<String, dynamic>?> cancelOrder(
    int orderId, {
    required String reason,
    String comment = '',
  }) {
    return _patch('admin/order-monitor/$orderId/cancel', {
      'reason': reason,
      'comment': comment,
    });
  }

}
