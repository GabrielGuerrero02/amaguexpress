import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/constants/constants.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/bloc/socket_bloc.dart';
import 'package:amaguexpress/src/common/file_helper.dart';
import 'package:amaguexpress/src/common/map_helper.dart';
import 'package:amaguexpress/src/models/order_model.dart';
import 'package:amaguexpress/src/provider/push_provider.dart';
import 'package:amaguexpress/src/services/market_service.dart';

class OrderController extends ChangeNotifier {
  final _pushProvider = PushProvider();
  final MarketService marketService = MarketService();

  final Map<MarkerId, Marker> _markers = {};
  final MarkerId markerIdStore = const MarkerId('store');
  final MarkerId markerIdClient = const MarkerId('client');
  final MarkerId markerIdDeliveryMan = const MarkerId('deliveryman');
  late BitmapDescriptor iconDeliveryMan;
  late OrderModel _order;
  final SocketBloc _socketBloc = SocketBloc();

  Completer<GoogleMapController> _completer = Completer();
  late CameraPosition initialCameraPosition;

  OrderController(OrderModel order) {
    //print('INICIO OrderController');
    initialCameraPosition = CameraPosition(
        target: LatLng(order.location.x, order.location.y), zoom: 16);

    try {
      //print('Antes de deserializar OrderModel');
      _order = OrderModel.fromJson(order.toJson());
      //print('Después de deserializar OrderModel');
    } catch (e, stack) {
      print('Error al deserializar OrderModel en OrderController: $e');
      print('Stacktrace: $stack');
    }

    // addMarkers();
    // onListenerPositions();

    _pushProvider.notifications.listen(evaluateNotification);
    //print('FIN OrderController');
  }

  evaluateNotification(Map<String, dynamic> notification) async {
    if (order.id.toString() == notification['orderId']) {
      switch (notification['type']) {
        case TypesNotification.changeOrderStatust:
          refreshOrder();
          break;
        case TypesNotification.messageChat:
          order.notificationsClient++;
          notifyListeners();
          break;
        default:
      }
    }
  }

  qualify() async {
    await marketService.qualify(order);
  }

  refreshOrder() async {
    order = await marketService.getOrder(order);
    onListenerPositions();
  }

  cleanNotificationsClient() {
    order.notificationsClient = 0;
    notifyListeners();
  }

  OrderModel get order => _order;

  set order(OrderModel order) {
    _order = order;
    notifyListeners();
  }

  centerMap() async {
    final GoogleMapController controller = await _completer.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(
        MapHelper().latLngBounds(
            order.location.x, order.location.y, order.start.x, order.start.y),
        130.0));
  }

  addMarkers() async {
    await addMarkertStore();
    await addMarkertClient();
    notifyListeners();
  }

  Set<Marker> get markers => _markers.values.toSet();

  onMapCreated(GoogleMapController controller) async {
    _completer = Completer();
    _completer.complete(controller);

    // Ensure base markers are always loaded for the client view.
    // (Store/Deliveryman screens may call this elsewhere, but the client needs it here.)
    await addMarkers();

    // If the order is already assigned/taken, start listening for deliveryman updates.
    await onListenerPositions();
  }

  onListenerPositions() async {
    _socketBloc.close();
    if (order.status == StatusOrder.assigned ||
        order.status == StatusOrder.taken) {
      // Start the deliveryman marker near the store so it is visible until the first real position arrives.
      addMarkertDeliveryMan(order.start.x, order.start.y);
      _socketBloc.connect(order.deliveryman!.id);
      _socketBloc.stream.listen((position) {
        updateLocationDeliveryMan(position);
      });
    }
  }

  addMarkertStore() async {
    // Use the same store icon as other roles (local asset), to keep a consistent UI
    // and avoid remote logo images that can look distorted on the map.
    final icon = await toBytes('assets/restaurant.png', 44, isLocal: true);
    addMarker(markerIdStore, icon, LatLng(order.start.x, order.start.y));
  }

  addMarkertClient() async {
    final icon = await toBytes('assets/home.png', 38, isLocal: true);
    addMarker(markerIdClient, icon, LatLng(order.location.x, order.location.y));
  }

  addMarkertDeliveryMan(double lt, double lg) async {
    final icon = await toBytes('assets/car.png', 36, isLocal: true);
    iconDeliveryMan = icon;
    addMarker(markerIdDeliveryMan, icon, LatLng(lt, lg));
  }

  addMarker(MarkerId markerId, BitmapDescriptor icon, LatLng position) {
    final market = Marker(
      markerId: markerId,
      icon: icon,
      position: position,
      anchor: const ui.Offset(0.5, 0.9),
    );
    _markers[markerId] = market;
  }

  updateLocationDeliveryMan(LatLng position) async {
    LatLng oldPosition = _markers[markerIdDeliveryMan]!.position;

    double rotation = Geolocator.bearingBetween(oldPosition.latitude,
        oldPosition.longitude, position.latitude, position.longitude);

    final market = Marker(
      markerId: markerIdDeliveryMan,
      icon: iconDeliveryMan,
      position: position,
      rotation: rotation,
    );
    _markers[markerIdDeliveryMan] = market;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _socketBloc.disposeStreams();
  }
}
