package com.anies1212.iris_camera

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.view.View
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class IrisCameraPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var imageStreamChannel: EventChannel
    private lateinit var orientationChannel: EventChannel
    private lateinit var stateChannel: EventChannel
    private lateinit var focusExposureChannel: EventChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var cameraController: CameraController? = null
    private val imageStreamHandler = ImageStreamHandler()
    private var orientationStreamHandler: OrientationStreamHandler? = null
    private val stateStreamHandler = StateStreamHandler()
    private val focusExposureStreamHandler = FocusExposureStreamHandler()
    private val permissionWaiters = mutableListOf<CompletableDeferred<Boolean>>()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val permissionListener =
        PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode == REQUEST_CODE_CAMERA) {
                val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                permissionWaiters.forEach { it.complete(granted) }
                permissionWaiters.clear()
                true
            } else {
                false
            }
        }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "iris_camera")
        channel.setMethodCallHandler(this)

        imageStreamChannel = EventChannel(binding.binaryMessenger, "iris_camera/imageStream")
        imageStreamChannel.setStreamHandler(imageStreamHandler)

        orientationStreamHandler =
            OrientationStreamHandler(binding.applicationContext.applicationContext)
        orientationChannel = EventChannel(binding.binaryMessenger, "iris_camera/orientation")
        orientationChannel.setStreamHandler(orientationStreamHandler)

        stateChannel = EventChannel(binding.binaryMessenger, "iris_camera/state")
        stateChannel.setStreamHandler(stateStreamHandler)

        focusExposureChannel = EventChannel(binding.binaryMessenger, "iris_camera/focusExposureState")
        focusExposureChannel.setStreamHandler(focusExposureStreamHandler)

        val factory = object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
            override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                val previewView = PreviewView(context)
                previewView.scaleType = PreviewView.ScaleType.FILL_CENTER
                cameraController?.attachPreviewView(previewView)
                return object : PlatformView {
                    override fun getView(): View = previewView
                    override fun dispose() {}
                }
            }
        }
        binding.platformViewRegistry.registerViewFactory("iris_camera/preview", factory)

        applicationContext?.let {
            cameraController = CameraController(
                it,
                lifecycleOwnerProvider = { activity as? LifecycleOwner },
                imageStreamHandler = imageStreamHandler,
                stateStreamHandler = stateStreamHandler,
                focusExposureStreamHandler = focusExposureStreamHandler,
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
            "listAvailableLenses" -> launchWithPermission(result) {
                val includeFront = call.argument<Boolean>("includeFront") ?: true
                val lenses = cameraController?.listAvailableLenses(includeFront) ?: emptyList()
                result.success(lenses.map { it.toMap() })
            }

            "switchLens" -> launchWithPermission(result) {
                val category = call.argument<String>("category")
                    ?: return@launchWithPermission result.error(
                        "invalid_arguments",
                        "Expected category",
                        null,
                    )
                val descriptor = cameraController?.switchLens(category)
                result.success(descriptor?.toMap())
            }

            "takePhoto" -> launchWithPermission(result) {
                val flashMode = call.argument<String>("flashMode")
                val exposureMicros = call.argument<Number>("exposureDurationMicros")?.toLong()
                val iso = call.argument<Number>("iso")?.toDouble()
                val bytes = cameraController?.capturePhoto(flashMode, exposureMicros, iso)
                if (bytes == null) {
                    result.error("photo_capture_failed", "Capture failed", null)
                } else {
                    result.success(bytes)
                }
            }

            "startVideoRecording" -> {
                val enableAudio = call.argument<Boolean>("enableAudio") ?: true
                launchWithPermission(result, requireAudio = enableAudio) {
                    val filePath = call.argument<String>("filePath")
                    val path = cameraController?.startVideoRecording(
                        filePath = filePath,
                        enableAudio = enableAudio,
                    )
                    result.success(path)
                }
            }

            "stopVideoRecording" -> launchWithPermission(result) {
                val path = cameraController?.stopVideoRecording()
                result.success(path)
            }

            "setFocus" -> launchWithPermission(result) {
                val x = call.argument<Double>("x")
                val y = call.argument<Double>("y")
                val point = if (x != null && y != null) android.graphics.PointF(x.toFloat(), y.toFloat()) else null
                cameraController?.setFocus(point, call.argument<Double>("lensPosition"))
                result.success(null)
            }

            "setZoom" -> launchWithPermission(result) {
                val zoom = call.argument<Double>("zoomFactor") ?: 1.0
                cameraController?.setZoom(zoom)
                result.success(null)
            }

            "setWhiteBalance" -> launchWithPermission(result) {
                val temperature = call.argument<Double>("temperature")
                val tint = call.argument<Double>("tint")
                cameraController?.setWhiteBalance(temperature, tint)
                result.success(null)
            }

            "setExposureMode" -> launchWithPermission(result) {
                val modeRaw = call.argument<String>("mode")
                val mode = if (modeRaw == "locked") ExposureModeNative.LOCKED else ExposureModeNative.AUTO
                cameraController?.setExposureMode(mode)
                result.success(null)
            }

            "getExposureMode" -> launchWithPermission(result) {
                val mode = cameraController?.getExposureMode() ?: ExposureModeNative.AUTO
                result.success(if (mode == ExposureModeNative.LOCKED) "locked" else "auto")
            }

            "setExposurePoint" -> launchWithPermission(result) {
                val x = call.argument<Double>("x") ?: 0.5
                val y = call.argument<Double>("y") ?: 0.5
                cameraController?.setExposurePoint(android.graphics.PointF(x.toFloat(), y.toFloat()))
                result.success(null)
            }

            "getMinExposureOffset" -> launchWithPermission(result) {
                result.success(cameraController?.getMinExposureOffset() ?: 0.0)
            }

            "getMaxExposureOffset" -> launchWithPermission(result) {
                result.success(cameraController?.getMaxExposureOffset() ?: 0.0)
            }

            "setExposureOffset" -> launchWithPermission(result) {
                val offset = call.argument<Double>("offset") ?: 0.0
                result.success(cameraController?.setExposureOffset(offset) ?: 0.0)
            }

            "getExposureOffset" -> launchWithPermission(result) {
                result.success(cameraController?.getExposureOffset() ?: 0.0)
            }

            "getExposureOffsetStepSize" -> launchWithPermission(result) {
                result.success(cameraController?.getExposureOffsetStepSize() ?: 0.1)
            }

            "setResolutionPreset" -> launchWithPermission(result) {
                val presetName = call.argument<String>("preset")
                val preset = ResolutionPresetNative.fromString(presetName)
                cameraController?.setResolutionPreset(preset)
                result.success(null)
            }

            "startImageStream" -> launchWithPermission(result) {
                cameraController?.startImageStream()
                result.success(null)
            }

            "stopImageStream" -> launchWithPermission(result) {
                cameraController?.stopImageStream()
                result.success(null)
            }

            "setTorch" -> launchWithPermission(result) {
                val enabled = call.argument<Boolean>("enabled") ?: false
                cameraController?.setTorch(enabled)
                result.success(null)
            }

            "setFocusMode" -> launchWithPermission(result) {
                val modeRaw = call.argument<String>("mode")
                val mode = if (modeRaw == "locked") FocusModeNative.LOCKED else FocusModeNative.AUTO
                cameraController?.setFocusMode(mode)
                result.success(null)
            }

            "getFocusMode" -> launchWithPermission(result) {
                val mode = cameraController?.getFocusMode() ?: FocusModeNative.AUTO
                result.success(if (mode == FocusModeNative.LOCKED) "locked" else "auto")
            }

            "setFrameRateRange" -> launchWithPermission(result) {
                val minFps = call.argument<Double>("minFps")
                val maxFps = call.argument<Double>("maxFps")
                cameraController?.setFrameRateRange(minFps, maxFps)
                result.success(null)
            }

            "initialize" -> launchWithPermission(result) {
                cameraController?.initialize()
                result.success(null)
            }

            "pauseSession" -> launchWithPermission(result) {
                cameraController?.pauseSession()
                result.success(null)
            }

            "resumeSession" -> launchWithPermission(result) {
                cameraController?.resumeSession()
                result.success(null)
            }

            "disposeSession" -> launchWithPermission(result) {
                cameraController?.disposeSession()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

  private fun launchWithPermission(
    result: MethodChannel.Result,
    requireAudio: Boolean = false,
    block: suspend () -> Unit,
  ) {
    scope.launch {
      val granted = ensurePermission(requireAudio)
      if (!granted) {
        result.error(
          "camera_permission_denied",
          "Camera permission not granted.",
          null,
                )
                return@launch
            }
            try {
                block()
            } catch (error: Throwable) {
                stateStreamHandler.emit(
                    CameraLifecycleStateNative.ERROR,
                    FlutterErrorWrapper("camera_error", error.message),
                )
                result.error(
                    "camera_error",
                    error.message ?: "Operation failed",
                    null,
                )
            }
        }
    }

  private suspend fun ensurePermission(requireAudio: Boolean): Boolean {
    val ctx = activity ?: applicationContext ?: return false
    val cameraGranted =
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    val audioGranted =
        !requireAudio || ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    if (cameraGranted && audioGranted) return true
    if (permissionWaiters.isNotEmpty()) {
      return permissionWaiters.last().await()
    }
    val currentActivity = activity
    if (currentActivity == null) return false
    val deferred = CompletableDeferred<Boolean>()
    permissionWaiters.add(deferred)
    val permissions = mutableListOf(Manifest.permission.CAMERA)
    if (requireAudio) {
      permissions.add(Manifest.permission.RECORD_AUDIO)
    }
    ActivityCompat.requestPermissions(currentActivity, permissions.toTypedArray(), REQUEST_CODE_CAMERA)
    return deferred.await()
  }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        orientationStreamHandler?.onCancel(null)
        orientationChannel.setStreamHandler(null)
        stateChannel.setStreamHandler(null)
        focusExposureChannel.setStreamHandler(null)
        scope.launch { cameraController?.disposeSession() }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(permissionListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        activityBinding?.removeRequestPermissionsResultListener(permissionListener)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
        activityBinding?.removeRequestPermissionsResultListener(permissionListener)
        activityBinding = null
    }

    companion object {
        private const val REQUEST_CODE_CAMERA = 9798
    }
}
