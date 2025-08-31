package top.coclyun.clipshare

import android.app.Application
import android.content.Context
import org.acra.ACRA
import org.acra.config.CoreConfigurationBuilder
import org.acra.config.HttpSenderConfigurationBuilder
import org.acra.data.StringFormat
import org.acra.sender.HttpSender

class MyApplication: Application() {

    override fun attachBaseContext(newBase: Context?) {
        super.attachBaseContext(newBase)
        val builder = CoreConfigurationBuilder()
            .withBuildConfigClass(BuildConfig::class.java)
            .withReportFormat(StringFormat.JSON)

        val httpConfig = HttpSenderConfigurationBuilder()
            .withUri("https://acra.coclyun.top/report")
            .withHttpMethod(HttpSender.Method.POST)
            .withBasicAuthLogin("n7evJKRuZezohrEs")
            .withBasicAuthPassword("9Qujrfk92bwpyHIB")
            .withConnectionTimeout(5000)
            .withSocketTimeout(20000)
            .withEnabled(true)//默认启用自动报告崩溃日志

        builder.withPluginConfigurations(httpConfig.build())

        ACRA.init(this, builder)
    }
}