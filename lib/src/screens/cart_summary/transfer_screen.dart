import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/screens/cart_summary/cart_summary_controller.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  // Datos bancarios
  static const String kBank = 'Pichincha';
  static const String kAccountType = 'Ahorros';
  static const String kAccountNumber = '2210457663';
  static const String kOwner = 'Gabriel Guerrero';
  static const String kWhatsApp = '0998197655';

  // UX similar a PayPhone
  static const int maxAttempts = 10;
  static const int secondsPerAttempt = 20;

  late final String reference;

  int _attempt = 0; // 0..maxAttempts
  int _secondsLeft = secondsPerAttempt;
  bool _running = false;
  String? _message;
  bool _checking = false;
  bool _approved = false;

  Future<void> _manualVerifyNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final ok = await _tryOnce();
      if (!mounted) return;
      if (ok) {
        _stopTimers();
      }
    } finally {
      _checking = false;
    }
  }

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    reference = 'AMX-TRF-${DateTime.now().millisecondsSinceEpoch}';

    // Asegura que el total esté bien calculado (delivery fee, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cart = context.read<CartSummaryController>();
      await cart.loadDeliveryFee();
      await cart.loadBalance();
      await _startVerify();
      // if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copyAccount() async {
    await Clipboard.setData(const ClipboardData(text: kAccountNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de cuenta copiado ✅')));
  }

  Future<void> _copyWhatsApp() async {
    await Clipboard.setData(const ClipboardData(text: kWhatsApp));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Número de WhatsApp copiado ✅')),
    );
  }

  Future<void> _openWhatsAppChat() async {
    // Ecuador: 0998197655 -> 593998197655
    final digits = kWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;
    final phone = '593$normalized';

    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _startVerify() async {
    if (_running) return;

    setState(() {
      _running = true;
      _message = null;
      _attempt = 1;
      _secondsLeft = secondsPerAttempt;
    });

    _stopTimers();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;

      if (_secondsLeft > 1) {
        setState(() => _secondsLeft -= 1);
        return;
      }

      // Fin del conteo: ejecutamos un intento
      setState(() => _secondsLeft = 0);

      final ok = await _tryOnce();
      if (!mounted) return;

      if (ok) {
        t.cancel();
        _timer = null;
        return;
      }

      // Si no fue OK, avanzamos de intento o terminamos
      if (_attempt >= maxAttempts) {
        t.cancel();
        _timer = null;
        setState(() {
          _running = false;
          _message = 'Aún no se acredita la transferencia. Puedes reintentar.';
          _secondsLeft = secondsPerAttempt;
        });
        return;
      }

      setState(() {
        _attempt += 1;
        _secondsLeft = secondsPerAttempt;
      });
    });
  }

  Future<bool> _tryOnce() async {
    final cart = context.read<CartSummaryController>();

    try {
      await cart.loadBalance();

      final totalNeeded = cart.total;
      if (cart.money >= totalNeeded) {
        final bought = await cart.buy(TypesPayment.money);
        if (!mounted) return false;

        if (bought == true) {
          setState(() {
            _running = false;
            _approved = true;
            _message = null;
          });
          await _showApprovedModal();
          return true;
        }

        setState(() {
          _message = 'No se pudo generar la orden. Intenta nuevamente.';
        });
        return false;
      }

      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _message = 'Error consultando el saldo. Intenta nuevamente.';
      });
      return false;
    }
  }

  Future<void> _showApprovedModal() async {
    final primary = Theme.of(context).colorScheme.primary;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF3E2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'PAGO APROBADO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Listo. La transferencia fue validada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pulsa “Aceptar” para volver y continuar con tu pedido.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, true); // vuelve a body_cart
                      },
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartSummaryController>();
    final primary = Theme.of(context).colorScheme.primary;

    final totalNeeded = cart.total;
    final attemptsLeft = _running ? (maxAttempts - _attempt + 1) : maxAttempts;

    final verifyText = _running
        ? 'Verificar pago (${_secondsLeft}s) - $attemptsLeft intentos'
        : 'Verificar pago';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Pago por Transferencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: _approved
                                ? const Color(0xFFDFF3E2)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            _approved
                                ? 'PAGO APROBADO'
                                : 'TRANSFERENCIA PENDIENTE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color:
                                  _approved ? const Color(0xFF2E7D32) : primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyAccount,
                          tooltip: 'Copiar número de cuenta',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Banco: $kBank'),
                    Text('Cuenta: $kAccountType'),
                    Text('Número: $kAccountNumber'),
                    Text('Propietario: $kOwner'),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Referencia: $reference',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pasos:',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                        '1) Realiza la transferencia a la cuenta indicada.'),
                    const Text('2) Envia comprobante (WhatsApp): $kWhatsApp'),
                    const Text('3) Regresa aquí y presiona “Verificar pago”.'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyWhatsApp,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar WhatsApp'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openWhatsAppChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Ir a WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Nota: Solo transferencias Banco Pichincha → Banco Pichincha.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Saldo actual: \$${cart.money.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total a pagar: \$${totalNeeded.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _message!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (_running) {
                    _manualVerifyNow();
                  } else {
                    _startVerify();
                  }
                },
                child: Text(verifyText),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
