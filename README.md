
## Setup Instructions

1.  **Flutter Environment:**
    *   Ensure you have the latest Flutter SDK installed and configured.
    *   Verify your Flutter setup with `flutter doctor`.

2.  **Clone the Repository:**
    ```bash
    git clone <your-repository-url>
    cd my_object_detector
    ```

3.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Platform Specific Setup:**

    *   **Android:**
        *   Open the project in Android Studio (the `android` folder).
        *   Ensure `minSdkVersion` in `android/app/build.gradle` is at least `21` (or as required by the ML Kit version used).
        *   Android Studio should automatically sync Gradle dependencies. If not, trigger a manual sync.
        *   The necessary ML Kit dependencies (`com.google.mlkit:object-detection`) are included in `android/app/build.gradle`.

    

## Implementation Explanation

The application follows these main steps:

1.  **Flutter UI & Camera (`lib/object_detector_view.dart`, `lib/main.dart`):**
    *   The `camera` plugin is used to initialize and display a live camera preview.
    *   `CameraController.startImageStream` provides a continuous stream of `CameraImage` objects.

2.  **Image Processing in Dart (`lib/object_detector_view.dart`):**
    *   For each `CameraImage`:
        *   The device orientation and camera sensor orientation are used to calculate the `imageRotation` required by the native ML Kit SDKs to correctly interpret the image.
        *   The `_imageSize` (width and height of the `CameraImage`) is stored for use by the `DetectionPainter`.

3.  **Platform Channel Communication (`lib/object_detector_service.dart`):**
    *   A `MethodChannel` named `com.example.my_object_detector/ml_kit` is established.
    *   The `ObjectDetectorService` class encapsulates the platform channel calls.
    *   The `detectObjects` method takes the `CameraImage` and `imageRotation`.
    *   It serializes the image data (width, height, YUV image planes as `List<Map<String, ByteArray>>`, and rotation) into a `Map`.
    *   This map is sent to the native side using `_channel.invokeMethod('detect', imageData)`.
    *   It awaits and returns the detection results (a `List<Map<String, dynamic>>`) from the native side.

4.  **Native Android Implementation (`android/.../ObjectDetectorPlugin.kt`):**
    *   `ObjectDetectorPlugin.kt` implements `FlutterPlugin` and `MethodChannel.MethodCallHandler`.
    *   It's registered in `MainActivity.kt`.
    *   **Channel Handling:** Listens for the `detect` method call on the defined channel.
    *   **Data Parsing:** Deserializes the image data (width, height, planes, rotation) from the arguments map.
    *   **InputImage Creation:**
        *   The Y, U, and V plane `ByteArray`s are extracted.
        *   These byte arrays are concatenated into a single `ByteBuffer` (`yuvBuffer`).
        *   An ML Kit `InputImage` is created using `InputImage.fromByteBuffer(yuvBuffer, width, height, rotationDegrees, InputImage.IMAGE_FORMAT_YUV_420_888)`. This format expects planar Y, U, V data in the buffer.
    *   **ML Kit Object Detection:**
        *   An `ObjectDetector` is initialized with `STREAM_MODE`, classification, and multiple object detection enabled.
        *   `objectDetector.process(inputImage)` is called.
    *   **Result Formatting:**
        *   On success, the list of `DetectedObject`s is processed.
        *   For each object, a map containing the normalized `boundingBox` (0.0-1.0), `trackingId`, and `labels` (text, confidence) is created.
        *   This list of maps is sent back to Flutter via `flutterResult.success()`.
    *   **Error Handling:** On failure, an error is sent back via `flutterResult.error()`.

5.  **Native iOS Implementation (`ios/.../ObjectDetectorPlugin.swift` - *Outline*):**
    *   (This section would detail the iOS equivalent if fully implemented).
    *   A Swift class `ObjectDetectorPlugin` would implement `FlutterPlugin` and register as a handler for the same `MethodChannel`.
    *   It would parse incoming image data.
    *   **InputImage Creation (iOS):**
        *   Convert Flutter's `CameraImage` data (CVPixelBuffer or raw bytes) into a `VisionImage` (for ML Kit on-device via Vision) or an `MLImage` (if using direct ML Kit models with custom handling).
        *   Handle image orientation correctly for the Vision framework or ML Kit iOS.
    *   **ML Kit/Vision Object Detection (iOS):**
        *   Use `VNDetectObjectsRequest` (Vision) or configure an ML Kit `ObjectDetector` for iOS.
        *   Process the image.
    *   **Result Formatting (iOS):**
        *   Convert detection results (`VNRecognizedObjectObservation` or ML Kit iOS objects) into a `List<Map<String, Any>>` similar to Android, with normalized bounding boxes and labels.
        *   Send results back to Flutter.

6.  **Displaying Detections (`lib/detection_painter.dart`):**
    *   The `_detectionResults` list (received in Flutter) and `_imageSize` are passed to `DetectionPainter`.
    *   `DetectionPainter` (a `CustomPainter`) is overlaid on the `CameraPreview`.
    *   **Coordinate Transformation:** It scales and translates the normalized bounding box coordinates (relative to the `originalImageSize`) to fit correctly onto the `previewScreenSize` (the actual rendered size of the `CameraPreview` widget). This involves calculating scale factors and offsets to handle aspect ratio differences.
    *   **Mirroring:** For the front camera, horizontal coordinates are flipped to match the mirrored preview.
    *   It draws rectangles for bounding boxes and uses `TextPainter` to display labels and confidence scores.

## What We Have Done (Summary of Progress)

*   **Flutter Project Setup:** Created a new Flutter project from scratch.
*   **Camera Integration:** Successfully integrated the `camera` plugin to display a live feed and stream `CameraImage` data.
*   **Platform Channel Definition (Dart):** Defined `ObjectDetectorService` and the `MethodChannel` contract for sending image data and receiving detection results. Image data includes planes, dimensions, and calculated rotation.
*   **Android Native Implementation (Kotlin):**
    *   Added ML Kit `object-detection` dependency.
    *   Created `ObjectDetectorPlugin.kt` to handle method calls.
    *   Successfully parsed incoming image data from Dart.
    *   Implemented the logic to convert Flutter's `CameraImage` YUV planes into a single `ByteBuffer` and then into an ML Kit `InputImage` using `InputImage.fromByteBuffer` with `IMAGE_FORMAT_YUV_420_888`.
    *   Initialized and used the ML Kit `ObjectDetector` to process these `InputImage`s.
    *   Formatted detection results (normalized bounding boxes, labels, confidence) into a list of maps and sent them back to Flutter.
    *   Registered the plugin in `MainActivity.kt`.
*   **Flutter UI for Results:**
    *   The `ObjectDetectorView` state now receives and stores detection results from the native side.
    *   Implemented `DetectionPainter` to draw bounding boxes and labels.
    *   Worked on the coordinate transformation logic within the painter to map normalized ML Kit coordinates to screen preview coordinates, including handling aspect ratios and front-camera mirroring.
    *   The `build` method in `ObjectDetectorView` now conditionally renders `CustomPaint` using `LayoutBuilder` to attempt to get the correct preview size for the painter.
*   **Debugging & Iteration:**
    *   Iteratively debugged issues related to `InputImage` creation on Android (e.g., "Unresolved reference: fromYuvBuffers", "IllegalArgumentException: Image width and height must be positive", "NullPointerException" for plane bytes).
    *   Added extensive logging on both Dart and Kotlin sides to trace data flow and identify errors.

## Issues and Roadblocks Faced (Example - *Customize This*)

*   **`InputImage` Creation on Android:**
    *   Initial attempts to use non-existent or outdated ML Kit methods for YUV conversion (like `fromYuvBuffers`) led to "Unresolved reference" errors.
    *   The correct approach involved concatenating Y, U, V plane `ByteArray`s into a single `ByteBuffer` and using `InputImage.fromByteBuffer` with the `IMAGE_FORMAT_YUV_420_888` flag. This required careful handling of byte data.
*   **`IllegalArgumentException: Image width and height must be positive`:** This occurred when the `width` or `height` passed to `InputImage.fromByteBuffer` was zero. Traced back to either `CameraImage` providing zero dimensions initially or the default value (`?: 0`) in Kotlin being used. Solved by ensuring valid dimensions are passed from Dart and checked.
*   **`NullPointerException` for Plane Bytes:** Encountered when one of the Y, U, or V plane byte arrays was `null` before `ByteBuffer.wrap()`. Solved by adding explicit null checks in Kotlin before wrapping.
*   **Coordinate Transformation for Painter:** Accurately mapping normalized bounding box coordinates from the ML Kit model (which sees the raw `CameraImage`) to the on-screen `CameraPreview` widget dimensions is complex. This involves:
    *   Getting the correct `originalImageSize` (from `CameraImage`).
    *   Determining the `previewScreenSize` (the actual rendered size of the `CameraPreview` widget, which might be affected by `AspectRatio` and `Center` widgets). Using `LayoutBuilder` helps here.
    *   Calculating scale factors and offsets.
    *   Handling front-camera mirroring. This often requires iterative adjustments.
*   **(If applicable) iOS Implementation Complexity:** Setting up ML Kit or Vision on iOS natively, handling `CVPixelBuffer` conversion, and managing memory and threading can be more involved than on Android if not familiar with Swift/Objective-C specifics for camera processing.
*   **(If applicable) Asynchronous Nature:** Managing the async flow between `startImageStream`, platform channel calls, and UI updates (`setState`) requires care to avoid race conditions or excessive processing. The `_isDetecting` flag helps manage this.

** App is not detecting the object due to some specific error. Error will be resolved in coming days


