package com.anies1212.iris_camera

import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import androidx.camera.core.ImageProxy
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.min

internal object ImageUtil {
    fun yuv420ToRgba(image: ImageProxy): ByteArray {
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val width = image.width
        val height = image.height
        val out = ByteArray(width * height * 4)
        val yRowStride = yPlane.rowStride
        val uvRowStride = uPlane.rowStride
        val uvPixelStride = uPlane.pixelStride

        val yBuffer = yPlane.buffer.apply { rewind() }
        val uBuffer = uPlane.buffer.apply { rewind() }
        val vBuffer = vPlane.buffer.apply { rewind() }

        for (y in 0 until height) {
            for (x in 0 until width) {
                val yIndex = yRowStride * y + x
                val uvIndex = uvRowStride * (y / 2) + (x / 2) * uvPixelStride

                val yValue = (yBuffer.get(yIndex).toInt() and 0xFF)
                val uValue = (uBuffer.get(uvIndex).toInt() and 0xFF) - 128
                val vValue = (vBuffer.get(uvIndex).toInt() and 0xFF) - 128

                val r = clamp((yValue + 1.370705f * vValue).toInt())
                val g = clamp((yValue - 0.337633f * uValue - 0.698001f * vValue).toInt())
                val b = clamp((yValue + 1.732446f * uValue).toInt())

                val outIndex = (y * width + x) * 4
                out[outIndex] = b.toByte()
                out[outIndex + 1] = g.toByte()
                out[outIndex + 2] = r.toByte()
                out[outIndex + 3] = 0xFF.toByte()
            }
        }
        return out
    }

    fun rgbaToBgra(bytes: ByteArray): ByteArray {
        val swapped = ByteArray(bytes.size)
        var i = 0
        while (i < bytes.size) {
            val r = bytes[i]
            val g = bytes[i + 1]
            val b = bytes[i + 2]
            val a = bytes[i + 3]
            swapped[i] = b
            swapped[i + 1] = g
            swapped[i + 2] = r
            swapped[i + 3] = a
            i += 4
        }
        return swapped
    }

    fun imageProxyToJpeg(image: ImageProxy): ByteArray {
        val nv21 = yuv420888ToNv21(image)
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
        val stream = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, image.width, image.height), 95, stream)
        return stream.toByteArray()
    }

    private fun yuv420888ToNv21(image: ImageProxy): ByteArray {
        val yBuffer = image.planes[0].buffer.apply { rewind() }
        val uBuffer = image.planes[1].buffer.apply { rewind() }
        val vBuffer = image.planes[2].buffer.apply { rewind() }

        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()

        val nv21 = ByteArray(ySize + uSize + vSize)

        yBuffer.get(nv21, 0, ySize)

        val uvPixelStride = image.planes[1].pixelStride
        val uvRowStride = image.planes[1].rowStride
        var index = ySize
        val width = image.width
        val height = image.height
        for (row in 0 until height / 2) {
            for (col in 0 until width / 2) {
                val uIndex = row * uvRowStride + col * uvPixelStride
                val vIndex = row * image.planes[2].rowStride + col * image.planes[2].pixelStride
                nv21[index++] = vBuffer.get(vIndex)
                nv21[index++] = uBuffer.get(uIndex)
            }
        }
        return nv21
    }

    private fun clamp(value: Int): Int = min(255, max(0, value))
}
