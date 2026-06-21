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
  final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  final firebase_storage.Reference storageReference =
      firebase_storage.FirebaseStorage.instance.ref(folder).child(safeName);

  try {
    if (kDebugMode) {
      print('[FirebaseStorage] uploadFile -> folder=$folder');
      print('[FirebaseStorage] uploadFile -> name=$safeName');
      print('[FirebaseStorage] uploadFile -> file=${file.path}');
      print('[FirebaseStorage] uploadFile -> targetWidth=$targetWidth');
    }

    // Si targetWidth es mayor a 0, procesamos la imagen
    if (targetWidth > 0) {
      final originalBytes = await file.readAsBytes();

      if (kDebugMode) {
        print(
            '[FirebaseStorage] uploadFile -> originalBytes=${originalBytes.length}');
      }

      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        if (kDebugMode) {
          print('[FirebaseStorage] uploadFile -> decodeImage returned null');
        }
        return '';
      }

      if (kDebugMode) {
        print(
            '[FirebaseStorage] uploadFile -> decoded=${decoded.width}x${decoded.height}');
      }

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

      if (kDebugMode) {
        print(
            '[FirebaseStorage] uploadFile -> compressedBytes=${compressedBytes.length}');
        print('[FirebaseStorage] uploadFile -> putData start');
      }

      final metadata = firebase_storage.SettableMetadata(
        contentType: 'image/jpeg',
      );

      final firebase_storage.UploadTask uploadTask = storageReference.putData(
        Uint8List.fromList(compressedBytes),
        metadata,
      );
      await uploadTask.whenComplete(() => null);

      if (kDebugMode) {
        print('[FirebaseStorage] uploadFile -> putData done');
      }
    } else {
      if (kDebugMode) {
        print('[FirebaseStorage] uploadFile -> putFile original start');
      }

      final firebase_storage.UploadTask uploadTask =
          storageReference.putFile(file);
      await uploadTask.whenComplete(() => null);

      if (kDebugMode) {
        print('[FirebaseStorage] uploadFile -> putFile original done');
      }
    }

    if (kDebugMode) {
      print('[FirebaseStorage] uploadFile -> getDownloadURL start');
    }

    final String url = await storageReference.getDownloadURL();

    if (kDebugMode) {
      print('[FirebaseStorage] uploadFile -> getDownloadURL done');
      print('[FirebaseStorage] uploadFile -> url=$url');
    }

    return '${url.split('?alt=media&token=')[0]}?alt=media';
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('[FirebaseStorage] uploadFile ERROR: $e');
      print('[FirebaseStorage] uploadFile STACK: $stackTrace');
    }
    return '';
  }
}
