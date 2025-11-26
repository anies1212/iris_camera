package com.anies1212.iris_camera

import android.hardware.camera2.CameraCharacteristics
import kotlin.math.atan

internal enum class CameraLensPositionNative(val value: String) {
    FRONT("front"),
    BACK("back"),
    EXTERNAL("external"),
    UNSPECIFIED("unspecified");
}

internal enum class CameraLensCategoryNative(val value: String) {
    WIDE("wide"),
    ULTRA_WIDE("ultraWide"),
    TELEPHOTO("telephoto"),
    TRUE_DEPTH("trueDepth"),
    DUAL("dual"),
    TRIPLE("triple"),
    CONTINUITY("continuity"),
    EXTERNAL("external"),
    UNKNOWN("unknown");
}

internal data class CameraLensDescriptorNative(
    val id: String,
    val name: String,
    val position: CameraLensPositionNative,
    val category: CameraLensCategoryNative,
    val supportsFocus: Boolean,
    val focalLength: Double?,
    val fieldOfView: Double?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "position" to position.value,
        "category" to category.value,
        "supportsFocus" to supportsFocus,
        "focalLength" to focalLength,
        "fieldOfView" to fieldOfView,
    )
}

internal enum class ResolutionPresetNative {
    low, medium, high, veryHigh, ultraHigh, max;

    companion object {
        fun fromString(value: String?): ResolutionPresetNative =
            entries.firstOrNull { it.name == value } ?: high
    }
}

internal enum class FocusExposureStateNative(val value: String) {
    FOCUSING("focusing"),
    FOCUS_LOCKED("focusLocked"),
    FOCUS_FAILED("focusFailed"),
    EXPOSURE_SEARCHING("exposureSearching"),
    EXPOSURE_LOCKED("exposureLocked"),
    EXPOSURE_FAILED("exposureFailed"),
    COMBINED_LOCKED("combinedLocked"),
    UNKNOWN("unknown");
}

internal enum class CameraLifecycleStateNative(val value: String) {
    INITIALIZED("initialized"),
    RUNNING("running"),
    PAUSED("paused"),
    DISPOSED("disposed"),
    ERROR("error");
}

internal enum class FocusModeNative { AUTO, LOCKED }

internal enum class ExposureModeNative { AUTO, LOCKED }

internal data class FrameRateRange(
    val minFps: Double?,
    val maxFps: Double?,
)

internal object LensCategorizer {
    fun categoryFor(characteristics: CameraCharacteristics): Pair<CameraLensCategoryNative, Double?> {
        val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        val sensorSize = characteristics.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
        if (focalLengths == null || focalLengths.isEmpty() || sensorSize == null) {
            return CameraLensCategoryNative.UNKNOWN to null
        }
        val focal = focalLengths.minOrNull() ?: return CameraLensCategoryNative.UNKNOWN to null
        val horizFov = 2.0 * Math.toDegrees(atan((sensorSize.width / (2.0 * focal)).toDouble()))
        val category = when {
            horizFov > 75 -> CameraLensCategoryNative.ULTRA_WIDE
            horizFov < 40 -> CameraLensCategoryNative.TELEPHOTO
            else -> CameraLensCategoryNative.WIDE
        }
        return category to horizFov
    }
}
