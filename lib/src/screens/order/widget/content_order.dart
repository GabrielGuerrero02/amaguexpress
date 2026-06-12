import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/screens/main/tab1_controller.dart';
import 'package:amaguexpress/src/screens/main/tab2_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_controller.dart';
import 'package:amaguexpress/src/screens/order/order_controller.dart';
import 'package:amaguexpress/src/screens/order/widget/floating_head.dart';
import 'package:amaguexpress/src/screens/order/widget/floating_sheet_bottom.dart';
import 'package:amaguexpress/src/widgets/primary_button.dart';
import 'package:provider/provider.dart';

// Estilo oscuro para Google Maps (se aplica solo en tema oscuro)
const String kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},
  {"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
  {"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

class ContentOrder extends StatefulWidget {
  const ContentOrder(
    this.orderController, {
    super.key,
  });
  final OrderController orderController;

  @override
  State<ContentOrder> createState() => _ContentOrderState();
}

class _ContentOrderState extends State<ContentOrder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        const Duration(milliseconds: 2100),
        () => widget.orderController.centerMap(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        widget.orderController.refreshOrder();
        break;
      case AppLifecycleState.paused:
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          minMaxZoomPreference: const MinMaxZoomPreference(3, 16),
          markers: widget.orderController.markers,
          mapType: MapType.normal,
          buildingsEnabled: false,
          compassEnabled: true,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          initialCameraPosition: widget.orderController.initialCameraPosition,
          onMapCreated: (controller) {
            widget.orderController.onMapCreated(controller);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            controller.setMapStyle(isDark ? kDarkMapStyle : null);
          },
        ),
        FloatingHead(orderController: widget.orderController),
        FloatingSheetBottom(orderController: widget.orderController),
        widget.orderController.order.status == StatusOrder.delivered
            ? ScoreDialog(widget.orderController)
            : widget.orderController.order.status == StatusOrder.cancelled
                ? CancelledOrderDialog(widget.orderController)
                : Container()
      ],
    );
  }
}

class ScoreDialog extends StatelessWidget {
  const ScoreDialog(this.orderController, {super.key});

  final OrderController orderController;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Color.fromARGB(170, 0, 0, 0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              orderController.order.status == StatusOrder.cancelled
                  ? S.of(context).lStatusOrderCancelled
                  : S.of(context).lStatusOrderDelivered,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kDefaultPadding * 2),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 5.0),
              itemSize: 50,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (raiting) {
                orderController.order.scoreClient = raiting;
              },
            ),
            const SizedBox(height: kDefaultPadding * 2),
            PrimaryButton(
              text: S.of(context).bQualify,
              onPressed: () async {
                final tab2Controller =
                    Provider.of<Tab2Controller>(context, listen: false);
                Provider.of<Tab1Controller>(context, listen: false).load();
                Provider.of<TabManController>(context, listen: false)
                    .currentScreen = 0;
                Navigator.of(context).popUntil((route) => route.isFirst);
                await orderController.qualify();
                tab2Controller.loadOrders();
              },
            )
          ],
        ),
      ),
    );
  }
}

class CancelledOrderDialog extends StatefulWidget {
  const CancelledOrderDialog(this.orderController, {super.key});

  final OrderController orderController;

  @override
  State<CancelledOrderDialog> createState() => _CancelledOrderDialogState();
}

class _CancelledOrderDialogState extends State<CancelledOrderDialog> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (!_shown) {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Provider.of<Tab1Controller>(context, listen: false).load();
        final tab2Controller =
            Provider.of<Tab2Controller>(context, listen: false);
        tab2Controller.hideCancelledOrder(widget.orderController.order.id);
        Provider.of<TabManController>(context, listen: false).currentScreen = 0;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    return const SizedBox.shrink();
  }
}
