import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/petition_controller.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/button_client_direction.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/button_store_direction.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/floating_button_call.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/floating_button_cancel.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/floating_button_whatsapp.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/floating_head.dart';
import 'package:amaguexpress/src/screens/deliveryman/petition/widget/floating_sheet_bottom.dart';
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

class ContentPetition extends StatefulWidget {
  const ContentPetition(
    this.petitionController, {
    super.key,
  });

  final PetitionController petitionController;

  @override
  State<ContentPetition> createState() => _ContentPetitionState();
}

class _ContentPetitionState extends State<ContentPetition>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        const Duration(milliseconds: 2100),
        () => widget.petitionController.centerMap(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        widget.petitionController.refreshPetition();
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
      inAsyncCall: widget.petitionController.inAsyncCall,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: kPrimaryColor,
            actions: [_buttonAppBar(widget.petitionController)]),
        body: Stack(
          children: [
            GoogleMap(
              minMaxZoomPreference: const MinMaxZoomPreference(3, 16),
              markers: widget.petitionController.markers,
              mapType: MapType.normal,
              buildingsEnabled: false,
              compassEnabled: true,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              initialCameraPosition:
                  widget.petitionController.initialCameraPosition,
              onMapCreated: (controller) {
                widget.petitionController.onMapCreated(controller);
                final isDark = Theme.of(context).brightness == Brightness.dark;
                controller.setMapStyle(isDark ? kDarkMapStyle : null);
              },
            ),
            FloatingHead(petitionController: widget.petitionController),
            FloatingButtonCall(petition: widget.petitionController.petition),
            FloatingButtonWhatsapp(
              petitionController: widget.petitionController,
            ),
            FloatingButtonCancel(petitionController: widget.petitionController),
            FloatingSheetBottom(petitionController: widget.petitionController),
          ],
        ),
      ),
    );
  }

  Widget _buttonAppBar(PetitionController petitionController) {
    switch (petitionController.petition.status) {
      case StatusOrder.assigned:
        return ButtonStoreDirection(petition: petitionController.petition);
      case StatusOrder.taken:
        return ButtonClientDirection(petition: petitionController.petition);
      default:
        return Container();
    }
  }
}
