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
}
