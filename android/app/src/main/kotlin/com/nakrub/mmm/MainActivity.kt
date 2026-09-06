package com.nakrub.mmm

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.FloatBuffer

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mmm/clothing_analysis",
        ).setMethodCallHandler { call, result ->
            if (call.method == "segmentForeground") {
                segmentForeground(call.arguments as? Map<*, *>, result)
                return@setMethodCallHandler
            }
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

    private fun segmentForeground(
        arguments: Map<*, *>?,
        result: MethodChannel.Result,
    ) {
        val bytes = arguments?.get("bytes") as? ByteArray
        val bitmap = bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
        if (bitmap == null) {
            result.error("invalid_image", "Valid image bytes are required.", null)
            return
        }

        val options = SubjectSegmenterOptions.Builder()
            .enableForegroundConfidenceMask()
            .build()
        val segmenter = SubjectSegmentation.getClient(options)
        segmenter.process(InputImage.fromBitmap(bitmap, 0))
            .addOnSuccessListener { segmentation ->
                val mask = segmentation.foregroundConfidenceMask
                if (mask == null) {
                    result.success(null)
                    return@addOnSuccessListener
                }
                result.success(maskPayload(bitmap, mask))
            }
            .addOnFailureListener {
                result.success(null)
            }
            .addOnCompleteListener {
                segmenter.close()
                bitmap.recycle()
            }
    }

    private fun maskPayload(bitmap: Bitmap, mask: FloatBuffer): Map<String, Any> {
        val values = ByteArray(bitmap.width * bitmap.height)
        var minX = bitmap.width
        var minY = bitmap.height
        var maxX = -1
        var maxY = -1
        var total = 0f
        mask.rewind()
        for (y in 0 until bitmap.height) {
            for (x in 0 until bitmap.width) {
                val confidence = mask.get()
                total += confidence
                if (confidence > 0.5f) {
                    values[y * bitmap.width + x] = 255.toByte()
                    minX = minOf(minX, x)
                    minY = minOf(minY, y)
                    maxX = maxOf(maxX, x)
                    maxY = maxOf(maxY, y)
                }
            }
        }
        val hasForeground = maxX >= minX && maxY >= minY
        return mapOf(
            "width" to bitmap.width,
            "height" to bitmap.height,
            "mask" to values,
            "confidence" to (total / (bitmap.width * bitmap.height)).toDouble(),
            "boundingBox" to if (hasForeground) {
                listOf(
                    minX.toDouble() / bitmap.width,
                    minY.toDouble() / bitmap.height,
                    (maxX + 1).toDouble() / bitmap.width,
                    (maxY + 1).toDouble() / bitmap.height,
                )
            } else {
                listOf(0.0, 0.0, 1.0, 1.0)
            },
        )
    }
}
