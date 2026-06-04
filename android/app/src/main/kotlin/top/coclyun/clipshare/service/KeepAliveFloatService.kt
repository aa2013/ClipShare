package top.coclyun.clipshare.service

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.WindowManager
import android.view.WindowManager.LayoutParams
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner

class KeepAliveFloatService : Service(), LifecycleOwner, SavedStateRegistryOwner {
    private lateinit var windowManager: WindowManager
    private lateinit var params: LayoutParams
    private lateinit var composeView: ComposeView
    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateRegistryController = SavedStateRegistryController.create(this)
    private var viewAdded = false

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateRegistryController.savedStateRegistry

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        savedStateRegistryController.performAttach()
        savedStateRegistryController.performRestore(null)
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        params = LayoutParams()
        composeView = ComposeView(this).apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindow)
            setViewTreeLifecycleOwner(this@KeepAliveFloatService)
            setViewTreeSavedStateRegistryOwner(this@KeepAliveFloatService)
            setContent {
                KeepAlivePixel()
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        showFloatWindow()
        return START_STICKY
    }

    override fun onDestroy() {
        if (viewAdded) {
            windowManager.removeView(composeView)
            viewAdded = false
        }
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        super.onDestroy()
    }

    private fun showFloatWindow() {
        if (!Settings.canDrawOverlays(this) || viewAdded) {
            return
        }

        params.type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            LayoutParams.TYPE_PHONE
        }
        params.format = PixelFormat.RGBA_8888
        params.width = DEBUG_WINDOW_SIZE_PX
        params.height = DEBUG_WINDOW_SIZE_PX
        params.flags = BASE_WINDOW_FLAGS
        params.gravity = Gravity.START or Gravity.CENTER_VERTICAL
        params.x = 0
        params.y = 0
        windowManager.addView(composeView, params)
        viewAdded = true
    }

    companion object {
        private const val DEBUG_WINDOW_SIZE_PX = 1
        private const val BASE_WINDOW_FLAGS =
            LayoutParams.FLAG_NOT_FOCUSABLE or
                LayoutParams.FLAG_NOT_TOUCHABLE or
                LayoutParams.FLAG_NOT_TOUCH_MODAL
    }
}

@Composable
private fun KeepAlivePixel() {
    Box(
        modifier = Modifier
            .fillMaxSize()
//            .background(Color.Red)
    )
}
