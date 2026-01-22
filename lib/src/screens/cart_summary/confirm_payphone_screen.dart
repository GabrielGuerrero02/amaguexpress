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
  bool loading = true;
  bool _didRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didRun) return;
      _didRun = true;
      _run();
    });
  }

  Future<void> _run() async {
    final cart = context.read<CartSummaryController>();
    final tabMain = context.read<TabManController>();
    final tab1 = context.read<Tab1Controller>();
    final tab2 = context.read<Tab2Controller>();
    final iconCart = context.read<IconCartController>();

    // UI state
    if (mounted) {
      setState(() {
        loading = true;
        success = false;
        statusMessage = 'Confirmando el pago...';
      });
    }

    final ok = await cart.confirmPayPhoneAndBuy(
      widget.transactionId,
      widget.clientTxId,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        success = true;
        loading = false;
        statusMessage = 'Pago aprobado. Generando tu pedido...';
      });

      // Volver a la pantalla principal y refrescar
      Navigator.popUntil(context, (r) => r.isFirst);
      tabMain.currentScreen = 1;
      tab1.load();
      tab2.loadOrders();
      iconCart.count();
    } else {
      setState(() {
        success = false;
        loading = false;
        statusMessage = 'No se pudo confirmar el pago. Intenta nuevamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de pago')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                const CircularProgressIndicator(),
              ] else if (success) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 72),
              ] else ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 72),
              ],
              const SizedBox(height: 16),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              if (!loading && !success) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _run,
                    child: const Text('Reintentar'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Volver'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
