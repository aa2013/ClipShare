package top.coclyun.clipshare.adapter

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import android.view.DragEvent
import android.view.LayoutInflater
import android.view.View
import android.view.View.DragShadowBuilder
import android.view.View.GONE
import android.view.View.VISIBLE
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat.getSystemService
import androidx.recyclerview.widget.RecyclerView
import io.flutter.plugin.common.MethodChannel.Result
import top.coclyun.clipshare.MainActivity
import top.coclyun.clipshare.R
import kotlin.math.min


class HistoryFloatAdapter(
    dataList: List<History>,
    private val onDragStart: () -> Unit,
    private val onDragEnd: () -> Unit,
) : RecyclerView.Adapter<HistoryFloatViewHolder>() {
    private val dataList: MutableList<History> = dataList.toMutableList();
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): HistoryFloatViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.history_float_item_layout, parent, false)
        return HistoryFloatViewHolder(view)
    }

    override fun onBindViewHolder(holder: HistoryFloatViewHolder, position: Int) {
        val item = dataList[position]
        holder.bind(item, onDragStart, onDragEnd)
    }

    override fun getItemCount(): Int {
        return dataList.size
    }

    fun addDataList(list: List<History>) {
        dataList.addAll(list)
        // 更新整个数据集
        notifyDataSetChanged()
    }
}

class HistoryFloatViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {

    private val textView = itemView.findViewById<TextView>(R.id.content)
    private val imageView = itemView.findViewById<ImageView>(R.id.image)
    private val copyIcon = itemView.findViewById<ImageView>(R.id.copyIcon)
    private val pinIcon = itemView.findViewById<ImageView>(R.id.pinIcon)
    private lateinit var onDragStart: () -> Unit
    private lateinit var onDragEnd: () -> Unit
    private fun ignoreNextCopy(){
        MainActivity.clipChannel.invokeMethod("ignoreNextCopy",null)
    }
    @SuppressLint("ClickableViewAccessibility")
    private val onTouchLinear: View.OnTouchListener = View.OnTouchListener { _, event ->
        itemView.onTouchEvent(event)
        false
    }

    private val onDragListener: View.OnDragListener = View.OnDragListener { _, event ->
        when (event.action) {
            DragEvent.ACTION_DRAG_STARTED -> {
                onDragStart()
            }

            DragEvent.ACTION_DRAG_ENDED -> {
                onDragEnd()
            }
        }
        true
    }

    @SuppressLint("ClickableViewAccessibility")
    fun bind(item: History, onDragStart: () -> Unit, onDragEnd: () -> Unit) {
        this.onDragStart = onDragStart
        this.onDragEnd = onDragEnd
        //region 设置显示内容
        val type = item.type
        val content = item.content;
        if (type.lowercase() == "image") {
            //图片
            textView.visibility = GONE
            imageView.visibility = VISIBLE
            val bitmap = BitmapFactory.decodeFile(content)
            imageView.setImageBitmap(bitmap)

            imageView.setOnLongClickListener {
                //开始startDragAndDrop
                val dragData = ClipData.newUri(
                    itemView.context.contentResolver,
                    "image",
                    Uri.parse("content://top.coclyun.clipshare.FileProvider/${item.content}")
                )
                val shadow = DragShadowBuilder(imageView)
                imageView.startDragAndDrop(dragData, shadow, null, View.DRAG_FLAG_GLOBAL)
                false
            }
            imageView.setOnDragListener(onDragListener)

        } else {
            //文本
            textView.visibility = VISIBLE
            imageView.visibility = GONE
            textView.text = content.substring(0, min(200, content.length))
            //由于TextView的点击事件拦截导致LinearLayout的水波纹效果在TextView上无法触发，此处进行手动调用
            textView.setOnTouchListener(onTouchLinear)
            textView.setOnLongClickListener {
                //开始startDragAndDrop
                val mimeTypes = arrayOf(ClipDescription.MIMETYPE_TEXT_PLAIN)
                val dragData = ClipData("text", mimeTypes, ClipData.Item(content))
                val shadow = DragShadowBuilder(textView)
                textView.startDragAndDrop(dragData, shadow, null, View.DRAG_FLAG_GLOBAL)
                false
            }
            textView.setOnDragListener(onDragListener)
        }
        //endregion
        //region 复制按钮
        copyIcon.setOnClickListener {
            // 获取剪贴板管理器
            val clipboardManager = getSystemService(
                itemView.context,
                ClipboardManager::class.java
            ) as ClipboardManager
            if (item.type.lowercase() == "text") {
                // 创建一个剪贴板数据
                val clipData = ClipData.newPlainText("text", content)
                ignoreNextCopy()
                // 将数据放入剪贴板
                clipboardManager.setPrimaryClip(clipData)
            } else {
                val pkgName = itemView.context.packageName
                val clipData = ClipData.newUri(
                    itemView.context.contentResolver,
                    "image",
                    Uri.parse("content://${pkgName}.clipboard_listener.FileProvider/${item.content}")
                )
                ignoreNextCopy()
                // 将数据放入剪贴板
                clipboardManager.setPrimaryClip(clipData)
            }
            copyIcon.setImageResource(R.drawable.baseline_check_24);
            copyIcon.postDelayed({
                copyIcon.setImageResource(R.drawable.outline_content_copy_24)
            }, 500)

        }
        //endregion
        //region 置顶按钮
        pinIcon.setImageResource(if (item.top) R.drawable.baseline_push_pin_24 else R.drawable.outline_push_not_pin_24)
        pinIcon.setOnClickListener {
            item.top = !item.top
            pinIcon.setImageResource(if (item.top) R.drawable.baseline_push_pin_24 else R.drawable.outline_push_not_pin_24)
            MainActivity.clipChannel.invokeMethod(
                "setTop",
                mapOf("id" to item.id, "top" to item.top),
                object : Result {
                    override fun success(result: Any?) {
                        Log.d("setTop", "$result")
                        if (result != true) {
                            //更新失败，还原
                            item.top = !item.top
                            pinIcon.setImageResource(if (item.top) R.drawable.baseline_push_pin_24 else R.drawable.outline_push_not_pin_24)
                        }
                    }

                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?
                    ) {
                        //更新失败，还原
                        item.top = !item.top
                        pinIcon.setImageResource(if (item.top) R.drawable.baseline_push_pin_24 else R.drawable.outline_push_not_pin_24)
                    }

                    override fun notImplemented() {
                        //更新失败，还原
                        item.top = !item.top
                        pinIcon.setImageResource(if (item.top) R.drawable.baseline_push_pin_24 else R.drawable.outline_push_not_pin_24)
                    }

                })
        }
        //endregion
    }
}