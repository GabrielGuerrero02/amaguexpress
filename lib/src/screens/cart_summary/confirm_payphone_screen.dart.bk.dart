import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_controller.dart';
import 'package:amaguexpress/src/screens/main/tab1_controller.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_controller.dart';
import 'package:amaguexpress/src/widgets/icon_cart/icon_cart_controller.dart';
import 'package:amaguexpress/constants/constants.dart';

class ConfirmPayPhoneScreen extends StatefulWidget {
  final String transactionId;
  final String clientTxId;

  const ConfirmPayPhoneScreen({
    super.key,
    required this.transactionId,
    required this.clientTxId,
  });

  @override
  State<ConfirmPayPhoneScreen> createState() => _ConfirmPayPhoneScreenState();
}

class _ConfirmPayPhoneScreenState extends State<ConfirmPayPhoneScreen> {
  String statusMessage = 'Confirmando el pago...';
  bool success = false;

  @override
  void initState() {
    super.initState();
    _confirmPayment();
  }

  Future<void> _confirmPayment() async {
    final cartSummaryController =
        Provider.of<CartSummaryController>(context, listen: false);
    final tabManController =
        Provider.of<TabManController>(context, listen: false);
    final tab1Controller = Provider.of<Tab1Controller>(context, listen: false);
    final tab2Controller = Provider.of<Tab2Controller>(context, listen: false);
    final iconCartController =
        Provider.of<IconCartController>(context, listen: false);

    bool result = await cartSummaryController.confirmPayPhoneAndBuy(
      widget.transactionId,
      widget.clientTxId,
    );

    if (result) {
      setState(() {
        statusMessage = '✅ Pago confirmado. Redirigiendo...';
        success = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);

      tabManController.currentScreen = 1;
      tab1Controller.load();
      tab2Controller.loadOrders();
      iconCartController.count();
    } else {
      setState(() {
        statusMessage = '❌ No se pudo confirmar el pago.';
        success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: const Text('Confirmación de pago')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (success)
              const Icon(Icons.check_circle, color: Colors.green, size: 64)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(statusMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
