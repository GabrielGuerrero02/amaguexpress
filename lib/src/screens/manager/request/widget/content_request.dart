import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/src/common/status_label.dart';
import 'package:amaguexpress/src/screens/manager/request/request_controller.dart';
import 'package:amaguexpress/src/screens/manager/request/widget/floating_head.dart';
import 'package:amaguexpress/src/screens/manager/request/widget/floating_sheet_bottom.dart';
import 'package:amaguexpress/src/widgets/modal_progress_hud.dart';
import 'package:amaguexpress/constants/constants.dart';

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

class ContentRequest extends StatefulWidget {
  const ContentRequest(
    this.requestController, {
    super.key,
  });

  final RequestController requestController;

  @override
  State<ContentRequest> createState() => _ContentRequestState();
}

class _ContentRequestState extends State<ContentRequest>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        const Duration(milliseconds: 2100),
        () => widget.requestController.centerMap(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        widget.requestController.refreshRequest();
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
    return ModalProgressHUD(
      inAsyncCall: widget.requestController.inAsyncCall,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor, // Usa tu color primario
          title: Text(
            statusOrderLabel(
              widget.requestController.request.status,
              widget.requestController.request.store.company.type,
            ),
            maxLines: 2,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              minMaxZoomPreference: const MinMaxZoomPreference(3, 16),
              markers: widget.requestController.markers,
              mapType: MapType.normal,
              buildingsEnabled: false,
              compassEnabled: true,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              initialCameraPosition:
                  widget.requestController.initialCameraPosition,
              onMapCreated: (controller) {
                widget.requestController.onMapCreated(controller);
                final isDark = Theme.of(context).brightness == Brightness.dark;
                controller.setMapStyle(isDark ? kDarkMapStyle : null);
              },
            ),
            FloatingHead(requestController: widget.requestController),
            FloatingClientCallButton(
              requestController: widget.requestController,
            ),
            FloatingClientChatButton(
              requestController: widget.requestController,
            ),
            FloatingSheetBottom(requestController: widget.requestController),
          ],
        ),
      ),
    );
  }
}
