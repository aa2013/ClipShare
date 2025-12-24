package top.coclyun.clipshare.observer

import android.annotation.SuppressLint
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.util.Log
import top.coclyun.clipshare.MyApplication


class SmsObserver(private val app: MyApplication, handler: Handler) :
    ContentObserver(handler) {
    private val tag = "SmsObserver"
    private var lastSmsId: Long = -1

    init {
        val cursor: Cursor? = app.contentResolver.query(
                Uri.parse("content://sms/inbox"),
                null,
                null,
                null,
                "date DESC LIMIT 1"
            )
        if (cursor != null && cursor.moveToFirst()) {
            lastSmsId = cursor.getLong(cursor.getColumnIndex("_id"))
        }
    }

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        super.onChange(selfChange, uri)
        Log.d(tag, uri.toString())
        readSms();
    }

    /**
     * 读取短信
     * @SuppressLint("Range")抑制与使用Cursor时获取列索引相关的警告
     */
    @SuppressLint("Range")
    private fun readSms() {
        val cursor: Cursor? =
            app.contentResolver.query(
                Uri.parse("content://sms/inbox"),
                null,
                null,
                null,
                "date DESC LIMIT 1"
            )
        if (cursor != null && cursor.moveToFirst()) {
            val smsId = cursor.getLong(cursor.getColumnIndex("_id"))
            if (smsId <= lastSmsId) return
            lastSmsId = smsId
            val address = cursor.getString(cursor.getColumnIndex("address"))
            val body = cursor.getString(cursor.getColumnIndex("body"))
//            Log.d(tag, "Sender: $address, Message: $body")
            cursor.close()
            app.onSmsChanged(body)
        } else {
            Log.d(tag, "no result")
        }
    }
}