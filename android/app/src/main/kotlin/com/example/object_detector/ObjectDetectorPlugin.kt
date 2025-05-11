package com.example.object_detector // Or your consistent package name

import android.graphics.ImageFormat // Keep this for ImageFormat.YUV_420_888 constant
import androidx.annotation.NonNull
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.ObjectDetector
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer
import android.util.Log

class ObjectDetectorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var objectDetector: ObjectDetector? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.my_object_detector/ml_kit") // Ensure this matches Dart
        channel.setMethodCallHandler(this)

        val options = ObjectDetectorOptions.Builder()
            .setDetectorMode(ObjectDetectorOptions.STREAM_MODE)
            .enableClassification()
            .enableMultipleObjects()
            .build()
        objectDetector = ObjectDetection.getClient(options)
        Log.d("ObjectDetectorPlugin", "ML Kit Object Detector Initialized.")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "detect") {
            try {
                val imageData = call.arguments as? Map<String, Any>
                if (imageData == null) {
                    Log.e("ObjectDetectorPlugin", "Image data is null in onMethodCall")
                    result.error("INVALID_ARGUMENT", "Image data is null", null)
                    return
                }
                handleDetection(imageData, result)
            } catch (e: Exception) {
                Log.e("ObjectDetectorPlugin", "Error processing detect call in onMethodCall", e)
                result.error("DETECTION_ERROR", "Exception in onMethodCall: ${e.message}", e.stackTraceToString())
            }
        } else {
            result.notImplemented()
        }
    }

    private fun handleDetection(imageData: Map<String, Any>, flutterResult: Result) {
    Log.d("ObjectDetectorPlugin", "handleDetection ENTERED") // Did we even get here?
    try {
        val width = imageData["width"] as? Int ?: 0
        val height = imageData["height"] as? Int ?: 0
        val rotationDegrees = imageData["rotation"] as? Int ?: 0
        Log.d("ObjectDetectorPlugin", "Image params: W=$width, H=$height, Rot=$rotationDegrees")

        @Suppress("UNCHECKED_CAST")
        val planeMaps = imageData["planes"] as? List<Map<String, Any>>

        if (width == 0 || height == 0 || planeMaps == null || planeMaps.size < 3) {
            Log.e("ObjectDetectorPlugin", "INVALID_IMAGE_DATA: W=$width, H=$height, planeMapsIsNull=${planeMaps == null}, planeMapsSize=${planeMaps?.size}")
            flutterResult.error("INVALID_IMAGE_DATA", "Image dimensions or plane maps are invalid.", null)
            return
        }
        Log.d("ObjectDetectorPlugin", "PlaneMaps count: ${planeMaps.size}")


        val yPlane = planeMaps[0]
        val uPlane = planeMaps[1]
        val vPlane = planeMaps[2]

        val yBytes = yPlane["bytes"] as? ByteArray
        val uBytes = uPlane["bytes"] as? ByteArray
        val vBytes = vPlane["bytes"] as? ByteArray

        if (yBytes == null || uBytes == null || vBytes == null) {
            Log.e("ObjectDetectorPlugin", "INVALID_PLANE_BYTES: yBytesIsNull=${yBytes == null}, uBytesIsNull=${uBytes == null}, vBytesIsNull=${vBytes == null}")
            flutterResult.error("INVALID_PLANE_BYTES", "Plane bytes are null.", null)
            return
        }
        Log.d("ObjectDetectorPlugin", "Plane bytes sizes: Y=${yBytes.size}, U=${uBytes.size}, V=${vBytes.size}")


        val yBuffer = ByteBuffer.wrap(yBytes)
        val uBuffer = ByteBuffer.wrap(uBytes)
        val vBuffer = ByteBuffer.wrap(vBytes)

        val yuvBuffer = ByteBuffer.allocateDirect(yBytes.size + uBytes.size + vBytes.size)
        yuvBuffer.put(yBuffer); yuvBuffer.put(uBuffer); yuvBuffer.put(vBuffer)
        yuvBuffer.flip()
        Log.d("ObjectDetectorPlugin", "yuvBuffer created, capacity: ${yuvBuffer.capacity()}")


        val inputImage = InputImage.fromByteBuffer(
            yuvBuffer, width, height, rotationDegrees, InputImage.IMAGE_FORMAT_YUV_420_888
        )
        Log.d("ObjectDetectorPlugin", "InputImage created successfully.")


        objectDetector?.process(inputImage)
            ?.addOnSuccessListener { detectedObjects ->
                Log.d("ObjectDetectorPlugin", "ML Kit Success: Found ${detectedObjects.size} objects.") // <<< KEY LOG
                val resultList = mutableListOf<Map<String, Any?>>()
                // ... (rest of your success logic)
                if (detectedObjects.isNotEmpty()) {
                     Log.d("ObjectDetectorPlugin", "First object details: ${detectedObjects[0].labels.joinToString { it.text }} BB: ${detectedObjects[0].boundingBox}")
                }
                flutterResult.success(resultList)
            }
            ?.addOnFailureListener { e ->
                Log.e("ObjectDetectorPlugin", "ML Kit Failure", e) // <<< KEY LOG
                flutterResult.error("MLKIT_ERROR", "Object detection failed: ${e.message}", e.stackTraceToString())
            }
    } catch (e: Exception) {
        Log.e("ObjectDetectorPlugin", "Exception in handleDetection", e)
        flutterResult.error("HANDLE_DETECTION_EXCEPTION", "Exception: ${e.message}", e.stackTraceToString())
    }
}

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        objectDetector?.close()
        objectDetector = null
        Log.d("ObjectDetectorPlugin", "Object Detector closed and detached from engine.")
    }
}