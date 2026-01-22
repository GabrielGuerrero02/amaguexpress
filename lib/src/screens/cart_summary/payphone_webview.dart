import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:flutter/services.dart';
import 'confirm_payphone_screen.dart';

const String _kBaseApi = 'https://api.amaguexpress.com';
const String _kPayPhoneSalePath = '/api/client/payments/payphone/payment';
const String _kPayPhoneSaleStatusPath =
    '/api/client/payments/payphone/sale/status';
const String _kPayPhoneSaleFinalizePath =
    '/api/client/payments/payphone/sale/finalize';
const Duration _kHttpTimeout = Duration(seconds: 25);

class PayPhoneWebView extends StatefulWidget {
  final double amount;
  final String phoneNumber;
  final List<Map<String, dynamic>> products;

  const PayPhoneWebView({
    super.key,
    required this.amount,
    required this.phoneNumber,
    required this.products,
  });

  @override
  State<PayPhoneWebView> createState() => _PayPhoneWebViewState();
}

class _PayPhoneWebViewState extends State<PayPhoneWebView> {
  bool loading = true;
  bool verifying = false;

  String? clientTxId;
  String? transactionId; // string para UI / requests
  String statusText = 'PENDIENTE';

  bool _finalized = false;
  Map<String, dynamic>? _finalizePayload;

  // Auto-verify: 20s x 5 intentos (manual reinicia el ciclo)
  Timer? _autoVerifyTimer;
  static const int _autoVerifyIntervalSeconds = 20;
  static const int _autoVerifyMaxAttempts = 5;
  int _autoVerifySeconds = _autoVerifyIntervalSeconds;
  int _autoVerifyAttempt = 0; // 0.._autoVerifyMaxAttempts

  String _maskPhoneForUi(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return raw;
    final last4 = digits.substring(digits.length - 4);
    return '*** *** $last4';
  }

  String _extractBackendMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();

        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map) {
            final em = first['message'];
            if (em is String && em.trim().isNotEmpty) return em.trim();
          }
        }
      }
    } catch (_) {
      // ignore
    }
    return body;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusPillText(String status) {
    switch (status) {
      case 'APROBADO':
        return 'PAGO APROBADO';
      case 'RECHAZADO':
        return 'PAGO RECHAZADO';
      default:
        return 'PAGO PENDIENTE';
    }
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  @override
  void initState() {
    super.initState();
    _generatePaymentUrl();
  }

  void _stopAutoVerifyCountdown() {
    _autoVerifyTimer?.cancel();
    _autoVerifyTimer = null;
  }

  void _startAutoVerifyCountdown({bool resetAttempts = false}) {
    // Evita múltiples timers / spam
    _stopAutoVerifyCountdown();

    if (resetAttempts) {
      _autoVerifyAttempt = 0;
    }

    _autoVerifySeconds = _autoVerifyIntervalSeconds;

    // Solo aplica cuando tenemos transactionId y el estado aún está pendiente
    if (transactionId == null || transactionId!.isEmpty) return;
    if (statusText != 'PENDIENTE') return;

    // Si ya se agotaron intentos, no programamos más
    if (_autoVerifyAttempt >= _autoVerifyMaxAttempts) return;

    _autoVerifyTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }

      // Si el estado cambió o el usuario está verificando, detenemos el tick.
      if (statusText != 'PENDIENTE' || verifying) {
        t.cancel();
        return;
      }

      if (_autoVerifySeconds <= 1) {
        t.cancel();

        // Consumimos un intento de auto-verificación
        _autoVerifyAttempt++;
        setState(() => _autoVerifySeconds = 0);

        // Auto-verificación
        await _verifySaleStatus(isAuto: true);
        return;
      }

      setState(() => _autoVerifySeconds--);
    });
  }

  String _verifyButtonText() {
    if (verifying) return 'Verificando…';

    if (statusText == 'PENDIENTE') {
      final remainingAttempts = (_autoVerifyMaxAttempts - _autoVerifyAttempt)
          .clamp(0, _autoVerifyMaxAttempts);

      if (remainingAttempts > 0) {
        return 'Verificar pago (${_autoVerifySeconds}s) · $remainingAttempts intentos';
      }

      return 'Verificar pago · sin intentos automáticos';
    }

    return 'Verificar pago';
  }

  Future<void> _generatePaymentUrl() async {
    final token = PreferencesProvider().token;
    clientTxId =
        "AMAGU-USER-${PreferencesProvider().user.id}-${DateTime.now().millisecondsSinceEpoch}";

    final String sanitizedPhone =
        widget.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    final amountInt = (widget.amount * 100).toInt();
    final amountWithTax = (amountInt * 0.88).round();
    final tax = amountInt - amountWithTax;

    debugPrint(
        '[PP] prepare: amount=$amountInt amountWithTax=$amountWithTax tax=$tax phone=$sanitizedPhone');

    final payload = {
      "amount": amountInt,
      "amountWithTax": amountWithTax,
      "tax": tax,
      "clientTransactionId": clientTxId,
      "reference": "Pago AmaguExpress",
      "responseUrl":
          "https://api.amaguexpress.com/api/client/payments/payphone/webhook",
      "phoneNumber": sanitizedPhone,
    };

    try {
      debugPrint('[PP] POST ${_kBaseApi + _kPayPhoneSalePath}');
      final response = await http
          .post(
            Uri.parse(_kBaseApi + _kPayPhoneSalePath),
            headers: _authHeaders(token),
            body: jsonEncode(payload),
          )
          .timeout(_kHttpTimeout);

      debugPrint(
          '[PP] prepare status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final txId = data['transactionId']?.toString();
        final backendClientTxId =
            (data['clientTxId'] ?? data['clientTransactionId'])?.toString();

        if (backendClientTxId != null && backendClientTxId.isNotEmpty) {
          clientTxId = backendClientTxId;
        }

        if (txId == null || txId.isEmpty) {
          if (!mounted) return;
          setState(() => loading = false);
          await _showStartPaymentError(_extractBackendMessage(response.body));
          return;
        }

        if (!mounted) return;
        setState(() {
          transactionId = txId;
          loading = false;
          statusText = 'PENDIENTE';
          _autoVerifyAttempt = 0;
          _autoVerifySeconds = _autoVerifyIntervalSeconds;
        });

        _startAutoVerifyCountdown(resetAttempts: true);
        return;
      }

      if (!mounted) return;
      setState(() => loading = false);
      await _showStartPaymentError(_extractBackendMessage(response.body));
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      await _showStartPaymentError(
        'No se pudo conectar con el servidor. Revisa tu conexión e intenta nuevamente.',
      );
    }
  }

  Future<void> _showStartPaymentError(String msg) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No se pudo iniciar el pago'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generatePaymentUrl();
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _finalizeSalePayment() async {
    final token = PreferencesProvider().token;
    if (transactionId == null || transactionId!.isEmpty) return null;

    final uri = Uri.parse('$_kBaseApi$_kPayPhoneSaleFinalizePath');

    final body = {
      'transactionId': transactionId,
      'clientTxId': clientTxId,
    };

    final res = await http
        .post(uri, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(_kHttpTimeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      try {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          _finalizePayload = data;
          _finalized = true;
          return data;
        }
      } catch (_) {}
      _finalizePayload = <String, dynamic>{'success': true};
      _finalized = true;
      return _finalizePayload;
    }

    throw Exception(_extractBackendMessage(res.body));
  }

  Future<void> _verifySaleStatus(
      {bool isAuto = false, bool resetAutoFlow = false}) async {
    final token = PreferencesProvider().token;
    if (transactionId == null || transactionId!.isEmpty) return;

    // Detenemos el timer actual para evitar doble tick; lo reprogramamos al final si sigue pendiente.
    _stopAutoVerifyCountdown();

    // Si es verificación manual, reiniciamos intentos y contador (fresh 5)
    if (!isAuto && resetAutoFlow) {
      _autoVerifyAttempt = 0;
      _autoVerifySeconds = _autoVerifyIntervalSeconds;
      if (mounted) setState(() {});
    }

    setState(() => verifying = true);

    try {
      final uri = Uri.parse(
        '$_kBaseApi$_kPayPhoneSaleStatusPath?transactionId=${Uri.encodeComponent(transactionId!)}',
      );

      final res = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(_kHttpTimeout);

      if (!mounted) return;

      if (res.statusCode != 200) {
        await _showSimpleDialog(
          title: 'No se pudo verificar el pago',
          message: _extractBackendMessage(res.body),
          okText: 'Cerrar',
          okColor: kPrimaryColor,
        );
        return;
      }

      final data = jsonDecode(res.body);

      final statusCode = data['statusCode'];
      final statusRaw =
          (data['transactionStatus'] ?? data['status'] ?? '').toString();

      final statusNorm = statusRaw.toLowerCase();

      String newStatus;
      if (statusCode == 3 || statusNorm == 'approved') {
        newStatus = 'APROBADO';
      } else if (statusCode == 2 || statusNorm == 'denied') {
        newStatus = 'RECHAZADO';
      } else {
        newStatus = 'PENDIENTE';
      }

      setState(() => statusText = newStatus);

      // Si sigue pendiente, reprogramamos el próximo auto-check (si quedan intentos)
      if (newStatus == 'PENDIENTE') {
        _startAutoVerifyCountdown();
      } else {
        _stopAutoVerifyCountdown();
      }

      if (newStatus == 'APROBADO') {
        // 1) Finalizar en backend (acreditar saldo + registrar payment idempotente)
        if (!_finalized) {
          try {
            await _finalizeSalePayment();
          } catch (e) {
            await _showApprovedButFinalizeFailed(e.toString());
            return;
          }
        }

        // 2) Modal de aprobado y luego pasamos a la pantalla que confirma y crea el pedido
        await _showApprovedDialog(
          onAccept: () async {
            _stopAutoVerifyCountdown();

            Navigator.of(context).pop(); // cierra dialog

            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ConfirmPayPhoneScreen(
                  transactionId: transactionId!,
                  clientTxId: clientTxId ?? '',
                ),
              ),
            );

            if (result == true && mounted) {
              Navigator.of(context).pop(true);
            }
          },
        );
        return;
      }

      if (newStatus == 'RECHAZADO') {
        await _showSimpleDialog(
          title: 'PAGO RECHAZADO',
          message:
              'El cobro fue rechazado en PayPhone. Puedes intentarlo nuevamente o elegir otro método de pago.',
          okText: 'Cerrar',
          okColor: Colors.red,
          titleColor: Colors.red,
          centerTitle: true,
          fontSize: 14,
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      await _showSimpleDialog(
        title: 'No se pudo verificar el pago',
        message: e.toString(),
        okText: 'Cerrar',
        okColor: kPrimaryColor,
      );
    } finally {
      if (mounted) {
        setState(() => verifying = false);

        // Si sigue pendiente y quedan intentos, retomamos countdown
        if (statusText == 'PENDIENTE') {
          _startAutoVerifyCountdown();
        }
      }
    }
  }

  Future<void> _manualVerify() async {
    // Manual: verifica ahora y reinicia el ciclo automático (20s x 5 intentos)
    await _verifySaleStatus(isAuto: false, resetAutoFlow: true);
  }

  Future<void> _showApprovedButFinalizeFailed(String err) async {
    await _showSimpleDialog(
      title: 'PAGO APROBADO',
      message:
          'PayPhone aprobó el cobro, pero no se pudo finalizar en el servidor.\n\nDetalle: $err\n\nPulsa “Cerrar” e intenta “Verificar pago” nuevamente.',
      okText: 'Cerrar',
      okColor: Colors.green,
      titleColor: Colors.green,
      centerTitle: true,
      fontSize: 14,
    );
  }

  Future<void> _showApprovedDialog({required VoidCallback onAccept}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          title: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'PAGO APROBADO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          content: const Text(
            'Listo. El cobro fue aprobado en\nPayPhone.\n\nPulsa “Aceptar” para volver y\ncontinuar con tu pedido.\n',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.35),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Aceptar'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSimpleDialog({
    required String title,
    required String message,
    required String okText,
    required Color okColor,
    Color? titleColor,
    bool centerTitle = false,
    double fontSize = 13,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: centerTitle
            ? Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              okText,
              style: TextStyle(color: okColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopAutoVerifyCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pillColor = _statusColor(statusText);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Pago con PayPhone'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (loading) ...[
                const Spacer(),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Enviando solicitud de cobro a PayPhone…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por favor espera un momento.',
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ] else if (transactionId != null) ...[
                const SizedBox(height: 6),
                const Text(
                  'Solicitud enviada a PayPhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: pillColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusPillText(statusText),
                              style: TextStyle(
                                color: pillColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copiar ID de transacción',
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: transactionId!),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('transactionId copiado'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Se envió el cobro a PayPhone con el número registrado: ${_maskPhoneForUi(widget.phoneNumber)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pasos:',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text('1) Abre la app PayPhone.'),
                      const Text('2) Aprueba el cobro pendiente.'),
                      const Text(
                          '3) Regresa aquí y presiona “Verificar pago”.'),
                      const SizedBox(height: 10),
                      const Text(
                        'Nota: Si aún no tienes PayPhone, instálala y registra tu tarjeta antes de continuar.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: verifying ? null : _manualVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(_verifyButtonText()),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'El pago se rechazará en 5 minutos si no completas la transacción.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: Colors.black, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const Spacer(),
                const Icon(Icons.error_outline, size: 42, color: Colors.red),
                const SizedBox(height: 10),
                const Text(
                  'No se pudo iniciar el pago',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Intenta nuevamente. Si el problema persiste, verifica tu conexión.',
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
