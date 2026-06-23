import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/src/services/admin_order_monitor_service.dart';
import 'package:amaguexpress/src/widgets/drawer_menu.dart';
import 'package:flutter/material.dart';

class AdminOrderMonitorScreen extends StatefulWidget {
  const AdminOrderMonitorScreen({super.key});

  @override
  State<AdminOrderMonitorScreen> createState() =>
      _AdminOrderMonitorScreenState();
}

class _AdminOrderMonitorScreenState extends State<AdminOrderMonitorScreen> {
  final AdminOrderMonitorService service = AdminOrderMonitorService();

  bool loading = false;
  bool cancelling = false;
  Map<String, dynamic>? todaySummary;
  Map<String, dynamic>? deliverymenSummary;
  Map<String, dynamic>? storesSummary;
  Map<String, dynamic>? clientsSummary;
  Map<String, dynamic>? liveOrders;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() => loading = true);

    final results = await Future.wait([
      service.todaySummary(),
      service.deliverymenSummary(),
      service.storesSummary(),
      service.clientsSummary(),
      service.liveOrders(),
    ]);

    if (!mounted) return;

    setState(() {
      todaySummary = results[0];
      deliverymenSummary = results[1];
      storesSummary = results[2];
      clientsSummary = results[3];
      liveOrders = results[4];
      loading = false;
    });
  }

  List<dynamic> get orders {
    final data = liveOrders?['orders'];

    if (data is List) {
      return data;
    }

    return [];
  }

  String money(dynamic value) {
    final number = double.tryParse((value ?? 0).toString()) ?? 0;
    return '\$${number.toStringAsFixed(2)}';
  }

  int intValue(Map<String, dynamic>? data, String key) {
    return int.tryParse((data?[key] ?? 0).toString()) ?? 0;
  }

  String statusText(dynamic status) {
    final value = int.tryParse((status ?? '').toString());

    switch (value) {
      case 0:
        return 'Pendiente tienda';
      case 1:
        return 'Iniciado';
      case 100:
        return 'Asignado';
      case 101:
        return 'Retirado';
      case 200:
        return 'Entregado';
      case 300:
        return 'Calificado';
      case 400:
        return 'Cancelado';
      default:
        return 'Estado $status';
    }
  }

  String paymentText(dynamic payment) {
    final value = int.tryParse((payment ?? '').toString());

    switch (value) {
      case 5001:
        return 'Efectivo';
      case 6002:
        return 'Transferencia / Tarjeta';
      default:
        return 'Pago $payment';
    }
  }

  String formatTimeOnly(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String elapsedText(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '-';

    final diff = DateTime.now().difference(date.toLocal());
    final minutes = diff.inMinutes;

    if (minutes < 1) return 'Ahora';
    if (minutes < 60) return 'Hace $minutes min';

    final hours = diff.inHours;
    final restMinutes = minutes % 60;

    if (hours < 24) {
      return restMinutes > 0 ? 'Hace ${hours}h ${restMinutes}m' : 'Hace ${hours}h';
    }

    final days = diff.inDays;
    return 'Hace $days día${days == 1 ? '' : 's'}';
  }

  String preparationText(Map<String, dynamic> order) {
    final prep = int.tryParse((order['preparationTimeMinutes'] ?? 0).toString()) ?? 0;
    final acceptedAt = order['storeAcceptedAt'];

    if (prep <= 0) {
      return 'Prep: -';
    }

    final status = statusText(order['status']).toLowerCase();

    if (status.contains('entregado') || status.contains('calificado')) {
      return 'Prep: $prep min · Finalizado';
    }

    if (status.contains('cancelado')) {
      return 'Prep: $prep min · Cancelado';
    }

    if (acceptedAt == null) {
      return 'Prep: $prep min · Pendiente';
    }

    final acceptedDate = DateTime.tryParse(acceptedAt.toString());

    if (acceptedDate == null) {
      return 'Prep: $prep min';
    }

    final readyAt = acceptedDate.toLocal().add(Duration(minutes: prep));
    final diff = readyAt.difference(DateTime.now()).inMinutes;

    if (diff > 0) {
      return 'Prep: $prep min · Restan $diff min';
    }

    if (diff == 0) {
      return 'Prep: $prep min · Listo ahora';
    }

    return 'Prep: $prep min · Retraso ${diff.abs()} min';
  }

  bool canCancelOrder(Map<String, dynamic> order) {
    final status = int.tryParse((order['status'] ?? '').toString());

    return status == 0 || status == 1 || status == 100 || status == 101;
  }

  Future<void> showCancelOrderDialog(Map<String, dynamic> order) async {
    final orderId = int.tryParse((order['orderId'] ?? '').toString());

    if (orderId == null) {
      return;
    }

    final reasonController = TextEditingController();
    final commentController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar pedido #$orderId'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Ingresa el motivo de cancelación. Esta acción notificará al cliente.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo obligatorio',
                  hintText: 'Ejemplo: tienda cerrada, producto no disponible',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario opcional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El motivo de cancelación es obligatorio.'),
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'reason': reason,
                'comment': commentController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    reasonController.dispose();
    commentController.dispose();

    if (result == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación final'),
        content: Text(
          '¿Confirmas cancelar el pedido #$orderId?\n\nEsta acción no debe usarse por error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await cancelOrder(orderId, result['reason']!, result['comment'] ?? '');
  }

  Future<void> cancelOrder(
    int orderId,
    String reason,
    String comment,
  ) async {
    setState(() => cancelling = true);

    final response = await service.cancelOrder(
      orderId,
      reason: reason,
      comment: comment,
    );

    if (!mounted) return;

    setState(() => cancelling = false);

    final statusCode = int.tryParse((response?['statusCode'] ?? 0).toString()) ?? 0;
    final success = response != null && statusCode >= 200 && statusCode < 300;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pedido #$orderId cancelado correctamente.'
              : 'No se pudo cancelar el pedido #$orderId.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DraweMenu(),
      appBar: AppBar(
        title: const Text('Panel administrador'),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : loadDashboard,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                const Text(
                  'Panel administrador',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Resumen operativo de AmaguExpress.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Resumen del día'),
                _summaryToday(),
                const SizedBox(height: 18),
                _sectionTitle('Pedidos en vivo'),
                _liveOrders(),
                const SizedBox(height: 18),
                _sectionTitle('Operación'),
                _operationSummary(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _summaryToday() {
    final sales = todaySummary?['salesTodayByPayment'] as Map<String, dynamic>?;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Ventas hoy',
                money(sales?['total'] ?? todaySummary?['salesToday']),
                Icons.attach_money,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                'Efectivo',
                money(sales?['cash']),
                Icons.payments_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Transf. / Tarjeta',
                money(sales?['transfer']),
                Icons.credit_card,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                'Pedidos hoy',
                intValue(todaySummary, 'ordersToday').toString(),
                Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Entregados',
                intValue(todaySummary, 'delivered').toString(),
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                'Cancelados',
                intValue(todaySummary, 'cancelled').toString(),
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'En curso',
                intValue(todaySummary, 'active').toString(),
                Icons.pending_actions_outlined,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _operationSummary() {
    final deliverymenOnline = intValue(deliverymenSummary, 'online');
    final deliverymenBusy = intValue(deliverymenSummary, 'busy');
    final deliverymenAvailable =
        deliverymenOnline - deliverymenBusy < 0 ? 0 : deliverymenOnline - deliverymenBusy;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Motorizados',
                intValue(deliverymenSummary, 'registered').toString(),
                Icons.two_wheeler,
                subtitle: 'En línea: ${intValue(deliverymenSummary, 'online')}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                'Disponibles',
                deliverymenAvailable.toString(),
                Icons.delivery_dining,
                subtitle: 'Ocupados: ${intValue(deliverymenSummary, 'busy')}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Tiendas',
                intValue(storesSummary, 'registered').toString(),
                Icons.storefront_outlined,
                subtitle: 'Operando: ${intValue(storesSummary, 'operating')}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                'Clientes',
                intValue(clientsSummary, 'registeredClients').toString(),
                Icons.people_alt_outlined,
                subtitle: 'Sesiones: ${intValue(clientsSummary, 'sessions')}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kPrimaryColor, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _liveOrders() {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding),
          child: Text('No hay pedidos activos o pedidos de hoy.'),
        ),
      );
    }

    return Column(
      children: orders
          .map((order) => _orderCard(Map<String, dynamic>.from(order)))
          .toList(),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pedido #${order['orderId']}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusChip(statusText(order['status'])),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${elapsedText(order['createdAt'])} · ${preparationText(order)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Acept.: ${order['storeAcceptedAt'] == null ? 'Pendiente' : formatTimeOnly(order['storeAcceptedAt'])}',
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(height: 22),
            _infoLine('Pago', paymentText(order['payment'])),
            _infoLine('Cliente', '${order['clientName'] ?? '-'} · ${order['clientPhone'] ?? '-'}'),
            _infoLine('Tienda', '${order['storeName'] ?? order['companyName'] ?? '-'}'),
            _infoLine('Motorizado', '${order['deliverymanName'] ?? 'Sin motorizado'}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _infoLine('Total', money(order['total']))),
                Expanded(child: _infoLine('Delivery', money(order['deliveryFee']))),
              ],
            ),
            if (canCancelOrder(order)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: cancelling ? null : () => showCancelOrderDialog(order),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar pedido'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
