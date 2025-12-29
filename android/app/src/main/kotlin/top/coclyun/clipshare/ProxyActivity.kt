package top.coclyun.clipshare

import android.app.Activity
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterFragmentActivity

class ProxyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val app = application as MyApplication
        app.updateRecentTasksVisibility()
        val intent = FlutterFragmentActivity.CachedEngineIntentBuilder(
            MainActivity::class.java, MyApplication.FLUTTER_ENGINE_ID
        ).build(this);
        startActivity(intent)
        finish()
    }
}