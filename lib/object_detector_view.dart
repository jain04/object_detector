// lib/object_detector_view.dart (or your view file)

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:object_detector/main.dart';
import 'object_detector_service.dart';
import 'detection_painter.dart'; // <<<<<<< IMPORT THE PAINTER

// Assuming 'cameras' list from main.dart is accessible or passed
// If ObjectDetectorView is in its own file, 'cameras' must be passed in.
// For this example, I'll assume 'cameras' is the global list from your main.dart snippet.
// If not, you'll need to adjust how 'cameras' is accessed (e.g., pass via constructor).
// extern List<CameraDescription> cameras; // This would be if it's truly global from main.dart

class ObjectDetectorView extends StatefulWidget {
  // If 'cameras' is not global, it should be passed in:
  // final List<CameraDescription> cameras;
  // const ObjectDetectorView({super.key, required this.cameras});
  const ObjectDetectorView({super.key}); // Assuming global 'cameras' for now based on your snippet

  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorViewState();
}

class _ObjectDetectorViewState extends State<ObjectDetectorView> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<dynamic> _detectionResults = [];
  bool _isDetecting = false;
  final ObjectDetectorService _detectorService = ObjectDetectorService();
  CameraDescription? _selectedCamera;

  // To store the actual image dimensions from CameraImage for the painter
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    // Access the global 'cameras' list (defined in your main.dart)
    // This is not ideal; passing via constructor is better.
    // For now, to match your snippet:
    if (cameras.isNotEmpty) { // Check if global 'cameras' list is populated
      _initializeCamera();
    } else {
      debugPrint("ObjectDetectorView: Global 'cameras' list is empty or not accessible.");
    }
  }

  Future<void> _initializeCamera() async {
    // Use the global 'cameras' list
    _selectedCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first);

    _cameraController = CameraController(
      _selectedCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();
      _isCameraInitialized = true;
      _cameraController!.startImageStream(_processCameraImage);
    } on CameraException catch (e) {
      debugPrint("Error initializing camera: ${e.code}\n${e.description}");
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isCameraInitialized || _cameraController == null || _selectedCamera == null) return;
    if (_isDetecting) return;

    _isDetecting = true;

    // Store/update the image size from the current frame for the painter
    // This is the resolution of the image sent to ML Kit
    if (mounted) {
      setState(() { // Ensure _imageSize is updated within setState if it affects painter directly
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }


    try {
      final DeviceOrientation deviceOrientation = _cameraController!.value.deviceOrientation;
      final int sensorOrientation = _selectedCamera!.sensorOrientation;
      final bool isFrontCamera = _selectedCamera!.lensDirection == CameraLensDirection.front;
      int imageRotation = _calculateImageRotationForAndroid(sensorOrientation, deviceOrientation, isFrontCamera);

      final List<dynamic>? results = await _detectorService.detectObjects(image, imageRotation);

      if (mounted) {
        setState(() {
          _detectionResults = results ?? [];
          if (_detectionResults.isNotEmpty) {
            // print("Flutter Detection Results: $_detectionResults"); // Good for debugging
          }
        });
      }
    } catch (e) {
      debugPrint("Error in _processCameraImage (Flutter): $e");
    } finally {
      _isDetecting = false;
    }
  }

  int _calculateImageRotationForAndroid(int sensorOrientation, DeviceOrientation deviceOrientation, bool isFrontCamera) {
    int rotationCompensation = 0;
    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp: rotationCompensation = 0; break;
      case DeviceOrientation.landscapeLeft: rotationCompensation = 90; break;
      case DeviceOrientation.portraitDown: rotationCompensation = 180; break;
      case DeviceOrientation.landscapeRight: rotationCompensation = 270; break;
    }
    int imageRotation;
    if (isFrontCamera) {
      imageRotation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      imageRotation = (sensorOrientation - rotationCompensation + 360) % 360;
    }
    return imageRotation;
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(key: Key("loadingIndicator"))),
      );
    }

    // This is the size of the CameraPreview widget itself on the screen.
    final Size previewWidgetSize = _cameraController!.value.previewSize ?? MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Native Object Detection')),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Center the CameraPreview to handle aspect ratio differences
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!, key: const Key("cameraPreview")),
            ),
          ),
          // Conditionally add the CustomPaint widget if there are results AND sizes are known
          if (_detectionResults.isNotEmpty && _imageSize != null && _selectedCamera != null)
            LayoutBuilder( // Use LayoutBuilder to get the actual size the CustomPaint can occupy
              builder: (context, constraints) {
                // The previewScreenSize for the painter should be the actual size of the CameraPreview area.
                // If CameraPreview is wrapped in AspectRatio and Center, its actual rendered size
                // might be smaller than `constraints.biggest`. We need to calculate it.

                double actualPreviewWidth = constraints.maxWidth;
                double actualPreviewHeight = constraints.maxHeight;

                final double screenAspectRatio = constraints.maxWidth / constraints.maxHeight;
                final double cameraAspectRatio = _cameraController!.value.aspectRatio;

                if (screenAspectRatio > cameraAspectRatio) {
                  // Screen is wider than camera preview (letterboxed vertically or full height)
                  actualPreviewWidth = constraints.maxHeight * cameraAspectRatio;
                } else {
                  // Screen is taller than camera preview (pillarboxed horizontally or full width)
                  actualPreviewHeight = constraints.maxWidth / cameraAspectRatio;
                }
                final Size actualRenderedPreviewSize = Size(actualPreviewWidth, actualPreviewHeight);


                return CustomPaint(
                  // The CustomPaint widget itself will take the full space of the Stack by default (fit: StackFit.expand)
                  // or the size given by LayoutBuilder constraints.
                  // We need to pass the *actual rendered size of the CameraPreview* to the painter.
                  size: constraints.biggest, // CustomPaint takes full space
                  painter: DetectionPainter(
                    detections: _detectionResults,
                    originalImageSize: _imageSize!, // Actual CameraImage dimensions
                    previewScreenSize: actualRenderedPreviewSize, // Size of the CameraPreview widget as rendered
                    screenOrientation: MediaQuery.of(context).orientation,
                    cameraLensDirection: _selectedCamera!.lensDirection,
                  ),
                );
              }
            ),
        ],
      ),
    );
  }
}