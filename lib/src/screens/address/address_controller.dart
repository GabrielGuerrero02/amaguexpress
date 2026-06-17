import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/bloc/location_bloc.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/provider/db_provider.dart';
import 'package:amaguexpress/src/services/address_service.dart';

class AddressController extends ChangeNotifier {
  final AddressService addressService = AddressService();
  late AddressModel _address;
  final Completer<GoogleMapController> _completer = Completer();
  GoogleMapController? _mapController;
  bool _isDisposed = false;
  late CameraPosition initialCameraPosition;

  Future<GoogleMapController> getController() async =>
      _mapController ?? await _completer.future;

  AddressController(AddressModel address) {
    _address = address;
    initialCameraPosition = CameraPosition(
        target: LatLng(_address.location.x, _address.location.y), zoom: 16);
  }

  AddressModel get address => _address;
  bool _inAsyncCall = false;

  bool get inAsyncCall => _inAsyncCall;

  set inAsyncCall(bool asyncCall) {
    _inAsyncCall = asyncCall;
    notifyListeners();
  }

  onMapCreated(GoogleMapController controller) async {
    if (_isDisposed) return;

    _mapController = controller;

    if (!_completer.isCompleted) {
      _completer.complete(controller);
    }
  }

  onCameraMove(CameraPosition cameraPosition) {
    _address.location.x = cameraPosition.target.latitude;
    _address.location.y = cameraPosition.target.longitude;
  }

  Future<AddressModel?> createAdrress() async {
    inAsyncCall = true;

    AddressModel? addressResponse;
    if (_address.id > 0) {
      addressResponse = await addressService.update(_address);
    } else {
      addressResponse = await addressService.create(_address);
    }

    if (addressResponse == null) {
      inAsyncCall = false;
      return null;
    }
    await DBProvider.db.createAddress(addressResponse);
    inAsyncCall = false;
    return addressResponse;
  }

  //When the client is not authenticated, it is only saved on a local basis.
  saveAdrressDb() async {
    inAsyncCall = true;
    _address.alias = S.current.lNewAddress;
    await DBProvider.db.createAddress(_address);
    inAsyncCall = false;
  }

  final LocationBloc _locationBloc = LocationBloc();

  myLocation() async {
    inAsyncCall = true;
    final List location = await _locationBloc.determinePosition();
    inAsyncCall = false;
    try {
      final GoogleMapController controller = await getController();

      if (_isDisposed) return;

      await controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(location[0], location[1]), zoom: 16)));
    } catch (e) {
      debugPrint('AddressController.myLocation animateCamera ignored: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController = null;
    super.dispose();
  }
}
