package top.coclyun.clipshare

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class ProxyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val app = application as MyApplication
        app.updateRecentTasksVisibility()
        // 通知点击回调：把通知 id 上送 Flutter，由 Dart 统一分发点击后的业务。
        val notifyId = intent?.getIntExtra(notifyIdExtra, -1) ?: -1
        if (notifyId >= 0) {
            MyApplication.notifyClickToDart(notifyId)
        }
        val intent = FlutterFragmentActivity.CachedEngineIntentBuilder(
            MainActivity::class.java, MyApplication.FLUTTER_ENGINE_ID
        ).build(this)
        forwardSourceIntent(intent, this.intent)
        startActivity(intent)
        finish()
    }

    /**
     * 首次经由 ProxyActivity 拉起主界面时，需要把原始文件打开 Intent 一并透传。
     * 否则 MainActivity 首次创建只能拿到 CachedEngineIntentBuilder 生成的新 Intent，
     * 会丢失 ACTION_VIEW 对应的 uri、type 与授权信息。
     */
    private fun forwardSourceIntent(targetIntent: Intent, sourceIntent: Intent?) {
        if (sourceIntent == null) {
            return
        }
        targetIntent.action = sourceIntent.action
        if (sourceIntent.data != null || sourceIntent.type != null) {
            targetIntent.setDataAndType(sourceIntent.data, sourceIntent.type)
        }
        targetIntent.replaceExtras(sourceIntent)
        targetIntent.clipData = sourceIntent.clipData
        targetIntent.addFlags(sourceIntent.flags)
    }
}
