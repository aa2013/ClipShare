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
