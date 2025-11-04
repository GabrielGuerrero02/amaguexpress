import 'package:flutter/material.dart';
import 'package:amaguexpress/src/models/order_model.dart';
import 'package:amaguexpress/src/screens/order/order_controller.dart';
import 'package:amaguexpress/src/screens/order/widget/content_order.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/constants/constants.dart';

class OrderScreen extends StatelessWidget {
  final OrderModel order;

  const OrderScreen(this.order, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrderController>.value(
      value: OrderController(order),
      child: Scaffold(
        appBar: AppBar(title: Text(order.store.name)),
        backgroundColor: kPrimaryColor, // Usa tu color primario
        body: Consumer<OrderController>(
            builder: (context, orderController, child) =>
                ContentOrder(orderController)),
      ),
    );
  }
}
