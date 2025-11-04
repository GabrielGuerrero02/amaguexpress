import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:amaguexpress/constants/constants.dart';

const String _kBaseApi = 'https://api.amaguexpress.com';
const String _kPayPhonePath = '/api/client/payments/payphone/payment';
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
  String? paymentUrl;
  bool loading = true;
  late final WebViewController _webViewController;

  String? clientTxId;
  Timer? _pollTimer;
  bool _hasReturned = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[WebView] onPageStarted: $url');
          },
          onPageFinished: (url) {
            debugPrint('[WebView] onPageFinished: $url');
          },
          onNavigationRequest: (request) {
            debugPrint('[WebView] onNavigationRequest: ${request.url}');
            if (request.url.startsWith('amaguexpress://return-from-payphone')) {
              final uri = Uri.parse(request.url);
              final transactionId = uri.queryParameters['transactionId'];
              final confirmedClientTxId = clientTxId; // usamos el que guardamos
              if (!mounted) return NavigationDecision.prevent;
              debugPrint(
                  '[WebView] RETURN scheme -> txId=$transactionId clientTx=$confirmedClientTxId');
              Navigator.pop(context, {
                'transactionId': transactionId,
                'clientTxId': confirmedClientTxId,
              });
              return NavigationDecision.prevent;
            } else if (request.url
                .startsWith('https://amaguexpress.com/confirmacion.html')) {
              final uri = Uri.parse(request.url);
              // PayPhone puede enviar "transactionId" o "id"
              final txId = uri.queryParameters['transactionId'] ??
                  uri.queryParameters['id'];
              final clientTxFromUrl =
                  uri.queryParameters['clientTransactionId'] ??
                      uri.queryParameters['clientTxId'];
              final confirmedClientTxId = clientTxFromUrl ?? clientTxId;
              if (mounted) {
                debugPrint(
                    '[WebView] CONFIRM html -> txId=$txId clientTx=$confirmedClientTxId');
                Navigator.pop(context, {
                  'transactionId': txId,
                  'clientTxId': confirmedClientTxId,
                });
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _generatePaymentUrl();
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
      //"storeId": "7867d74a-111a-4418-88be-9d05624be105",
      "amount": amountInt,
      "amountWithTax": amountWithTax,
      "tax": tax,
      //"currency": "USD",
      "clientTransactionId": clientTxId,
      "reference": "Pago AmaguExpress",
      "responseUrl":
          "https://amaguexpress.com/confirmacion.html?clientTxId=$clientTxId",
      "phoneNumber": sanitizedPhone,
      //"products": widget.products
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      debugPrint('[PP] POST ${_kBaseApi + _kPayPhonePath}');
      final response = await http
          .post(
            Uri.parse(_kBaseApi + _kPayPhonePath),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(_kHttpTimeout);
      debugPrint(
          '[PP] prepare status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final paymentId = data['paymentId']?.toString();

// ✨ NUEVO: toma el clientTxId que devuelve tu backend
        final backendClientTxId =
            (data['clientTxId'] ?? data['clientTransactionId'])?.toString();
        if (backendClientTxId != null && backendClientTxId.isNotEmpty) {
          clientTxId =
              backendClientTxId; // ← este será el que confirmamos luego
        }

        if (paymentId != null) {
          final fullUrl = Uri(
            scheme: 'https',
            host: 'amaguexpress.com',
            path: '/payphone_payment.html',
            queryParameters: {
              'paymentId': paymentId,
              'clientTxId': clientTxId,
            },
          ).toString();

          debugPrint('[PP] load WebView URL: $fullUrl');

          if (!mounted) return;
          setState(() {
            paymentUrl = fullUrl;
            loading = false;
          });

          _webViewController.loadRequest(Uri.parse(fullUrl));
          _startUrlPolling();
        } else {
          if (!mounted) return;
          setState(() => loading = false);

          if (!mounted) return;
          final msg = response.body;
          // ignore: use_build_context_synchronously
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('No se pudo iniciar el pago'),
              content: Text(msg.toString()),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generatePaymentUrl();
                    },
                    child: const Text('Reintentar')),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('Cancelar')),
              ],
            ),
          );
        }
      } else {
        if (!mounted) return;
        setState(() => loading = false);

        if (!mounted) return;
        final msg = response.body;
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No se pudo iniciar el pago'),
            content: Text(msg.toString()),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _generatePaymentUrl();
                  },
                  child: const Text('Reintentar')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).maybePop();
                  },
                  child: const Text('Cancelar')),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      if (!mounted) return;
      final msg = e.toString();
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No se pudo iniciar el pago'),
          content: Text(msg.toString()),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _generatePaymentUrl();
                },
                child: const Text('Reintentar')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).maybePop();
                },
                child: const Text('Cancelar')),
          ],
        ),
      );
    }
  }

  void _startUrlPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 700), (_) async {
      if (_hasReturned) return;
      final url = await _webViewController.currentUrl();
      if (url == null) return;
      if (url.startsWith('https://amaguexpress.com/confirmacion.html')) {
        final uri = Uri.parse(url);
        // PayPhone puede enviar "transactionId" o "id"
        final txId =
            uri.queryParameters['transactionId'] ?? uri.queryParameters['id'];
        final clientTxFromUrl = uri.queryParameters['clientTransactionId'] ??
            uri.queryParameters['clientTxId'];
        final confirmedClientTxId = clientTxFromUrl ?? clientTxId;
        debugPrint(
            '[WebView] POLL confirm.html -> txId=$txId clientTx=$confirmedClientTxId');
        _hasReturned = true;
        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.pop(context, {
          'transactionId': txId,
          'clientTxId': confirmedClientTxId,
        });
      } else if (url.startsWith('amaguexpress://return-from-payphone')) {
        final uri = Uri.parse(url);
        final transactionId = uri.queryParameters['transactionId'];
        final confirmedClientTxId = clientTxId;
        debugPrint(
            '[WebView] POLL return scheme -> txId=$transactionId clientTx=$confirmedClientTxId');
        _hasReturned = true;
        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.pop(context, {
          'transactionId': transactionId,
          'clientTxId': confirmedClientTxId,
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: const Text('Pago con PayPhone')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _webViewController),
    );
  }
}
