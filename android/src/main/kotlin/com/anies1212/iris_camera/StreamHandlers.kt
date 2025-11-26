package com.anies1212.iris_camera

import android.content.Context
import android.view.OrientationEventListener
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.atomic.AtomicBoolean

internal class ImageStreamHandler : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(frame: Map<String, Any>) {
        sink?.success(frame)
    }

    fun hasListener(): Boolean = sink != null
}

internal class OrientationStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private var listener: OrientationEventListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        if (listener == null) {
            listener = object : OrientationEventListener(context) {
                override fun onOrientationChanged(orientation: Int) {
                    val deviceOrientation = when {
                        orientation in 45..134 -> "landscapeRight"
                        orientation in 135..224 -> "portraitDown"
                        orientation in 225..314 -> "landscapeLeft"
                        orientation in 315..360 || orientation in 0..44 -> "portraitUp"
                        else -> "unknown"
                    }
                    val videoOrientation = when (deviceOrientation) {
                        "portraitUp" -> "portrait"
                        "portraitDown" -> "portraitUpsideDown"
                        "landscapeLeft" -> "landscapeLeft"
                        "landscapeRight" -> "landscapeRight"
                        else -> "unknown"
                    }
                    sink?.success(
                        mapOf(
                            "deviceOrientation" to deviceOrientation,
                            "videoOrientation" to videoOrientation,
                        ),
                    )
                }
            }
        }
        listener?.enable()
    }

    override fun onCancel(arguments: Any?) {
        listener?.disable()
        sink = null
    }
}

internal class StateStreamHandler : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(state: CameraLifecycleStateNative, error: FlutterErrorWrapper? = null) {
        val payload = mutableMapOf<String, Any?>("state" to state.value)
        if (error != null) {
            payload["errorCode"] = error.code
            payload["errorMessage"] = error.message
        }
        sink?.success(payload)
    }
}

internal class FocusExposureStreamHandler : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private val isEmitting = AtomicBoolean(false)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(state: FocusExposureStateNative) {
        if (isEmitting.compareAndSet(false, true)) {
            sink?.success(mapOf("state" to state.value))
            isEmitting.set(false)
        } else {
            sink?.success(mapOf("state" to state.value))
        }
    }
}
