import 'package:flutter/material.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/models/order_model.dart';
import 'package:amaguexpress/src/provider/push_provider.dart';
import 'package:amaguexpress/src/services/market_service.dart';

class Tab2Controller with ChangeNotifier {
  final _pushProvider = PushProvider();
  MarketService marketService = MarketService();

  bool _inAsyncCall = false;

  int _numOrders = 0;

  List<OrderModel> orders = [];
  final Set<int> _hiddenCancelledOrderIds = {};

  bool get inAsyncCall => _inAsyncCall;

  set inAsyncCall(bool asyncCall) {
    _inAsyncCall = asyncCall;
    notifyListeners();
  }

  int get numOrders => _numOrders;

  set numOrders(int newValue) {
    _numOrders = newValue;
    notifyListeners();
  }

  Tab2Controller() {
    loadOrders();
    _pushProvider.notifications.listen(evaluateNotification);
  }

  evaluateNotification(Map<String, dynamic> notification) async {
    switch (notification['type']) {
      case TypesNotification.changeOrderStatust:
        loadOrders();
        break;
      case TypesNotification.messageChat:
        final orderId = int.parse(notification['orderId']);
        final index = orders.indexWhere((or) => or.id == orderId);
        if (index < 0) return;
        orders[index].notificationsClient++;
        notifyListeners();
        break;
      default:
    }
  }

  cleanNotificationsClient(int orderId) {
    final index = orders.indexWhere((or) => or.id == orderId);
    if (index < 0) return;
    orders[index].notificationsClient = 0;
    notifyListeners();
  }

  hideCancelledOrder(int orderId) {
    _hiddenCancelledOrderIds.add(orderId);
    orders = orders
        .where((order) => !(order.status == StatusOrder.cancelled &&
            _hiddenCancelledOrderIds.contains(order.id)))
        .toList();
    numOrders = orders.length;
    notifyListeners();
  }

  loadOrders() async {
    inAsyncCall = true;
    final loadedOrders = await marketService.getOrders();
    orders = loadedOrders
        .where((order) => !(order.status == StatusOrder.cancelled &&
            _hiddenCancelledOrderIds.contains(order.id)))
        .toList();
    numOrders = orders.length;
    inAsyncCall = false;
    notifyListeners();
  }
}
