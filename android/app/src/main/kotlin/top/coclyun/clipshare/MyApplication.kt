package top.coclyun.clipshare

import android.app.ActivityManager
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.net.toUri
import androidx.documentfile.provider.DocumentFile
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.GeneratedPluginRegistrant
import org.acra.ACRA
import org.acra.config.CoreConfigurationBuilder
import org.acra.config.HttpSenderConfigurationBuilder
import org.acra.data.StringFormat
import org.acra.sender.HttpSender
import top.coclyun.clipshare.broadcast.ScreenReceiver
import top.coclyun.clipshare.clipboard_listener.ClipshareClipboardListenerPlugin
import top.coclyun.clipshare.observer.SmsObserver
import top.coclyun.clipshare.service.HistoryFloatService
import top.coclyun.clipshare.service.KeepAliveFloatService
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.net.URLDecoder

const val lockHistoryFloatLocation = "LOCK_HISTORY_FLOAT_LOCATION"
const val setHistoryFloatHandleWidth = "SET_HISTORY_FLOAT_HANDLE_WIDTH"
const val setHistoryFloatHandleColor = "SET_HISTORY_FLOAT_HANDLE_COLOR"
const val loadHistories = "LOAD_HISTORIES"
const val sendHistories = "SEND_HISTORIES"
const val OnHistoryChangedBroadcastAction = "top.coclyun.clipshare.ACTION_ON_HISTORY_CHANGED"
// Match the original translucent white default until the user picks a custom handle color.
val defaultHistoryFloatHandleColor = 0x17FFFFFF.toInt()

class MyApplication : Application() {

    private lateinit var flutterEngine: FlutterEngine
    private lateinit var methodChannel: MethodChannel
    private lateinit var localBroadcastReceiver: BroadcastReceiver
    private lateinit var screenReceiver: ScreenReceiver
    private val TAG: String = "MyApplication";
    private var smsObserver: SmsObserver? = null;
    private lateinit var binaryMessenger: BinaryMessenger
    private lateinit var notifyManager: NotificationManager
    private var showOnRecentTask = true

    companion object {
        const val FLUTTER_ENGINE_ID = "main_engine"
        lateinit var commonChannel: MethodChannel
        lateinit var androidChannel: MethodChannel
        lateinit var clipChannel: MethodChannel
        lateinit var applicationContext: Context
        lateinit var pendingIntent: PendingIntent


        var commonNotifyId = 2

        @JvmStatic
        var mainActivity: MainActivity? = null

        @JvmStatic
        val commonNotifyChannelId = "Common"

        @JvmStatic
        val requestOverlayResultCode = 5002

        /**
         * 发送通知
         */
        fun commonNotify(title:String?, content: String): Int {
            // 构建通知
            val builder = NotificationCompat.Builder(applicationContext, commonNotifyChannelId)
                .setSmallIcon(R.drawable.launcher_icon).setContentTitle( title ?: "ClipShare")
                .setContentText(content).setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent).setFullScreenIntent(pendingIntent, true)
                // 点击通知后自动关闭
                .setAutoCancel(true)
                // 设置为公开可见通知
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setBadgeIconType(NotificationCompat.BADGE_ICON_NONE)
            }
            val notificationManager =
                applicationContext.getSystemService(NOTIFICATION_SERVICE) as NotificationManager;
            val id = commonNotifyId++
            // 发送通知
            notificationManager.notify(id, builder.build())
            return id
        }
    }

    /**
     * 初始化应用主进程的 FlutterEngine 和平台通道，独立进程只保留自身必要初始化。
     */
    override fun onCreate() {
        super.onCreate()
        MyApplication.applicationContext = applicationContext
        if (!isMainProcess()) {
            Log.d(TAG, "Skip FlutterEngine initialization in non-main process: ${getCurrentProcessName()}")
            return
        }
        ClipshareClipboardListenerPlugin.activityClass = MainActivity::class.java
        MyApplication.pendingIntent = createPendingIntent()
        // 创建 engine
        flutterEngine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        this.binaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        commonChannel = MethodChannel(binaryMessenger, "top.coclyun.clipshare/common")
        androidChannel = MethodChannel(binaryMessenger, "top.coclyun.clipshare/android")
        clipChannel = MethodChannel(binaryMessenger, "top.coclyun.clipshare/clip")
        initCommonChannel()
        initAndroidChannel()
        createNotifyChannel()
        setupLocalBroadcastReceiver()
        // 先完成插件、通知和平台通道注册，再启动 Dart，避免入口代码过早调用尚未准备好的 MethodChannel。
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(FLUTTER_ENGINE_ID, flutterEngine)
    }

    /**
     * 判断当前是否为应用主进程，只有主进程需要初始化并缓存 FlutterEngine。
     */
    private fun isMainProcess(): Boolean {
        return packageName == getCurrentProcessName()
    }

    /**
     * 获取当前进程名，用于避免 ACRA 等独立进程重复初始化 Flutter 引擎。
     */
    private fun getCurrentProcessName(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return Application.getProcessName()
        }
        val currentPid = android.os.Process.myPid()
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return activityManager.runningAppProcesses
            ?.firstOrNull { processInfo -> processInfo.pid == currentPid }
            ?.processName
    }

    override fun attachBaseContext(newBase: Context?) {
        super.attachBaseContext(newBase)
        val builder = CoreConfigurationBuilder()
            .withBuildConfigClass(BuildConfig::class.java)
            .withReportFormat(StringFormat.JSON)

        val httpConfig = HttpSenderConfigurationBuilder()
            .withUri("https://acra.coclyun.top/report")
            .withHttpMethod(HttpSender.Method.POST)
            .withBasicAuthLogin("6NlEx1mIPWsgiK1m")
            .withBasicAuthPassword("k7y4lOhBWAb27xSN")
            .withConnectionTimeout(5000)
            .withSocketTimeout(20000)
            .withEnabled(true)//默认关闭自动报告崩溃日志

        builder.withPluginConfigurations(httpConfig.build())

        ACRA.init(this, builder)
    }

    private fun registerSmsObserver() {
        if (smsObserver != null) {
            unRegisterSmsObserver()
        }
        val handler = Handler()
        val observer = SmsObserver(this, handler)
        Log.d(TAG, "registerSmsObserver")
        smsObserver = observer
        contentResolver.registerContentObserver(Uri.parse("content://sms/"), true, observer)
    }

    /**
     * 注册应用内历史记录广播，将悬浮窗请求转发到 Flutter 侧并回传查询结果。
     */
    private fun setupLocalBroadcastReceiver() {
        localBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    loadHistories -> {
                        val more = intent.getBooleanExtra("more", false)
                        val minHistoryId = intent.getLongExtra("minHistoryId", 0)
                        clipChannel.invokeMethod(
                            "getHistory",
                            mapOf("fromId" to if (more) minHistoryId else 0L),
                            object : Result {
                                @Suppress("UNCHECKED_CAST")
                                override fun success(result: Any?) {
                                    val tmpList = result as List<Map<String, Any>>
                                    val serializableList = ArrayList<HashMap<String, Any>>().apply {
                                        tmpList.forEach { map ->
                                            add(HashMap(map))
                                        }
                                    }
                                    sendHistoriesResult(context, more, serializableList)
                                }

                                override fun error(
                                    errorCode: String, errorMessage: String?, errorDetails: Any?
                                ) {
                                    Log.e(TAG, "Failed to get histories from Flutter: $errorCode, $errorMessage")
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Flutter method getHistory is not implemented")
                                }

                            })
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(loadHistories)
        }

        LocalBroadcastManager.getInstance(this).registerReceiver(
            localBroadcastReceiver, filter
        )
    }

    /**
     * 将 Flutter 返回的历史记录查询结果转发给悬浮窗。
     */
    private fun sendHistoriesResult(
        context: Context,
        more: Boolean,
        histories: List<HashMap<String, Any>>
    ) {
        val intent = Intent(sendHistories)
        intent.putExtra("list", ArrayList(histories))
        intent.putExtra("more", more)
        LocalBroadcastManager.getInstance(context).sendBroadcast(intent)
    }

    private fun unRegisterSmsObserver() {
        if (smsObserver == null) return
        smsObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        smsObserver = null
        Log.d(TAG, "unRegisterSmsObserver")
    }

    private fun createNotifyChannel() {
        notifyManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        // 创建通知渠道（仅适用于 Android 8.0 及更高版本）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                commonNotifyChannelId, "普通通知", NotificationManager.IMPORTANCE_HIGH
            )
            notifyManager.createNotificationChannel(channel)
        }
    }

    /**
     * 检查通知权限
     */
    private fun checkNotification(): Boolean {
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        return notificationManager.areNotificationsEnabled()
    }

    /**
     * 请求通知权限
     */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            applicationContext.startActivity(intent)
        }
    }


    /**
     * 判断服务是否运行
     * @param context 上下文
     * @param serviceClass 服务类
     */
    private fun isServiceRunning(context: Context, serviceClass: Class<*>): Boolean {
        val activityManager = context.getSystemService(ACTIVITY_SERVICE) as ActivityManager

        // 获取运行中的服务列表
        for (service in activityManager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                // 如果找到匹配的服务类名，表示服务在运行
                return true
            }
        }
        // 未找到匹配的服务类名，表示服务未在运行
        return false
    }

    /**
     * 初始化平台channel
     */
    private fun initAndroidChannel() {
        // 注册广播接收器
        screenReceiver = ScreenReceiver(androidChannel)
        val filter = IntentFilter()
        filter.addAction(Intent.ACTION_SCREEN_ON)
        filter.addAction(Intent.ACTION_SCREEN_OFF)
        filter.addAction(Intent.ACTION_USER_PRESENT)
        registerReceiver(screenReceiver, filter)
        androidChannel.setMethodCallHandler { call, result ->
            var args: Map<String, Any> = mapOf()
            if (call.arguments is Map<*, *>) {
                args = call.arguments as Map<String, Any>
            }
            when (call.method) {
                //检查悬浮窗权限
                "checkAlertWindowPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                //授权悬浮窗权限
                "grantAlertWindowPermission" -> {
                    val intent = Intent(
                        ACTION_MANAGE_OVERLAY_PERMISSION, "package:$packageName".toUri()
                    )
                    mainActivity?.startActivityForResult(intent, requestOverlayResultCode);
                    result.success(true)
                }
                //检查通知权限
                "checkNotification" -> {
                    result.success(checkNotification())
                }
                //授权通知权限
                "grantNotification" -> {
                    requestNotificationPermission()
                }
                //检查电池优化
                "checkIgnoreBattery" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                //请求忽略电池优化
                "requestIgnoreBattery" -> {
                    requestIgnoreBatteryOptimizations()
                }
                //将应用置于后台
                "moveToBg" -> {
                    mainActivity?.moveTaskToBack(true)
                }
                //发送通知
                "sendNotify" -> {
                    val title = args["title"].toString();
                    val content = args["content"].toString();
                    result.success(commonNotify(title, content));
                }
                //发送通知
                "cancelNotify" -> {
                    val id = args["id"] as Int
                    notifyManager.cancel(id)
                    result.success(true);
                }
                //显示历史浮窗
                "showHistoryFloatWindow" -> {
                    val width = (args["width"] as? Number)?.toInt() ?: 32
                    val color = (args["color"] as? Number)?.toInt() ?: defaultHistoryFloatHandleColor
                    val i18n = args["i18n"] as? Map<*, *>
                    if (!isServiceRunning(this, HistoryFloatService::class.java)) {
                        startService(Intent(this, HistoryFloatService::class.java).apply {
                            putExtra("width", width)
                            putExtra("color", color)
                            putExtra(
                                HistoryFloatService.EXTRA_FLOAT_TITLE,
                                i18n?.get("title") as? String
                            )
                            putExtra(
                                HistoryFloatService.EXTRA_FLOAT_COUNT_TEMPLATE,
                                i18n?.get("countTemplate") as? String
                            )
                            putExtra(
                                HistoryFloatService.EXTRA_FLOAT_IMAGE_UNAVAILABLE,
                                i18n?.get("imageUnavailable") as? String
                            )
                            putExtra(
                                HistoryFloatService.EXTRA_FLOAT_TEXT_TYPE,
                                i18n?.get("textType") as? String
                            )
                            putExtra(
                                HistoryFloatService.EXTRA_FLOAT_IMAGE_TYPE,
                                i18n?.get("imageType") as? String
                            )
                            putExtra(
                                HistoryFloatService.EXTRA_FLOAT_FILE_TYPE,
                                i18n?.get("fileType") as? String
                            )
                        })
                    }
                }
                "showKeepAliveFloatWindow" -> {
                    if (Settings.canDrawOverlays(this) && !isServiceRunning(this, KeepAliveFloatService::class.java)) {
                        startService(Intent(this, KeepAliveFloatService::class.java))
                    }
                }
                "setHistoryFloatHandleWidth" -> {
                    val width = (args["width"] as? Number)?.toInt() ?: 32
                    val intent = Intent(setHistoryFloatHandleWidth)
                    intent.putExtra("width", width)
                    LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
                    if (isServiceRunning(this, HistoryFloatService::class.java)) {
                        startService(Intent(this, HistoryFloatService::class.java).apply {
                            action = setHistoryFloatHandleWidth
                            putExtra("width", width)
                        })
                    }
                }
                "setHistoryFloatHandleColor" -> {
                    val color = (args["color"] as? Number)?.toInt() ?: defaultHistoryFloatHandleColor
                    val intent = Intent(setHistoryFloatHandleColor)
                    intent.putExtra("color", color)
                    LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
                    if (isServiceRunning(this, HistoryFloatService::class.java)) {
                        startService(Intent(this, HistoryFloatService::class.java).apply {
                            action = setHistoryFloatHandleColor
                            putExtra("color", color)
                        })
                    }
                }
                "closeKeepAliveFloatWindow" -> {
                    stopService(Intent(this, KeepAliveFloatService::class.java))
                }
                //锁定悬浮窗位置
                "lockHistoryFloatLoc" -> {
                    val lockLoc = args["loc"] as Boolean
                    val intent = Intent(lockHistoryFloatLocation)
                    intent.putExtra("lock", lockLoc)
                    LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
                    if (isServiceRunning(this, HistoryFloatService::class.java)) {
                        startService(Intent(this, HistoryFloatService::class.java).apply {
                            action = lockHistoryFloatLocation
                            putExtra("lock", lockLoc)
                        })
                    }
                }
                //关闭历史浮窗
                "closeHistoryFloatWindow" -> {
                    stopService(Intent(this, HistoryFloatService::class.java))
                }
                //提示
                "toast" -> {
                    val content = args["content"].toString();
                    Toast.makeText(this, content, Toast.LENGTH_LONG).show();
                    result.success(true);
                }
                //从content中复制文件到指定路径
                "copyFileFromUri" -> {
                    var savedPath: String? = null
                    try {
                        val content = args["content"].toString()
                        val uri = content.toUri();
                        val documentFile = DocumentFile.fromSingleUri(this, uri)
                        val fileName = documentFile!!.name
                        savedPath = args["savedPath"].toString() + "/${fileName}";
                        val inputStream = contentResolver.openInputStream(uri)
                        if (inputStream == null) {
                            Log.e(TAG, "Failed to open input stream for URI: $content")
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val destFile = File(savedPath)
                        val outputStream: OutputStream = FileOutputStream(destFile)
                        val buffer = ByteArray(1024 * 10)
                        var length: Int
                        while (inputStream.read(buffer).also { length = it } > 0) {
                            outputStream.write(buffer, 0, length)
                        }
                        inputStream.close()
                        outputStream.close()
                    } catch (e: Exception) {
                        e.printStackTrace();
                        result.success(null)
                    }
                    result.success(savedPath)
                }
                //从uri中获取文件名称和大小
                "getFileNameFromUri" -> {
                    try {
                        val content = args["uri"].toString()
                        val uri = content.toUri()
                        val documentFile = DocumentFile.fromSingleUri(this, uri)
                        val fileName = URLDecoder.decode(documentFile!!.name, "UTF-8")
                        val length = documentFile.length()
                        result.success("$fileName,$length")
                    } catch (e: Exception) {
                        e.printStackTrace();
                        result.success(null)
                    }
                }
                //图片更新后通知媒体库扫描
                "notifyMediaScan" -> {
                    val imagePath = args["imagePath"].toString();
                    MediaScannerConnection.scanFile(
                        applicationContext, arrayOf(imagePath), null
                    ) { path, uri ->
                        Log.i(TAG, "initAndroidChannel: MediaScanner Completed")
                    }
                }
                //开启短信监听
                "startSmsListen" -> {
                    registerSmsObserver()
                }
                //停止短信监听
                "stopSmsListen" -> {
                    unRegisterSmsObserver()
                }
                //是否显示在后台任务卡片
                "showOnRecentTasks" -> {
                    showOnRecentTask = args["show"] as Boolean
                    updateRecentTasksVisibility()
                    result.success(true);
                }
                //获取指定Uri的真实路径
                "getImageUriRealPath" -> {
                    val uriStr = args["uri"].toString()
                    val uri = uriStr.toUri();
                    val path = getImagePathFromUri(this, uri)
                    result.success(path)
                }
                //获取媒体库中的最新一张图片
                "getLatestImagePath" -> {
                    val path = getLatestImagePath(this)
                    result.success(path)
                }
                //是否自动报告崩溃（可能在下一次启动app时才会有）
                "setAutoReportCrashes" -> {
                    val enable = args["enable"] as Boolean
                    ACRA.errorReporter.setEnabled(enable)
                    result.success(null)
                }
                //是否自动报告崩溃（可能在下一次启动app时才会有）
                "sendHistoryChangedBroadcast" -> {
                    val intent = Intent(OnHistoryChangedBroadcastAction)
                    for (key in args.keys) {
                        intent.putExtra(key, args[key].toString())
                    }
                    sendBroadcast(intent)
                    result.success(null)
                }
            }
        }
    }

    public fun updateRecentTasksVisibility() {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appTasks = am.appTasks
        for (task in appTasks) {
            task.setExcludeFromRecents(!showOnRecentTask)
        }
    }

    /**
     * 根据uri获取图片真实路径
     */
    private fun getImagePathFromUri(context: Context, uri: Uri?): String? {
        try {
            val projection = arrayOf(MediaStore.Images.Media.DATA) // 根据类型调整字段
            val cursor =
                context.contentResolver.query(uri!!, projection, null, null, null) ?: return null
            val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            if (columnIndex == -1) return null
            cursor.moveToFirst()
            val path = cursor.getString(columnIndex)
            cursor.close()
            return path
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    /**
     * 获取 MediaStore 中 1s内的最新一张图片并返回其路径
     */
    private fun getLatestImagePath(context: Context): String? {
        try {
            val projection =
                arrayOf(MediaStore.Images.Media.DATA, MediaStore.Images.Media.DATE_ADDED)
            val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

            val cursor = context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, projection, null, null, sortOrder
            ) ?: return null

            if (cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                if (columnIndex == -1) return null
                cursor.moveToFirst()
                val path = cursor.getString(columnIndex)
                cursor.close()
                return path
            } else {
                cursor.close()
                return null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.setData("package:$packageName".toUri())
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            applicationContext.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        var isIgnoring = false
        val powerManager: PowerManager? = getSystemService(Context.POWER_SERVICE) as PowerManager?
        if (powerManager != null) {
            isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return isIgnoring
    }

    /**
     * 初始化通用channel
     */
    private fun initCommonChannel() {
        commonChannel.setMethodCallHandler { call, result ->
            when (call.method) {
            }
        }
    }

    fun onSmsChanged(content: String) {
        androidChannel.invokeMethod(
            "onSmsChanged", mapOf("content" to content)
        )
    }

    /**
     * 创建通知点击 PendingIntent，当前按既有行为保留入口目标。
     */
    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(this, ProxyActivity::class.java)
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    }


}
