package top.coclyun.clipshare

import android.app.Activity
import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
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
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import top.coclyun.clipshare.broadcast.ScreenReceiver
import top.coclyun.clipshare.observer.SmsObserver
import top.coclyun.clipshare.service.HistoryFloatService
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import androidx.core.net.toUri
import org.acra.ACRA
import java.io.BufferedInputStream
import java.net.URLDecoder


class MainActivity : FlutterFragmentActivity() {
    private val requestOverlayResultCode = 5002
    private lateinit var screenReceiver: ScreenReceiver
    private val TAG: String = "MainActivity";
    private var smsObserver: SmsObserver? = null;
    private lateinit var binaryMessenger: BinaryMessenger

    companion object {
        lateinit var commonChannel: MethodChannel;
        lateinit var androidChannel: MethodChannel;
        lateinit var androidEventChannel: EventChannel;
        lateinit var clipChannel: MethodChannel;
        lateinit var applicationContext: Context
        lateinit var pendingIntent: PendingIntent

        @JvmStatic
        var lockHistoryFloatLoc: Boolean = false

        var commonNotifyId = 2

        @JvmStatic
        val commonNotifyChannelId = "Common"

        /**
         * 发送通知
         */
        fun commonNotify(content: String) {
            // 构建通知
            val builder = NotificationCompat.Builder(applicationContext, commonNotifyChannelId)
                .setSmallIcon(R.drawable.launcher_icon).setContentTitle("ClipShare")
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
                applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager;
            // 发送通知
            notificationManager.notify(commonNotifyId++, builder.build())
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.binaryMessenger = flutterEngine.dartExecutor.binaryMessenger
        MainActivity.applicationContext = applicationContext
        MainActivity.pendingIntent = createPendingIntent()
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        commonChannel = MethodChannel(
            binaryMessenger, "top.coclyun.clipshare/common"
        )
        androidChannel = MethodChannel(
            binaryMessenger, "top.coclyun.clipshare/android"
        )
        clipChannel = MethodChannel(
            binaryMessenger, "top.coclyun.clipshare/clip"
        )
        androidEventChannel = EventChannel(
            binaryMessenger, "top.coclyun.clipshare/read_file"
        )
        initCommonChannel()
        initAndroidChannel()
        createNotifyChannel();
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

    private fun unRegisterSmsObserver() {
        if (smsObserver == null) return
        smsObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        smsObserver = null
        Log.d(TAG, "unRegisterSmsObserver")
    }

    private fun createNotifyChannel() {
        // 创建通知渠道（仅适用于 Android 8.0 及更高版本）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                commonNotifyChannelId, "普通通知", NotificationManager.IMPORTANCE_HIGH
            )
            val notificationManager =
                Companion.applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager;
            notificationManager.createNotificationChannel(channel)
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
            startActivity(intent)
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
                        ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")
                    );
                    startActivityForResult(intent, requestOverlayResultCode);
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
                    moveTaskToBack(true)
                }
                //发送通知
                "sendNotify" -> {
                    val content = args["content"].toString();
                    commonNotify(content)
                    result.success(true);
                }
                //显示历史浮窗
                "showHistoryFloatWindow" -> {
                    if (!isServiceRunning(this, HistoryFloatService::class.java)) {
                        startService(Intent(this, HistoryFloatService::class.java))
                    }
                }
                //锁定悬浮窗位置
                "lockHistoryFloatLoc" -> {
                    lockHistoryFloatLoc = args["loc"] as Boolean
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
                    val show = args["show"] as Boolean
                    val systemService =
                        getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val appTasks = systemService.appTasks
                    val size = appTasks.size
                    if (size > 0) {
                        appTasks[0].setExcludeFromRecents(!show)
                    }
                    result.success(size > 0);
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
            }
        }
        androidEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            val sinkMap: MutableMap<String, EventChannel.EventSink> = hashMapOf()
            override fun onListen(
                arguments: Any?,
                events: EventChannel.EventSink?,
            ) {
                if (arguments is Map<*, *>) {
                    val uri = arguments["uri"] as? String
                    if (uri == null || events == null) {
                        runOnUiThread {
                            events?.error("1", "uri is empty.", null)
                        }
                        return
                    }
                    try {
                        sinkMap[uri] = events
                        startSendFileBytes2Flutter(uri, sinkMap)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        runOnUiThread {
                            events.error("1", "uri is empty.", null)
                        }
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                if (arguments is Map<*, *>) {
                    val uri = arguments["uri"] as? String
                    if (uri != null) {
                        sinkMap.remove(uri)
                    }
                }
            }

        })
    }

    fun startSendFileBytes2Flutter(
        uriStr: String,
        sinkMap: MutableMap<String, EventChannel.EventSink>,
    ) {
        val uri = uriStr.toUri();
        val inputStream = contentResolver.openInputStream(uri)
        if (inputStream == null) {
            if (sinkMap.contains(uriStr)) {
                runOnUiThread {
                    sinkMap[uriStr]?.error("2", "inputStream is null", null)
                }
                sinkMap.remove(uriStr)
            }
            return
        }
        Thread {
            try {
                inputStream.use {
                    val buffer = ByteArray(1024 * 10)
                    var length: Int
                    while (inputStream.read(buffer).also { length = it } > 0) {
                        if (!sinkMap.contains(uriStr)) {
                            throw Exception("Not found sink for uri: $uriStr")
                        }
                        val data = buffer.copyOf(length)
                        runOnUiThread {
                            sinkMap[uriStr]?.success(data)
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                runOnUiThread {
                    sinkMap[uriStr]?.error("3", e.message, null)
                }
                sinkMap.remove(uriStr)
            } finally {
                runOnUiThread {
                    try {
                        sinkMap[uriStr]?.endOfStream()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }.start()
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
            intent.setData(Uri.parse("package:$packageName"))
            startActivity(intent)
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestOverlayResultCode) {
            if (resultCode != Activity.RESULT_OK) {
                if (!Settings.canDrawOverlays(this)) {
                    Toast.makeText(
                        this, "请授予悬浮窗权限，否则无法后台读取剪贴板！", Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        if (!hasFocus) return
        Log.d("MainActivity", "onResume")
    }

    fun onSmsChanged(content: String) {
        androidChannel.invokeMethod(
            "onSmsChanged", mapOf("content" to content)
        )
    }

    override fun onRestart() {
        super.onRestart()
        Log.d("MainActivity", "onRestart")
    }

    override fun onStop() {
        super.onStop()
        Log.d("MainActivity", "onRestart")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MainActivity", "onDestroy")
        try {
            // 取消注册广播接收器
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            e.printStackTrace();
        }
        try {
            //MainActivity被销毁时停止服务运行
            stopService(Intent(this, HistoryFloatService::class.java))
        } catch (e: Exception) {
            e.printStackTrace();
        }
        try {
            //MainActivity被销毁时停止服务运行
            unRegisterSmsObserver()
        } catch (e: Exception) {
            e.printStackTrace();
        }
    }

    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(this, this::class.java)
        intent.putExtra("fromNotification", true)
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    }

}
