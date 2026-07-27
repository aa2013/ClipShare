package top.coclyun.clipshare

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {

    /**
     * 所有入口统一使用 Application 预热并缓存的主 FlutterEngine。
     * 否则可能出现偶发性的 "Cannot execute operation because FlutterJNI is not attached to native"错误
     */
    override fun getCachedEngineId(): String {
        return MyApplication.FLUTTER_ENGINE_ID
    }

    /**
     * 主 FlutterEngine 承载后台通道和常驻服务回调，Activity 销毁或旋转重建时不能释放。
     */
    override fun shouldDestroyEngineWithHost(): Boolean {
        return false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MyApplication.mainActivity = this
        dispatchFileOpenIntent(intent)
    }

    /**
     * share_handler 依赖 Activity 的新 Intent 回调来处理运行中的分享事件。
     * 这里额外补偿转发 ACTION_VIEW 文件打开事件，确保文件管理器“打开方式”也能复用 Flutter 侧统一处理链路。
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchFileOpenIntent(intent)
    }

    /**
     * 首次创建与后续复用 Activity 都统一走这里分发文件打开事件，避免两条入口行为不一致。
     */
    private fun dispatchFileOpenIntent(intent: Intent?) {
        val dataString = intent?.dataString
        if (intent?.action != Intent.ACTION_VIEW || dataString.isNullOrEmpty()) {
            return
        }
        MyApplication.androidChannel.invokeMethod(
            "onFileOpened",
            mapOf("uri" to dataString)
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        try {
            super.onActivityResult(requestCode, resultCode, data)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        if (requestCode == MyApplication.requestOverlayResultCode) {
            if (resultCode != Activity.RESULT_OK) {
                if (!Settings.canDrawOverlays(this)) {
                    Toast.makeText(
                        this, "请授予悬浮窗权限，否则无法后台读取剪贴板！", Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
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
        MyApplication.mainActivity = null
        Log.d("MainActivity", "onDestroy")
        try {
            super.onDestroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

}
