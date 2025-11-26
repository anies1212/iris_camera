package com.anies1212.iris_camera

import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.util.Log
import android.util.Range
import android.util.Size
import androidx.camera.camera2.interop.Camera2CameraControl
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.CaptureRequestOptions
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.MeteringPointFactory
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.concurrent.futures.await
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.math.roundToInt
import kotlinx.coroutines.suspendCancellableCoroutine

internal class CameraController(
    private val context: Context,
    private val lifecycleOwnerProvider: () -> LifecycleOwner?,
    private val imageStreamHandler: ImageStreamHandler,
    private val stateStreamHandler: StateStreamHandler,
    private val focusExposureStreamHandler: FocusExposureStreamHandler,
) {
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var previewView: PreviewView? = null
    private var selectedLensId: String? = null
    private var selectedDescriptor: CameraLensDescriptorNative? = null
    private var resolutionPreset: ResolutionPresetNative = ResolutionPresetNative.high
    private var frameRateRange: FrameRateRange = FrameRateRange(null, null)
    private var currentFocusMode: FocusModeNative = FocusModeNative.AUTO
    private var currentExposureMode: ExposureModeNative = ExposureModeNative.AUTO
    private var isInitialized = false
    private var isPaused = false
    private var isStreaming = false

    suspend fun ensureInitialized() {
        if (cameraProvider == null) {
            cameraProvider = ProcessCameraProvider.getInstance(context).await()
        }
    }

    fun attachPreviewView(view: PreviewView) {
        previewView = view
        preview?.setSurfaceProvider(view.surfaceProvider)
    }

    suspend fun listAvailableLenses(includeFront: Boolean): List<CameraLensDescriptorNative> {
        ensureInitialized()
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val result = mutableListOf<CameraLensDescriptorNative>()
        try {
            manager.cameraIdList.forEach { cameraId ->
                val characteristics = manager.getCameraCharacteristics(cameraId)
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                val position = when (facing) {
                    CameraCharacteristics.LENS_FACING_FRONT -> CameraLensPositionNative.FRONT
                    CameraCharacteristics.LENS_FACING_EXTERNAL -> CameraLensPositionNative.EXTERNAL
                    else -> CameraLensPositionNative.BACK
                }
                if (!includeFront && position == CameraLensPositionNative.FRONT) return@forEach
                val (category, fov) = LensCategorizer.categoryFor(characteristics)
                val focalLength = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.minOrNull()
                val afModes = characteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES) ?: intArrayOf()
                val supportsFocus = afModes.any { it == CaptureRequest.CONTROL_AF_MODE_AUTO || it == CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE }
                val descriptor = CameraLensDescriptorNative(
                    id = cameraId,
                    name = "Camera $cameraId",
                    position = position,
                    category = category,
                    supportsFocus = supportsFocus,
                    focalLength = focalLength?.toDouble(),
                    fieldOfView = fov,
                )
                result.add(descriptor)
            }
        } catch (error: CameraAccessException) {
            Log.e("IrisCamera", "Failed to list cameras", error)
            throw error
        }
        if (selectedLensId == null && result.isNotEmpty()) {
            val defaultLens = result.firstOrNull { it.position == CameraLensPositionNative.BACK } ?: result.first()
            selectedLensId = defaultLens.id
            selectedDescriptor = defaultLens
        }
        return result
    }

    suspend fun switchLens(categoryName: String): CameraLensDescriptorNative {
        val lenses = listAvailableLenses(includeFront = true)
        val target = lenses.firstOrNull { it.category.value == categoryName }
            ?: lenses.firstOrNull { it.position == CameraLensPositionNative.BACK }
            ?: lenses.first()
        selectedLensId = target.id
        selectedDescriptor = target
        bindUseCases()
        stateStreamHandler.emit(CameraLifecycleStateNative.RUNNING)
        return target
    }

    suspend fun initialize() {
        ensureInitialized()
        if (selectedLensId == null) {
            listAvailableLenses(includeFront = true)
        }
        bindUseCases()
        isInitialized = true
        isPaused = false
        stateStreamHandler.emit(CameraLifecycleStateNative.INITIALIZED)
        stateStreamHandler.emit(CameraLifecycleStateNative.RUNNING)
    }

    suspend fun pauseSession() {
        if (!isInitialized || isPaused) return
        cameraProvider?.unbindAll()
        isPaused = true
        stateStreamHandler.emit(CameraLifecycleStateNative.PAUSED)
    }

    suspend fun resumeSession() {
        if (!isInitialized) return
        bindUseCases()
        isPaused = false
        stateStreamHandler.emit(CameraLifecycleStateNative.RUNNING)
    }

    suspend fun disposeSession() {
        cameraProvider?.unbindAll()
        camera = null
        preview = null
        imageCapture = null
        imageAnalysis = null
        isInitialized = false
        isPaused = false
        isStreaming = false
        stateStreamHandler.emit(CameraLifecycleStateNative.DISPOSED)
    }

    suspend fun capturePhoto(
        flashMode: String?,
        exposureDurationMicros: Long?,
        iso: Double?,
    ): ByteArray {
        val capture = imageCapture ?: throw IllegalStateException("ImageCapture is not ready")
        if (flashMode != null) {
            capture.flashMode = when (flashMode) {
                "on" -> ImageCapture.FLASH_MODE_ON
                "off" -> ImageCapture.FLASH_MODE_OFF
                else -> ImageCapture.FLASH_MODE_AUTO
            }
        }
        if (exposureDurationMicros != null || iso != null) {
            val camera2 = camera?.cameraControl?.let { Camera2CameraControl.from(it) }
            val options = CaptureRequestOptions.Builder()
            exposureDurationMicros?.let {
                options.setCaptureRequestOption(CaptureRequest.SENSOR_EXPOSURE_TIME, it * 1000)
            }
            iso?.let { options.setCaptureRequestOption(CaptureRequest.SENSOR_SENSITIVITY, it.toInt()) }
            camera2?.setCaptureRequestOptions(options.build())
        }
        return suspendCancellableTakePicture(capture)
    }

    suspend fun setFocus(point: android.graphics.PointF?, lensPosition: Double?) {
        val controller = camera?.cameraControl ?: return
        val view = previewView ?: return
        val factory: MeteringPointFactory = view.meteringPointFactory
        val normalizedX = point?.x ?: 0.5f
        val normalizedY = point?.y ?: 0.5f
        val meteringPoint = factory.createPoint(
            normalizedX * view.width,
            normalizedY * view.height,
        )
        focusExposureStreamHandler.emit(FocusExposureStateNative.FOCUSING)
        val builder = FocusMeteringAction.Builder(meteringPoint, FocusMeteringAction.FLAG_AF or FocusMeteringAction.FLAG_AE)
        if (currentFocusMode == FocusModeNative.LOCKED) {
            builder.disableAutoCancel()
        }
        val action = builder.build()
        val future = controller.startFocusAndMetering(action)
        future.addListener({
            try {
                val result = future.get()
                if (result?.isFocusSuccessful == true) {
                    focusExposureStreamHandler.emit(FocusExposureStateNative.COMBINED_LOCKED)
                } else {
                    focusExposureStreamHandler.emit(FocusExposureStateNative.FOCUS_FAILED)
                }
            } catch (t: Throwable) {
                focusExposureStreamHandler.emit(FocusExposureStateNative.FOCUS_FAILED)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun setZoom(zoom: Double) {
        camera?.cameraControl?.setZoomRatio(zoom.toFloat())
    }

    fun setTorch(enabled: Boolean) {
        camera?.cameraControl?.enableTorch(enabled)
    }

    suspend fun setResolutionPreset(preset: ResolutionPresetNative) {
        resolutionPreset = preset
        bindUseCases()
    }

    suspend fun setFrameRateRange(minFps: Double?, maxFps: Double?) {
        frameRateRange = FrameRateRange(minFps, maxFps)
        bindUseCases()
    }

    fun setFocusMode(mode: FocusModeNative) {
        currentFocusMode = mode
        val camera2 = camera?.cameraControl?.let { Camera2CameraControl.from(it) }
        val options = CaptureRequestOptions.Builder()
        val afMode = if (mode == FocusModeNative.LOCKED) {
            CaptureRequest.CONTROL_AF_MODE_AUTO
        } else {
            CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
        }
        options.setCaptureRequestOption(CaptureRequest.CONTROL_AF_MODE, afMode)
        camera2?.setCaptureRequestOptions(options.build())
    }

    fun getFocusMode(): FocusModeNative = currentFocusMode

    fun setExposureMode(mode: ExposureModeNative) {
        currentExposureMode = mode
        val camera2 = camera?.cameraControl?.let { Camera2CameraControl.from(it) }
        val options = CaptureRequestOptions.Builder()
        options.setCaptureRequestOption(CaptureRequest.CONTROL_AE_LOCK, mode == ExposureModeNative.LOCKED)
        camera2?.setCaptureRequestOptions(options.build())
        focusExposureStreamHandler.emit(
            if (mode == ExposureModeNative.LOCKED) FocusExposureStateNative.EXPOSURE_LOCKED else FocusExposureStateNative.EXPOSURE_SEARCHING,
        )
    }

    fun getExposureMode(): ExposureModeNative = currentExposureMode

    fun setExposurePoint(point: android.graphics.PointF) {
        val controller = camera?.cameraControl ?: return
        val view = previewView ?: return
        val meteringPoint = view.meteringPointFactory.createPoint(
            point.x * view.width,
            point.y * view.height,
            FocusMeteringAction.FLAG_AE,
        )
        val action = FocusMeteringAction.Builder(meteringPoint, FocusMeteringAction.FLAG_AE).build()
        controller.startFocusAndMetering(action)
    }

    fun setWhiteBalance(temperature: Double?, tint: Double?) {
        val camera2 = camera?.cameraControl?.let { Camera2CameraControl.from(it) } ?: return
        val options = CaptureRequestOptions.Builder()
        if (temperature == null && tint == null) {
            options.setCaptureRequestOption(CaptureRequest.CONTROL_AWB_LOCK, false)
            options.setCaptureRequestOption(CaptureRequest.CONTROL_AWB_MODE, CaptureRequest.CONTROL_AWB_MODE_AUTO)
        } else {
            options.setCaptureRequestOption(CaptureRequest.CONTROL_AWB_LOCK, true)
            options.setCaptureRequestOption(CaptureRequest.CONTROL_AWB_MODE, CaptureRequest.CONTROL_AWB_MODE_AUTO)
        }
        camera2.setCaptureRequestOptions(options.build())
    }

    fun getExposureState(): androidx.camera.core.ExposureState? = camera?.cameraInfo?.exposureState

    fun getMinExposureOffset(): Double = exposureOffsetRange().lower

    fun getMaxExposureOffset(): Double = exposureOffsetRange().upper

    fun setExposureOffset(offset: Double): Double {
        val exposureState = camera?.cameraInfo?.exposureState ?: return 0.0
        val step = exposureState.exposureCompensationStep.toDouble()
        val index = (offset / step).roundToInt().coerceIn(
            exposureState.exposureCompensationRange.lower,
            exposureState.exposureCompensationRange.upper,
        )
        camera?.cameraControl?.setExposureCompensationIndex(index)
        return index * step
    }

    fun getExposureOffset(): Double {
        val exposureState = camera?.cameraInfo?.exposureState ?: return 0.0
        val step = exposureState.exposureCompensationStep.toDouble()
        return exposureState.exposureCompensationIndex * step
    }

    fun getExposureOffsetStepSize(): Double {
        val exposureState = camera?.cameraInfo?.exposureState ?: return 0.1
        return exposureState.exposureCompensationStep.toDouble()
    }

    suspend fun startImageStream() {
        if (isStreaming) return
        isStreaming = true
        bindUseCases()
    }

    suspend fun stopImageStream() {
        if (!isStreaming) return
        isStreaming = false
        bindUseCases()
    }

    private fun exposureOffsetRange(): Range<Double> {
        val exposureState = camera?.cameraInfo?.exposureState
        if (exposureState != null) {
            val step = exposureState.exposureCompensationStep.toDouble()
            return Range(
                exposureState.exposureCompensationRange.lower * step,
                exposureState.exposureCompensationRange.upper * step,
            )
        }
        return Range(0.0, 0.0)
    }

    private fun targetSizeForPreset(): Size? = when (resolutionPreset) {
        ResolutionPresetNative.low -> Size(640, 480)
        ResolutionPresetNative.medium -> Size(1280, 720)
        ResolutionPresetNative.high -> Size(1920, 1080)
        ResolutionPresetNative.veryHigh -> Size(2560, 1440)
        ResolutionPresetNative.ultraHigh -> Size(3840, 2160)
        ResolutionPresetNative.max -> null
    }

    private suspend fun bindUseCases() {
        ensureInitialized()
        val provider = cameraProvider ?: return
        val lensId = selectedLensId ?: listAvailableLenses(includeFront = true).firstOrNull()?.id
        val lifecycleOwner = lifecycleOwnerProvider.invoke()
            ?: throw IllegalStateException("No lifecycle owner available for camera binding.")
        val selector = if (lensId != null) {
            CameraSelector.Builder()
                .addCameraFilter { cameras -> cameras.filter { it.cameraInfo.cameraId == lensId } }
                .build()
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }

        val targetSize = targetSizeForPreset()

        val previewBuilder = Preview.Builder()
        val captureBuilder = ImageCapture.Builder()
        val analysisBuilder = ImageAnalysis.Builder()

        if (targetSize != null) {
            previewBuilder.setTargetResolution(targetSize)
            captureBuilder.setTargetResolution(targetSize)
            analysisBuilder.setTargetResolution(targetSize)
        }

        val previewInterop = Camera2Interop.Extender(previewBuilder)
        val captureInterop = Camera2Interop.Extender(captureBuilder)
        val analysisInterop = Camera2Interop.Extender(analysisBuilder)
        if (frameRateRange.minFps != null || frameRateRange.maxFps != null) {
            val minFpsValue = (frameRateRange.minFps ?: frameRateRange.maxFps ?: 15.0).roundToInt()
            val maxFpsValue = (frameRateRange.maxFps ?: frameRateRange.minFps ?: 30.0).roundToInt()
            val range = Range(minFpsValue.coerceAtMost(maxFpsValue), maxFpsValue.coerceAtLeast(minFpsValue))
            previewInterop.setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, range)
            captureInterop.setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, range)
            analysisInterop.setCaptureRequestOption(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, range)
        }

        val previewUseCase = previewBuilder.build()
        val captureUseCase = captureBuilder
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .setFlashMode(ImageCapture.FLASH_MODE_AUTO)
            .build()

        val analysisUseCase = if (isStreaming) {
            analysisBuilder
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build()
        } else {
            null
        }

        analysisUseCase?.setAnalyzer(executor) { image ->
            if (!isStreaming || !imageStreamHandler.hasListener()) {
                image.close()
                return@setAnalyzer
            }
            val frame = imageProxyToFrame(image)
            if (frame != null) {
                imageStreamHandler.emit(frame)
            }
            image.close()
        }

        provider.unbindAll()
        preview = previewUseCase
        imageCapture = captureUseCase
        imageAnalysis = analysisUseCase

        camera = provider.bindToLifecycle(
            lifecycleOwner,
            selector,
            *listOfNotNull(previewUseCase, captureUseCase, analysisUseCase).toTypedArray(),
        )

        previewView?.let { previewUseCase.setSurfaceProvider(it.surfaceProvider) }
        camera?.cameraInfo?.cameraState?.observe(lifecycleOwner) { state ->
            if (state.type == CameraState.Type.CLOSED) {
                stateStreamHandler.emit(CameraLifecycleStateNative.PAUSED)
            }
        }
        applyCurrentModes()
    }

    private fun applyCurrentModes() {
        setFocusMode(currentFocusMode)
        setExposureMode(currentExposureMode)
    }

    private fun imageProxyToFrame(image: ImageProxy): Map<String, Any>? {
        return when (image.format) {
            ImageFormat.YUV_420_888 -> {
                val rgba = ImageUtil.yuv420ToRgba(image)
                mapOf(
                    "bytes" to rgba,
                    "width" to image.width,
                    "height" to image.height,
                    "bytesPerRow" to image.width * 4,
                    "format" to "bgra8888",
                )
            }
            ImageFormat.RGBA_8888 -> {
                val buffer = image.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                val converted = ImageUtil.rgbaToBgra(bytes)
                mapOf(
                    "bytes" to converted,
                    "width" to image.width,
                    "height" to image.height,
                    "bytesPerRow" to image.planes[0].rowStride,
                    "format" to "bgra8888",
                )
            }
            else -> null
        }
    }

    private suspend fun suspendCancellableTakePicture(capture: ImageCapture): ByteArray =
        kotlinx.coroutines.suspendCancellableCoroutine { cont ->
            capture.takePicture(executor, object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    try {
                        val jpeg = ImageUtil.imageProxyToJpeg(image)
                        cont.resume(jpeg, null)
                    } catch (t: Throwable) {
                        cont.resumeWithException(t)
                    } finally {
                        image.close()
                    }
                }

                override fun onError(exception: ImageCaptureException) {
                    cont.resumeWithException(exception)
                }
            })
        }
}
