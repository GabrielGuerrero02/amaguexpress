import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class KajitaWebView extends StatefulWidget {
  const KajitaWebView({super.key});

  @override
  State<KajitaWebView> createState() => _KajitaWebViewState();
}

class _KajitaWebViewState extends State<KajitaWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'KushkiChannel',
        onMessageReceived: (JavaScriptMessage message) {
          Navigator.pop(context, message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
    _loadKajitaHtml();
  }

  Future<void> _loadKajitaHtml() async {
    final htmlString = await rootBundle.loadString('assets/kajita.html');
    _controller.loadHtmlString(htmlString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF39200), // Naranja
        foregroundColor: Colors.white,
        title: const Text('Pago con tarjeta'),
        centerTitle: true,
        elevation: 1,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF39200),
              ),
            ),
        ],
      ),
    );
  }
}
