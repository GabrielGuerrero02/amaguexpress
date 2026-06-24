import 'dart:async';

import 'package:flutter/material.dart' show ChangeNotifier, debugPrint;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/constants/status_constant.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/src/common/file_helper.dart';
import 'package:amaguexpress/src/common/map_helper.dart';
import 'package:amaguexpress/src/models/request_model.dart';
import 'package:amaguexpress/src/provider/push_provider.dart';
import 'package:amaguexpress/src/services/request_service.dart';

class RequestController extends ChangeNotifier {
  final _pushProvider = PushProvider();
  RequestService requestService = RequestService();

  final Map<MarkerId, Marker> _markers = {};
  final MarkerId markerIdStore = const MarkerId('store');
  final MarkerId markerIdClient = const MarkerId('client');
  late RequestModel _request;

  final Completer<GoogleMapController> _completer = Completer();
  GoogleMapController? _mapController;
  bool _isDisposed = false;
  int _notificationsClientStoreChat = 0;
  int _notificationsStoreDeliverymanChat = 0;
  int _preparationTimeMinutes = 15;

  late CameraPosition initialCameraPosition;

  RequestController(RequestModel request) {
    // Clone the object, avoiding duplicate increases in the number of messages received.
    // RequestsController _pushProvider AND RequestController _pushProvider
    _request = RequestModel.fromJson(request.toJson());

    initialCameraPosition = CameraPosition(
        target: LatLng(request.location.x, request.location.y), zoom: 16);
    addMarkers();

    _pushProvider.notifications.listen(evaluateNotification);
  }

  evaluateNotification(Map<String, dynamic> notification) async {
    if (request.id.toString() == notification['orderId']) {
      switch (notification['type']) {
        case TypesNotification.changeOrderStatust:
          refreshRequest();
          break;
        case TypesNotification.messageChat:
          final channel = notification['channel']?.toString();

          if (channel == 'client_store') {
            _notificationsClientStoreChat++;
          } else if (channel == 'store_deliveryman') {
            _notificationsStoreDeliverymanChat++;
          }

          notifyListeners();
          break;
        default:
      }
    }
  }

  refreshRequest() async {
    request = await requestService.findRequest(request);
  }

  centerMap() async {
    try {
      final GoogleMapController controller =
          _mapController ?? await _completer.future;

      if (_isDisposed) return;

      await controller.animateCamera(CameraUpdate.newLatLngBounds(
          MapHelper().latLngBounds(request.location.x, request.location.y,
              request.store.location.x, request.store.location.y),
          130.0));
    } catch (e) {
      debugPrint('RequestController.centerMap animateCamera ignored: $e');
    }
  }

  int get notificationsClientStoreChat => _notificationsClientStoreChat;

  int get notificationsStoreDeliverymanChat =>
      _notificationsStoreDeliverymanChat;

  cleanNotificationsClient() {
    _notificationsClientStoreChat = 0;
    _request.notificationsDeliveryman = 0;
    notifyListeners();
  }

  cleanNotificationsDeliveryman() {
    _notificationsStoreDeliverymanChat = 0;
    notifyListeners();
  }

  bool _inAsyncCall = false;

  bool get inAsyncCall => _inAsyncCall;

  int get preparationTimeMinutes => _preparationTimeMinutes;

  bool get isPendingStoreConfirmation =>
      request.status == StatusOrder.pendingStoreConfirmation;

  set inAsyncCall(bool asyncCall) {
    _inAsyncCall = asyncCall;
    notifyListeners();
  }

  void increasePreparationTime() {
    if (_preparationTimeMinutes >= 60) return;
    _preparationTimeMinutes += 5;
    notifyListeners();
  }

  void decreasePreparationTime() {
    if (_preparationTimeMinutes <= 5) return;
    _preparationTimeMinutes -= 5;
    notifyListeners();
  }

  Future<bool> acceptRequest() async {
    inAsyncCall = true;
    try {
      final acceptedRequest = await requestService.acceptRequest(
        request,
        preparationTimeMinutes,
      );

      if (acceptedRequest == null) return false;

      request = acceptedRequest;
      return true;
    } finally {
      inAsyncCall = false;
    }
  }

  Future<bool> rejectRequest() async {
    inAsyncCall = true;
    try {
      final rejectedRequest = await requestService.rejectRequest(request);

      if (rejectedRequest == null) return false;

      request = rejectedRequest;
      return true;
    } finally {
      inAsyncCall = false;
    }
  }

  RequestModel get request => _request;

  set request(RequestModel request) {
    _request = request;
    notifyListeners();
  }

  addMarkers() async {
    await addMarkertStore();
    await addMarkertClient();
    notifyListeners();
  }

  Set<Marker> get markers => _markers.values.toSet();

  onMapCreated(GoogleMapController controller) async {
    if (_isDisposed) return;

    _mapController = controller;

    if (!_completer.isCompleted) {
      _completer.complete(controller);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController = null;
    super.dispose();
  }

  addMarkertStore() async {
    final icon = await toBytes('assets/restaurant.png', 44, isLocal: true);
    addMarker(markerIdStore, icon,
        LatLng(request.store.location.x, request.store.location.y));
  }

  addMarkertClient() async {
    final icon = await toBytes('assets/home.png', 38, isLocal: true);
    addMarker(
        markerIdClient, icon, LatLng(request.location.x, request.location.y));
  }

  addMarker(MarkerId markerId, BitmapDescriptor icon, LatLng position) {
    final market = Marker(markerId: markerId, icon: icon, position: position);
    _markers[markerId] = market;
  }
}
