package com.example.object_detector // <<<<< CHANGE THIS TO YOUR ACTUAL PACKAGE NAME

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import androidx.annotation.NonNull // Or io.flutter.plugins.GeneratedPluginRegistrant if you use other plugins

// Import your plugin class
// The import path should match the package and class name of your ObjectDetectorPlugin.kt
// For example, if ObjectDetectorPlugin.kt is in the same package:
// import com.example.object_detector.ObjectDetectorPlugin // <<<< IF IN THE SAME PACKAGE

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine) // Important to call super

        // Register your custom plugin
        // Make sure ObjectDetectorPlugin is correctly imported or in the same package
        try {
            flutterEngine.plugins.add(ObjectDetectorPlugin()) // <<<<< ADD THIS LINE
            android.util.Log.d("MainActivity", "ObjectDetectorPlugin registered successfully.")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error registering ObjectDetectorPlugin", e)
        }

        // If you use other plugins that are auto-registered via GeneratedPluginRegistrant,
        // that line might already be here. Ensure your plugin is added too.
        // Example: io.flutter.plugins.GeneratedPluginRegistrant.registerWith(flutterEngine);
        // It's generally fine to add your plugin manually like above.
    }
}