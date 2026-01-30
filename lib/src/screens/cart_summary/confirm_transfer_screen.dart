import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_controller.dart';

class ConfirmTransferScreen extends StatefulWidget {
  const ConfirmTransferScreen({super.key});

  @override
  State<ConfirmTransferScreen> createState() => _ConfirmTransferScreenState();
}

class _ConfirmTransferScreenState extends State<ConfirmTransferScreen> {
  static const int maxAttempts = 5;
  static const Duration attemptInterval =
      Duration(seconds: 4); // 5 intentos ~ 20s

  int _attempt = 0;
  int _secondsLeft = 20;
  bool _running = false;
  String? _message;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 20;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _start() async {
    if (_running) return;

    setState(() {
      _running = true;
      _attempt = 0;
      _message = null;
    });

    _startTimer();

    final cart = context.read<CartSummaryController>();

    // Asegura cálculo de delivery/total
    await cart.loadDeliveryFee();
    final totalNeeded = cart.total;

    for (int i = 0; i < maxAttempts; i++) {
      _attempt = i + 1;
      if (mounted) setState(() {});

      await cart.loadBalance(); // GET /client/balance

      if (cart.money >= totalNeeded) {
        final ok = await cart.buy(TypesPayment.money);
        if (!mounted) return;
        Navigator.pop(context, ok);
        return;
      }

      if (i < maxAttempts - 1) {
        await Future.delayed(attemptInterval);
      }
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _message = 'Aún no se acredita la transferencia. Puedes reintentar.';
    });
  }

  ButtonStyle _orangeButtonStyle(Color primary) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartSummaryController>();
    final totalNeeded = cart.total;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Confirmando transferencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiempo: $_secondsLeft s',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Intento: $_attempt / $maxAttempts'),
            const SizedBox(height: 16),
            Text('Saldo actual: \$${cart.money.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16)),
            Text('Total requerido: \$${totalNeeded.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (_running) const Text('Esperando acreditación del saldo...'),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!, style: const TextStyle(color: Colors.orange)),
            ],
            const Spacer(),
            if (!_running)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: _orangeButtonStyle(primary),
                  onPressed: _start,
                  child: const Text('Reintentar'),
                ),
              ),
            if (!_running) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _orangeButtonStyle(primary),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
