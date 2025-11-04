import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_controller.dart';
import 'package:amaguexpress/src/screens/main/tab1_controller.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_controller.dart';
import 'package:amaguexpress/src/widgets/icon_cart/icon_cart_controller.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final cart = context.read<CartSummaryController>();
    final tabMain = context.read<TabManController>();
    final tab1 = context.read<Tab1Controller>();
    final tab2 = context.read<Tab2Controller>();
    final iconCart = context.read<IconCartController>();

    final ok = await cart.confirmPayPhoneAndBuy(
      widget.transactionId,
      widget.clientTxId,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        success = true;
        statusMessage = '✅ Pago confirmado, creando pedido...';
      });

      await Future.delayed(const Duration(seconds: 8));

      // Volver a la pantalla principal y refrescar
      Navigator.popUntil(context, (r) => r.isFirst);
      tabMain.currentScreen = 1;
      tab1.load();
      tab2.loadOrders();
      iconCart.count();
    } else {
      setState(() {
        success = false;
        statusMessage = '❌ No se pudo confirmar el pago.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de pago')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            success
                ? const Icon(Icons.check_circle, color: Colors.green, size: 64)
                : const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(statusMessage, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
