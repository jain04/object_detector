// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// Assuming ObjectDetectorView is in object_detector_view.dart in the same lib folder
import 'object_detector_view.dart';

List<CameraDescription> cameras = []; // Global list

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error initializing cameras: ${e.code}\nError Message: ${e.description}');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Object Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // No need to pass 'cameras' if ObjectDetectorView accesses the global one
      home: const ObjectDetectorView(),
    );
  }
}