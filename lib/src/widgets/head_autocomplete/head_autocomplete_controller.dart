import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amaguexpress/src/models/address_model.dart';
import 'package:amaguexpress/src/models/prediction_model.dart';
import 'package:amaguexpress/src/services/address_service.dart';

class HeadAutocompleteController extends ChangeNotifier {
  final AddressService addressService = AddressService();

  List<PredictionModel> predictions = [];

  final Function getController;
  final double latitude;
  final double longitude;
  bool _isDisposed = false;

  HeadAutocompleteController({
    required this.getController,
    required this.latitude,
    required this.longitude,
  });

  autocomplete(String place) async {
    if (place.length < 3) {
      predictions.clear();
      if (!_isDisposed) notifyListeners();
      return;
    }
    predictions =
        await addressService.autocomplete(place, lt: latitude, lg: longitude);

    if (_isDisposed) return;

    notifyListeners();
  }

  geocode(String placeId) async {
    Location? location = await addressService.geocode(placeId);
    if (_isDisposed || location == null) return;

    try {
      final GoogleMapController controller = await getController();

      if (_isDisposed) return;

      await controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(location.x, location.y), zoom: 16)));
    } catch (e) {
      debugPrint(
          'HeadAutocompleteController.geocode animateCamera ignored: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
