// lib/object_detector_service.dart
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class ObjectDetectorService {
  static const MethodChannel _channel = MethodChannel('com.example.my_object_detector/ml_kit');

  Future<List<dynamic>?> detectObjects(CameraImage image, int imageRotation) async {
    try {
      // Prepare plane data WITH bytesPerRow for each plane
      // This structure is important for the native Android side to reconstruct the YUV image
      final List<Map<String, dynamic>> planesData = image.planes.map((plane) {
        return {
          'bytes': plane.bytes, // This is Uint8List
          'bytesPerRow': plane.bytesPerRow,
        };
      }).toList();

      final Map<String, dynamic> imageData = {
        'width': image.width,
        'height': image.height,
        'planes': planesData, // List of maps, each containing 'bytes' and 'bytesPerRow'
        'rotation': imageRotation, // The calculated rotation for the image
        // For iOS, you might need to adjust the plane data structure if its ML Kit
        // or Vision framework expects something different. For now, this targets Android.
      };

      // 'detect' is the method name we'll listen for on the native side
      final List<dynamic>? results = await _channel.invokeMethod('detect', imageData);
      return results;
    } on PlatformException catch (e) {
      print("Failed to detect objects via platform channel: '${e.message}'.");
      return null;
    } catch (e) {
      print("Error in ObjectDetectorService.detectObjects: $e");
      return null;
    }
  }
}