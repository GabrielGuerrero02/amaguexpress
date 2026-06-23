import 'dart:convert';

import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/provider/preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClientMoneyTopUpScreen extends StatefulWidget {
  const ClientMoneyTopUpScreen({super.key});

  @override
  State<ClientMoneyTopUpScreen> createState() => _ClientMoneyTopUpScreenState();
}

class _ClientMoneyTopUpScreenState extends State<ClientMoneyTopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _commentController = TextEditingController();

  bool _loading = false;
  String? _message;
  bool _isError = false;

  final PreferencesProvider prefs = PreferencesProvider();

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _topUpClientMoney() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() {
        _message = 'Ingrese un monto válido.';
        _isError = true;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar recarga'),
        content: Text(
          'Se recargará \$${amount.toStringAsFixed(2)} al cliente ${_phoneController.text.trim()}.\n\n¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _message = null;
      _isError = false;
    });

    final client = http.Client();

    try {
      final response = await client.post(
        Uri.parse('${kDomain}admin/order-monitor/client-money/top-up'),
        headers: {
          'Authorization': 'Bearer ${prefs.token}',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'phone': _phoneController.text.trim(),
          'amount': amount,
          'reference': _referenceController.text.trim(),
          'comment': _commentController.text.trim(),
        }),
      );

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _message = 'Recarga aplicada correctamente.';
          _isError = false;
        });

        _amountController.clear();
        _referenceController.clear();
        _commentController.clear();
      } else {
        setState(() {
          _message = decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'No se pudo aplicar la recarga.';
          _isError = true;
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print('ClientMoneyTopUpScreen _topUpClientMoney: $error');
      }

      setState(() {
        _message = 'Error de conexión al aplicar recarga.';
        _isError = true;
      });
    } finally {
      client.close();

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recarga transferencia'),
        backgroundColor: kPrimaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recargar cliente',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Suma saldo a money del cliente para pagos por transferencia, tarjeta o PayPhone.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Celular cliente',
                    hintText: '+593984300750',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese el celular del cliente.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    hintText: '10.00',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) {
                      return 'Ingrese un monto válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Referencia transferencia',
                    hintText: 'Banco / comprobante / referencia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Comentario',
                    hintText: 'Comentario opcional',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.withValues(alpha: 0.10)
                          : Colors.green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isError ? Colors.red : Colors.green,
                      ),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isError ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _topUpClientMoney,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.price_check_outlined),
                    label: Text(_loading ? 'Aplicando...' : 'Recargar cliente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
