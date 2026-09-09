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
import top.coclyun.clipshare.defaultHistoryFloatHandleColor
import top.coclyun.clipshare.loadHistories
import top.coclyun.clipshare.lockHistoryFloatLocation
import top.coclyun.clipshare.setHistoryFloatHandleApplyAlphaToWholeHandle
import top.coclyun.clipshare.sendHistories
import top.coclyun.clipshare.setHistoryFloatHandleColor
import top.coclyun.clipshare.setHistoryFloatThemeMode
import top.coclyun.clipshare.setHistoryFloatHandleWidth
import java.io.File

data class HistoryFloatStrings(
    val title: String = "",
    val countTemplate: String = "{count}",
    val imageUnavailable: String = "",
    val textType: String = "",
    val imageType: String = "",
    val fileType: String = "",
) {
    fun formatCount(count: Int): String {
        return countTemplate.replace("{count}", count.toString())
    }

    fun formatType(type: String): String {
        return when (type.lowercase()) {
            "text" -> textType
            "image" -> imageType
            "file" -> fileType
            else -> type
        }
    }
}

/**
 * 历史悬浮窗主题模式，字符串取值与 Flutter ThemeMode.name 保持一致。
 */
private enum class HistoryFloatThemeMode {
    SYSTEM,
    DARK,
    LIGHT;

    /**
     * 根据当前 Android 配置解析悬浮窗是否应使用暗色配色。
     */
    fun isDark(context: Context): Boolean {
        return when (this) {
            SYSTEM -> {
                val nightMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                nightMode == Configuration.UI_MODE_NIGHT_YES
            }

            DARK -> true
            LIGHT -> false
        }
    }

    companion object {
        /**
         * 解析 Flutter 下发的主题字符串，未知值按跟随系统处理。
         */
        fun from(value: String?): HistoryFloatThemeMode {
            return when (value?.lowercase()) {
                "dark" -> DARK
                "light" -> LIGHT
                else -> SYSTEM
            }
        }
    }
}

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
    private var handleColor by mutableIntStateOf(defaultHistoryFloatHandleColor)
    private var applyAlphaToWholeHandle by mutableStateOf(false)
    private var darkTheme by mutableStateOf(false)
    private var floatStrings by mutableStateOf(HistoryFloatStrings())
    private var themeMode = HistoryFloatThemeMode.SYSTEM
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
    private var lastStateLog: String? = null

    private val tag = "HistoryFloatService"

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateRegistryController.savedStateRegistry

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(tag, "onCreate")
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
            addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) {
                    Log.d(this@HistoryFloatService.tag, "onViewAttachedToWindow")
                    logState("viewAttached", true)
                }

                override fun onViewDetachedFromWindow(v: View) {
                    Log.w(this@HistoryFloatService.tag, "onViewDetachedFromWindow")
                    logState("viewDetached", true)
                }
            })
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
                    strings = floatStrings,
                    expanded = expanded,
                    loading = loading,
                    closing = closing,
                    handleVisible = handleVisible,
                    handleWidth = handleWidth,
                    handleColor = handleColor,
                    applyAlphaToWholeHandle = applyAlphaToWholeHandle,
                    darkTheme = darkTheme,
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
        logState("onCreate completed", true)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(
            tag,
            "onStartCommand action=${intent?.action}, flags=$flags, startId=$startId, " +
                "viewAdded=$viewAdded, attached=${if (::composeView.isInitialized) composeView.isAttachedToWindow else false}"
        )
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        updateFloatTexts(intent)
        if (intent?.action == lockHistoryFloatLocation) {
            lockLoc = intent.getBooleanExtra("lock", false)
            logState("lock location updated", true)
            return START_STICKY
        }
        if (intent?.action == setHistoryFloatHandleWidth) {
            handleWidth = intent.getIntExtra("width", 32)
            logState("handle width updated", true)
            return START_STICKY
        }
        if (intent?.action == setHistoryFloatHandleColor) {
            handleColor = intent.getIntExtra("color", handleColor)
            logState("handle color updated", true)
            return START_STICKY
        }
        if (intent?.action == setHistoryFloatHandleApplyAlphaToWholeHandle) {
            applyAlphaToWholeHandle = intent.getBooleanExtra(
                EXTRA_APPLY_ALPHA_TO_WHOLE_HANDLE,
                applyAlphaToWholeHandle
            )
            logState("handle alpha mode updated", true)
            return START_STICKY
        }
        if (intent?.action == setHistoryFloatThemeMode) {
            updateThemeMode(intent)
            logState("theme mode updated", true)
            return START_STICKY
        }
        updateThemeMode(intent)
        handleWidth = intent?.getIntExtra("width", handleWidth) ?: handleWidth
        handleColor = intent?.getIntExtra("color", handleColor) ?: handleColor
        applyAlphaToWholeHandle = intent?.getBooleanExtra(
            EXTRA_APPLY_ALPHA_TO_WHOLE_HANDLE,
            applyAlphaToWholeHandle
        ) ?: applyAlphaToWholeHandle
        showFloatWindow()
        logState("onStartCommand completed", true)
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(tag, "onDestroy")
        fullscreenCheckHandler.removeCallbacks(fullscreenCheckRunnable)
        if (viewAdded) {
            logState("removeView before onDestroy", true)
            try {
                windowManager.removeView(composeView)
                viewAdded = false
                logState("removeView completed onDestroy", true)
            } catch (e: Exception) {
                Log.e(tag, "removeView failed onDestroy: ${e::class.java.name}: ${e.message}", e)
                throw e
            }
        } else {
            logState("onDestroy without view", true)
        }
        LocalBroadcastManager.getInstance(this).unregisterReceiver(localBroadcastReceiver)
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        super.onDestroy()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        Log.d(
            tag,
            "onConfigurationChanged orientation=${newConfig.orientation}, " +
                "uiMode=${newConfig.uiMode}, viewAdded=$viewAdded"
        )
        refreshSystemTheme()
        updateFullscreenVisibility()
        logState("configuration changed", true)
    }

    private fun setupLocalBroadcastReceiver() {
        localBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                Log.d(
                    tag,
                    "broadcast received action=${intent.action}, more=${intent.getBooleanExtra("more", false)}, " +
                        "minHistoryId=${intent.getLongExtra("minHistoryId", 0L)}, loading=$loading, " +
                        "historyCount=${histories.size}"
                )
                when (intent.action) {
                    lockHistoryFloatLocation -> {
                        lockLoc = intent.getBooleanExtra("lock", false)
                        logState("broadcast lock location updated", true)
                    }

                    setHistoryFloatHandleWidth -> {
                        handleWidth = intent.getIntExtra("width", 32)
                        logState("broadcast handle width updated", true)
                    }

                    setHistoryFloatHandleColor -> {
                        handleColor = intent.getIntExtra("color", handleColor)
                        logState("broadcast handle color updated", true)
                    }

                    setHistoryFloatHandleApplyAlphaToWholeHandle -> {
                        applyAlphaToWholeHandle = intent.getBooleanExtra(
                            EXTRA_APPLY_ALPHA_TO_WHOLE_HANDLE,
                            applyAlphaToWholeHandle
                        )
                        logState("broadcast handle alpha mode updated", true)
                    }

                    setHistoryFloatThemeMode -> {
                        updateThemeMode(intent)
                        logState("broadcast theme mode updated", true)
                    }

                    sendHistories -> {
                        val receivedList =
                            intent.getSerializableExtra("list") as? ArrayList<HashMap<String, Any>>
                        val more = intent.getBooleanExtra("more", false)
                        if (receivedList == null) {
                            Log.d(tag, "loadHistories receivedList is null")
                            loading = false
                            logState("history result null", true)
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
                        Log.d(
                            tag,
                            "history result received more=$more, listSize=${list.size}, " +
                                "loadingBefore=$loading, historyCountBefore=${histories.size}, " +
                                "minHistoryIdBefore=$minHistoryId, reachedHistoryEndBefore=$reachedHistoryEnd"
                        )

                        if (!more) {
                            histories.clear()
                            minHistoryId = 0L
                            reachedHistoryEnd = false
                        }

                        if (list.isEmpty()) {
                            reachedHistoryEnd = true
                            loading = false
                            logState("history result empty", true)
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
                        logState("history result processed", true)
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(lockHistoryFloatLocation)
            addAction(setHistoryFloatHandleWidth)
            addAction(setHistoryFloatHandleColor)
            addAction(setHistoryFloatHandleApplyAlphaToWholeHandle)
            addAction(setHistoryFloatThemeMode)
            addAction(sendHistories)
        }

        LocalBroadcastManager.getInstance(this).registerReceiver(
            localBroadcastReceiver,
            filter
        )
    }

    private fun showFloatWindow() {
        logState("showFloatWindow requested", true)
        if (!Settings.canDrawOverlays(this) || viewAdded) {
            Log.d(
                tag,
                "showFloatWindow skipped overlayPermission=${Settings.canDrawOverlays(this)}, viewAdded=$viewAdded"
            )
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
        Log.d(tag, "addView before ${windowParamsDescription()}")
        try {
            windowManager.addView(composeView, mainParams)
            viewAdded = true
            Log.d(tag, "addView completed ${windowParamsDescription()}")
        } catch (e: Exception) {
            Log.e(tag, "addView failed: ${e::class.java.name}: ${e.message}", e)
            throw e
        }
        updateFullscreenVisibility()
        fullscreenCheckHandler.removeCallbacks(fullscreenCheckRunnable)
        fullscreenCheckHandler.post(fullscreenCheckRunnable)
        logState("showFloatWindow completed", true)
    }

    private fun updateFloatTexts(intent: Intent?) {
        if (intent == null) {
            return
        }
        val title = intent.getStringExtra(EXTRA_FLOAT_TITLE) ?: floatStrings.title
        val countTemplate = intent.getStringExtra(EXTRA_FLOAT_COUNT_TEMPLATE) ?: floatStrings.countTemplate
        val imageUnavailable = intent.getStringExtra(EXTRA_FLOAT_IMAGE_UNAVAILABLE) ?: floatStrings.imageUnavailable
        val textType = intent.getStringExtra(EXTRA_FLOAT_TEXT_TYPE) ?: floatStrings.textType
        val imageType = intent.getStringExtra(EXTRA_FLOAT_IMAGE_TYPE) ?: floatStrings.imageType
        val fileType = intent.getStringExtra(EXTRA_FLOAT_FILE_TYPE) ?: floatStrings.fileType
        floatStrings = HistoryFloatStrings(
            title = title,
            countTemplate = countTemplate,
            imageUnavailable = imageUnavailable,
            textType = textType,
            imageType = imageType,
            fileType = fileType,
        )
    }

    /**
     * 应用 Flutter 下发的历史悬浮窗主题模式，并触发 Compose 内容重组。
     */
    private fun updateThemeMode(intent: Intent?) {
        themeMode = HistoryFloatThemeMode.from(intent?.getStringExtra(EXTRA_FLOAT_THEME_MODE))
        darkTheme = themeMode.isDark(this)
    }

    /**
     * 跟随系统时，Android 夜间模式变化需要单独刷新 resolved 暗色状态。
     */
    private fun refreshSystemTheme() {
        if (themeMode == HistoryFloatThemeMode.SYSTEM) {
            darkTheme = themeMode.isDark(this)
        }
    }

    private fun setPos1P3() {
        val screenHeight = resources.displayMetrics.heightPixels
        mainParams.x = 0
        mainParams.y = -(screenHeight / 3)
        positionY = mainParams.y
    }

    private fun moveHandle(dy: Float) {
        if (lockLoc || expanded || !viewAdded) {
            Log.d(
                tag,
                "moveHandle skipped dy=$dy, lockLoc=$lockLoc, expanded=$expanded, viewAdded=$viewAdded"
            )
            return
        }
        positionY += dy.toInt()
        mainParams.x = 0
        mainParams.y = positionY
        updateWindowLayout("moveHandle")
    }

    private fun unfoldView() {
        if (!viewAdded || expanded) {
            Log.d(tag, "unfoldView skipped viewAdded=$viewAdded, expanded=$expanded")
            return
        }
        handleVisible = false
        closing = false
        mainParams.width = LayoutParams.MATCH_PARENT
        mainParams.height = LayoutParams.MATCH_PARENT
        mainParams.x = 0
        updateWindowLayout("unfoldView")
        composeView.post {
            expanded = true
            refreshData()
            logState("unfoldView posted", true)
        }
        logState("unfoldView requested", true)
    }

    private fun requestHideContainer() {
        if (!viewAdded || !expanded || closing) {
            Log.d(
                tag,
                "requestHideContainer skipped viewAdded=$viewAdded, expanded=$expanded, closing=$closing"
            )
            return
        }
        closing = true
        logState("requestHideContainer", true)
    }

    private fun hideContainer() {
        if (!viewAdded || !expanded) {
            Log.d(tag, "hideContainer skipped viewAdded=$viewAdded, expanded=$expanded")
            return
        }
        closing = false
        expanded = false
        handleVisible = false
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        mainParams.x = 0
        mainParams.y = positionY
        updateWindowLayout("hideContainer")
        composeView.post {
            handleVisible = true
            logState("hideContainer posted", true)
        }
        logState("hideContainer requested", true)
    }

    private fun prepareForDrag() {
        if (!viewAdded) {
            Log.d(tag, "prepareForDrag skipped viewAdded=$viewAdded")
            return
        }
        hiddenForDrag = true
        applyFloatVisibility()
        mainParams.width = LayoutParams.WRAP_CONTENT
        mainParams.height = LayoutParams.WRAP_CONTENT
        mainParams.x = 0
        updateWindowLayout("prepareForDrag")
        logState("prepareForDrag", true)
    }

    private fun restoreAfterDrag() {
        if (!viewAdded) {
            Log.d(tag, "restoreAfterDrag skipped viewAdded=$viewAdded")
            return
        }
        if (expanded) {
            mainParams.width = LayoutParams.MATCH_PARENT
            mainParams.height = LayoutParams.MATCH_PARENT
        } else {
            mainParams.width = LayoutParams.WRAP_CONTENT
            mainParams.height = LayoutParams.WRAP_CONTENT
        }
        updateWindowLayout("restoreAfterDrag")
        composeView.post {
            hiddenForDrag = false
            applyFloatVisibility()
            logState("restoreAfterDrag posted", true)
        }
        logState("restoreAfterDrag", true)
    }

    private fun refreshData(more: Boolean = false) {
        if (loading || (more && reachedHistoryEnd)) return
        Log.d(
            tag,
            "refreshData more=$more, loadingBefore=$loading, historyCount=${histories.size}, " +
                "minHistoryId=$minHistoryId, reachedHistoryEnd=$reachedHistoryEnd"
        )
        currentLoadVisibleCount = 0
        loading = true
        requestHistories(more)
        logState("refreshData requested", true)
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
        Log.d(
            tag,
            "fullscreen state changed from=$hiddenForFullscreen to=$isFullscreen, " +
                "visibleFrame=$visibleDisplayFrame"
        )
        hiddenForFullscreen = isFullscreen
        applyFloatVisibility()
        logState("fullscreen visibility updated", true)
    }

    private fun applyFloatVisibility() {
        val oldVisibility = composeView.visibility
        val oldAlpha = composeView.alpha
        val expectedFlags = if (hiddenForFullscreen) {
            BASE_WINDOW_FLAGS or LayoutParams.FLAG_NOT_TOUCHABLE
        } else {
            BASE_WINDOW_FLAGS
        }
        if (viewAdded && mainParams.flags != expectedFlags) {
            mainParams.flags = expectedFlags
            updateWindowLayout("applyFloatVisibility flags")
        }
        if (hiddenForFullscreen) {
            composeView.visibility = View.VISIBLE
            composeView.alpha = 0f
            if (oldVisibility != composeView.visibility || oldAlpha != composeView.alpha) {
                logState("applyFloatVisibility fullscreen", true)
            }
            return
        }

        composeView.alpha = 1f
        composeView.visibility = if (hiddenForDrag) View.INVISIBLE else View.VISIBLE
        if (oldVisibility != composeView.visibility || oldAlpha != composeView.alpha) {
            logState("applyFloatVisibility normal", true)
        }
    }

    private fun updateWindowLayout(operation: String) {
        Log.d(tag, "updateViewLayout before operation=$operation ${windowParamsDescription()}")
        try {
            windowManager.updateViewLayout(composeView, mainParams)
            Log.d(tag, "updateViewLayout completed operation=$operation ${windowParamsDescription()}")
        } catch (e: Exception) {
            Log.e(
                tag,
                "updateViewLayout failed operation=$operation: ${e::class.java.name}: ${e.message}",
                e
            )
            throw e
        }
    }

    private fun logState(event: String, force: Boolean = false) {
        if (!::composeView.isInitialized) {
            Log.d(tag, "$event view not initialized, viewAdded=$viewAdded")
            return
        }
        val state = buildString {
            append("viewAdded=$viewAdded")
            append(", attached=${composeView.isAttachedToWindow}")
            append(", visibility=${composeView.visibility}")
            append(", alpha=${composeView.alpha}")
            append(", expanded=$expanded")
            append(", closing=$closing")
            append(", handleVisible=$handleVisible")
            append(", hiddenForFullscreen=$hiddenForFullscreen")
            append(", hiddenForDrag=$hiddenForDrag")
            append(", loading=$loading")
            append(", historyCount=${histories.size}")
            append(", width=${mainParams.width}")
            append(", height=${mainParams.height}")
            append(", x=${mainParams.x}")
            append(", y=${mainParams.y}")
            append(", flags=${mainParams.flags}")
        }.toString()
        if (force || state != lastStateLog) {
            Log.d(tag, "$event: $state")
            lastStateLog = state
        }
    }

    private fun windowParamsDescription(): String {
        return "width=${mainParams.width}, height=${mainParams.height}, x=${mainParams.x}, " +
            "y=${mainParams.y}, flags=${mainParams.flags}, gravity=${mainParams.gravity}, " +
            "viewAdded=$viewAdded, attached=${composeView.isAttachedToWindow}, " +
            "visibility=${composeView.visibility}, alpha=${composeView.alpha}"
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
        const val EXTRA_FLOAT_TITLE = "historyFloatTitle"
        const val EXTRA_FLOAT_COUNT_TEMPLATE = "historyFloatCountTemplate"
        const val EXTRA_FLOAT_IMAGE_UNAVAILABLE = "historyFloatImageUnavailable"
        const val EXTRA_FLOAT_TEXT_TYPE = "historyFloatTextType"
        const val EXTRA_FLOAT_IMAGE_TYPE = "historyFloatImageType"
        const val EXTRA_FLOAT_FILE_TYPE = "historyFloatFileType"
        const val EXTRA_FLOAT_THEME_MODE = "themeMode"
        const val EXTRA_APPLY_ALPHA_TO_WHOLE_HANDLE = "applyAlphaToWholeHandle"
        private const val BASE_WINDOW_FLAGS =
            LayoutParams.FLAG_NOT_FOCUSABLE or LayoutParams.FLAG_NOT_TOUCH_MODAL
        private const val FULLSCREEN_CHECK_INTERVAL_MS = 500L
        private const val HISTORY_PAGE_SIZE = 100
    }
}
