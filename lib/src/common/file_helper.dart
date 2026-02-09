import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;

// In-memory cache for marker bitmaps.
Map<String, BitmapDescriptor> _markerCache = <String, BitmapDescriptor>{};

/// Builds a Google Maps marker icon from an asset (local) or URL (remote),
/// resizing it to a consistent on-screen size.
///
/// - [targetWidth] is in logical pixels (dp). Internally we multiply by the
///   device pixel ratio to avoid huge icons on high-density screens.
/// - Uses an in-memory cache to avoid decoding the same icon repeatedly.
Future<BitmapDescriptor> toBytes(
  String path,
  int targetWidth, {
  required bool isLocal,
  int? targetHeight,
}) async {
  final dpr = (window.devicePixelRatio == 0) ? 1.0 : window.devicePixelRatio;
  final wPx = (targetWidth * dpr).round();
  final hPx = targetHeight != null ? (targetHeight * dpr).round() : null;

  final cacheKey = '${isLocal ? 'L' : 'R'}|$path|$wPx|${hPx ?? '-'}';
  final cached = _markerCache[cacheKey];
  if (cached != null) return cached;

  Uint8List bytes;
  if (isLocal) {
    final ByteData data = await rootBundle.load(path);
    bytes = data.buffer.asUint8List();
  } else {
    final file = await DefaultCacheManager().getSingleFile(path);
    bytes = await file.readAsBytes();
  }

  final codec = await instantiateImageCodec(
    bytes,
    targetWidth: wPx,
    targetHeight: hPx,
  );
  final frameInfo = await codec.getNextFrame();
  final imageData =
      await frameInfo.image.toByteData(format: ImageByteFormat.png);
  final descriptor = BitmapDescriptor.bytes(imageData!.buffer.asUint8List());

  _markerCache[cacheKey] = descriptor;
  return descriptor;
}

Future<String> uploadFile(
  io.File file,
  String folder,
  String name,
  int targetWidth,
) async {
  firebase_storage.Reference storageReference =
      firebase_storage.FirebaseStorage.instance.ref(folder).child(name);

  try {
    // Si targetWidth es mayor a 0, procesamos la imagen
    if (targetWidth > 0) {
      final originalBytes = await file.readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) return '';

      // Hacemos crop a cuadrado (desde el centro)
      final minSide =
          decoded.width < decoded.height ? decoded.width : decoded.height;
      final offsetX = ((decoded.width - minSide) / 2).round();
      final offsetY = ((decoded.height - minSide) / 2).round();
      final cropped = img.copyCrop(
        decoded,
        x: offsetX,
        y: offsetY,
        width: minSide,
        height: minSide,
      );

      // Redimensionamos a targetWidth
      final resized =
          img.copyResize(cropped, width: targetWidth, height: targetWidth);

      // Guardamos la imagen en formato JPG
      final compressedBytes = img.encodeJpg(resized, quality: 85);

      // Guardamos temporalmente para subir
      final tmpPath = '${file.parent.path}/${name}_compressed.jpg';
      final compressedFile = await File(tmpPath).writeAsBytes(compressedBytes);

      final firebase_storage.UploadTask uploadTask =
          storageReference.putFile(compressedFile);
      await uploadTask.whenComplete(() => null);
    } else {
      // Otros tipos de archivos, se suben tal como están
      final firebase_storage.UploadTask uploadTask =
          storageReference.putFile(file);
      await uploadTask.whenComplete(() => null);
    }
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(e);
    }
    return '';
  }

  final String url = await storageReference.getDownloadURL();
  return '${url.split('?alt=media&token=')[0]}?alt=media';
}
