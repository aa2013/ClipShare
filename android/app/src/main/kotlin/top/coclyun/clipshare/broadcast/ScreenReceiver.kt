package top.coclyun.clipshare.broadcast

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import top.coclyun.clipshare.MainActivity
import top.coclyun.clipshare.MyApplication

class ScreenReceiver internal constructor(private var androidChannel: MethodChannel) :
    BroadcastReceiver() {
    constructor() : this(androidChannel = MyApplication.androidChannel)

    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_SCREEN_ON == intent.action) {
            // 屏幕已打开
            androidChannel.invokeMethod("onScreenOpened", null)
        } else if (Intent.ACTION_USER_PRESENT == intent.action) {
            // 屏幕已解锁
            androidChannel.invokeMethod("onScreenUnlocked", null)
        } else if (Intent.ACTION_SCREEN_OFF == intent.action) {
            // 屏幕已关闭
            androidChannel.invokeMethod("onScreenClosed", null)
        }
    }
}