package com.nakrub.mmm

import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mmm/clothing_analysis",
        ).setMethodCallHandler { call, result ->
            if (call.method != "classifyImage") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.arguments as? ByteArray
            val bitmap = bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
            if (bitmap == null) {
                result.error("invalid_image", "Valid image bytes are required.", null)
                return@setMethodCallHandler
            }

            val labeler = ImageLabeling.getClient(
                ImageLabelerOptions.Builder().setConfidenceThreshold(0.05f).build(),
            )
            labeler.process(InputImage.fromBitmap(bitmap, 0))
                .addOnSuccessListener { labels ->
                    result.success(
                        labels.sortedByDescending { it.confidence }.take(20).map {
                            mapOf("label" to it.text, "confidence" to it.confidence.toDouble())
                        },
                    )
                }
                .addOnFailureListener { error ->
                    result.error("mlkit_failed", error.localizedMessage, null)
                }
                .addOnCompleteListener {
                    labeler.close()
                    bitmap.recycle()
                }
        }
    }
}
