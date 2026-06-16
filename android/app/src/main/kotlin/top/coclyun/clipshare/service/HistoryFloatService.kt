package top.coclyun.clipshare.service

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.WindowManager.LayoutParams
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import top.coclyun.clipshare.adapter.History
import top.coclyun.clipshare.loadHistories
import top.coclyun.clipshare.lockHistoryFloatLocation
import top.coclyun.clipshare.sendHistories
import top.coclyun.clipshare.setHistoryFloatHandleWidth
import java.io.File

class HistoryFloatService : Service(), LifecycleOwner, SavedStateRegistryOwner {
    private lateinit var localBroadcastReceiver: BroadcastReceiver
    private lateinit var windowManager: WindowManager
    private lateinit var mainParams: LayoutParams
    private lateinit var composeView: ComposeView
    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateRegistryController = SavedStateRegistryController.create(this)
    private val histories = mutableStateListOf<History>()
    private var expanded by mutableStateOf(false)
    private var loading by mutableStateOf(false)
    private var closing by mutableStateOf(false)
    private var handleVisible by mutableStateOf(true)
    private var handleWidth by mutableIntStateOf(32)
    private var minHistoryId = 0L
    private var reachedHistoryEnd = false
    private var currentLoadVisibleCount = 0
    private var lockLoc = false
    private var positionY = 0
    private var viewAdded = false
    private var hiddenForFullscreen = false
    private var hiddenForDrag = false
    private val visibleDisplayFrame = Rect()
    private val fullscreenCheckHandler = Handler(Looper.getMainLooper())
    private val fullscreenCheckRunnable = object : Runnable {
        override fun run() {
            updateFullscreenVisibility()
            fullscreenCheckHandler.postDelayed(this, FULLSCREEN_CHECK_INTERVAL_MS)
        }
    }

    private val tag = "HistoryFloatService"

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
        setupLocalBroadcastReceiver()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        mainParams = LayoutParams()
        composeView = ComposeView(this).apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindow)
            setViewTreeLifecycleOwner(this@HistoryFloatService)
            setViewTreeSavedStateRegistryOwner(this@HistoryFloatService)
            setOnApplyWindowInsetsListener { _, insets ->
                updateFullscreenVisibility()
                insets
            }
            setOnSystemUiVisibilityChangeListener {
                updateFullscreenVisibility()
            }
            setContent {
                HistoryFloatContent(
                    histories = histories,
                    expanded = expanded,
                    loading = loading,
                    closing = closing,
                    handleVisible = handleVisible,
                    handleWidth = handleWidth,
                    onExpand = { unfoldView() },
                    onCollapse = { requestHideContainer() },
                    onCollapseFinished = { hideContainer() },
                    onMoveHandle = { moveHandle(it) },
                    onLoadMore = { refreshData(true) },
                    onDragStart = { prepareForDrag() },
                    onDragEnd = { restoreAfterDrag() },
                )
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        if (intent?.action == lockHistoryFloatLocation) {
            lockLoc = intent.getBooleanExtra("lock", false)
            return START_STICKY
        }
        if (intent?.action == setHistoryFloatHandleWidth) {
            handleWidth = intent.getIntExtra("width", 32)
            return START_STICKY
        }
        handleWidth = intent?.getIntExtra("width", handleWidth) ?: handleWidth
        showFloatWindow()
        return START_STICKY
    }

    override fun onDestroy() {
        fullscreenCheckHandler.removeCallbacks(fullscreenCheckRunnable)
        if (viewAdded) {
            windowManager.removeView(composeView)
            viewAdded = false
        }
        LocalBroadcastManager.getInstance(this).unregisterReceiver(localBroadcastReceiver)
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        super.onDestroy()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        updateFullscreenVisibility()
    }

    private fun setupLocalBroadcastReceiver() {
        localBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    lockHistoryFloatLocation -> {
                        lockLoc = intent.getBooleanExtra("lock", false)
                    }

                    setHistoryFloatHandleWidth -> {
                        handleWidth = intent.getIntExtra("width", 32)
                    }

                    sendHistories -> {
                        val receivedList =
                            intent.getSerializableExtra("list") as? ArrayList<HashMap<String, Any>>
                        val more = intent.getBooleanExtra("more", false)
                        if (receivedList == null) {
                            Log.d(tag, "loadHistories receivedList is null")
                            loading = false
                            return
                        }

                        val list = receivedList.map { map ->
                            History(
                                id = map["id"] as Long,
                                content = map["content"] as String,
                                time = map["time"] as String,
                                top = map["top"] as Boolean,
                                type = map["type"] as String
                            )
                        }

                        if (!more) {
                            histories.clear()
                            minHistoryId = 0L
                            reachedHistoryEnd = false
                        }

                        if (list.isEmpty()) {
                            reachedHistoryEnd = true
                            loading = false
                            return
                        }

                        minHistoryId = list.last().id
                        if (list.size < HISTORY_PAGE_SIZE) {
                            reachedHistoryEnd = true
                        }

                        val itemsToAdd = if (more) {
                            val existingIds = histories.mapTo(mutableSetOf()) { it.id }
                            list.filter { existingIds.add(it.id) }
                        } else {
                            list.distinctBy { it.id }
                        }

                        if (itemsToAdd.isNotEmpty()) {
                            histories.addAll(itemsToAdd)
                        }
                        currentLoadVisibleCount += itemsToAdd.size
                        if (!reachedHistoryEnd && currentLoadVisibleCount < HISTORY_PAGE_SIZE) {
                            requestHistories(true)
                        } else {
                            loading = false
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(lockHistoryFloatLocation)
            addAction(setHistoryFloatHandleWidth)
            addAction(sendHistories)
        }

        LocalBroadcastManager.getInstance(this).registerReceiver(
            localBroadcastReceiver,
            filter
        )
    }

    private fun showFloatWindow() {
        if (!Settings.canDrawOverlays(this) || viewAdded) {
            return
        }

        mainParams.type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            LayoutParams.TYPE_PHONE
        }
        mainParams.format = PixelFormat.RGBA_8888
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        mainParams.flags = BASE_WINDOW_FLAGS
        mainParams.gravity = Gravity.END or Gravity.CENTER_VERTICAL
        setPos1P3()
        windowManager.addView(composeView, mainParams)
        viewAdded = true
        updateFullscreenVisibility()
        fullscreenCheckHandler.removeCallbacks(fullscreenCheckRunnable)
        fullscreenCheckHandler.post(fullscreenCheckRunnable)
    }

    private fun setPos1P3() {
        val screenHeight = resources.displayMetrics.heightPixels
        mainParams.x = 0
        mainParams.y = -(screenHeight / 3)
        positionY = mainParams.y
    }

    private fun moveHandle(dy: Float) {
        if (lockLoc || expanded || !viewAdded) {
            return
        }
        positionY += dy.toInt()
        mainParams.x = 0
        mainParams.y = positionY
        windowManager.updateViewLayout(composeView, mainParams)
    }

    private fun unfoldView() {
        if (!viewAdded || expanded) {
            return
        }
        handleVisible = false
        closing = false
        mainParams.width = LayoutParams.MATCH_PARENT
        mainParams.height = LayoutParams.MATCH_PARENT
        mainParams.x = 0
        windowManager.updateViewLayout(composeView, mainParams)
        composeView.post {
            expanded = true
            refreshData()
        }
    }

    private fun requestHideContainer() {
        if (!viewAdded || !expanded || closing) {
            return
        }
        closing = true
    }

    private fun hideContainer() {
        if (!viewAdded || !expanded) {
            return
        }
        closing = false
        expanded = false
        handleVisible = false
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        mainParams.x = 0
        mainParams.y = positionY
        windowManager.updateViewLayout(composeView, mainParams)
        composeView.post {
            handleVisible = true
        }
    }

    private fun prepareForDrag() {
        if (!viewAdded) {
            return
        }
        hiddenForDrag = true
        applyFloatVisibility()
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        mainParams.x = 0
        windowManager.updateViewLayout(composeView, mainParams)
    }

    private fun restoreAfterDrag() {
        if (!viewAdded) {
            return
        }
        if (expanded) {
            mainParams.width = LayoutParams.MATCH_PARENT
            mainParams.height = LayoutParams.MATCH_PARENT
        } else {
            mainParams.width = LayoutParams.WRAP_CONTENT
            mainParams.height = LayoutParams.WRAP_CONTENT
        }
        windowManager.updateViewLayout(composeView, mainParams)
        composeView.post {
            hiddenForDrag = false
            applyFloatVisibility()
        }
    }

    private fun refreshData(more: Boolean = false) {
        if (loading || (more && reachedHistoryEnd)) return
        currentLoadVisibleCount = 0
        loading = true
        requestHistories(more)
    }

    private fun requestHistories(more: Boolean) {
        val intent = Intent(loadHistories)
        intent.putExtra("more", more)
        intent.putExtra("minHistoryId", if (more) minHistoryId else 0L)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    private fun updateFullscreenVisibility() {
        if (!viewAdded) {
            return
        }
        val isFullscreen = isSystemFullscreen()
        if (hiddenForFullscreen == isFullscreen) {
            return
        }
        hiddenForFullscreen = isFullscreen
        applyFloatVisibility()
    }

    private fun applyFloatVisibility() {
        val expectedFlags = if (hiddenForFullscreen) {
            BASE_WINDOW_FLAGS or LayoutParams.FLAG_NOT_TOUCHABLE
        } else {
            BASE_WINDOW_FLAGS
        }
        if (viewAdded && mainParams.flags != expectedFlags) {
            mainParams.flags = expectedFlags
            windowManager.updateViewLayout(composeView, mainParams)
        }
        if (hiddenForFullscreen) {
            composeView.visibility = View.VISIBLE
            composeView.alpha = 0f
            return
        }

        composeView.alpha = 1f
        composeView.visibility = if (hiddenForDrag) View.INVISIBLE else View.VISIBLE
    }

    private fun isSystemFullscreen(): Boolean {
        composeView.getWindowVisibleDisplayFrame(visibleDisplayFrame)
        val statusBarHeight = getStatusBarHeight()
        if (statusBarHeight <= 0) {
            return false
        }

        return visibleDisplayFrame.top <= statusBarHeight / 2
    }

    private fun getStatusBarHeight(): Int {
        val resourceId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resourceId > 0) {
            resources.getDimensionPixelSize(resourceId)
        } else {
            0
        }
    }

    companion object {
        private const val BASE_WINDOW_FLAGS =
            LayoutParams.FLAG_NOT_FOCUSABLE or LayoutParams.FLAG_NOT_TOUCH_MODAL
        private const val FULLSCREEN_CHECK_INTERVAL_MS = 500L
        private const val HISTORY_PAGE_SIZE = 100
    }
}
