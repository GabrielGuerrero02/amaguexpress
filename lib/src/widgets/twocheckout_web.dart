import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TwoCheckoutWebView extends StatelessWidget {
  final String checkoutUrl;

  const TwoCheckoutWebView({Key? key, required this.checkoutUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF39200),
        foregroundColor: Colors.white,
        title: const Text('Pago con tarjeta'),
        centerTitle: true,
        elevation: 1,
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(checkoutUrl)),
      ),
    );
  }
}
