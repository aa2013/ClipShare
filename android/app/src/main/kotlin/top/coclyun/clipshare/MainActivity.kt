package top.coclyun.clipshare

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterFragmentActivity() {

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(MyApplication.FLUTTER_ENGINE_ID)
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
