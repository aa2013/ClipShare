@file:OptIn(ExperimentalFoundationApi::class)

package top.coclyun.clipshare.service

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Point
import android.graphics.RectF
import android.graphics.BitmapFactory
import android.net.Uri
import android.text.TextPaint
import android.view.DragEvent
import android.view.View
import android.view.View.DragShadowBuilder
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import top.coclyun.clipshare.MyApplication
import top.coclyun.clipshare.R
import top.coclyun.clipshare.adapter.History
import java.io.File
import kotlin.math.min

private val PanelBackground = Color(0xFFF9FAFB)
private val PanelStroke = Color(0xFFE5E7EB)
private val ItemBackground = Color.White
private val PrimaryText = Color(0xFF111827)
private val SecondaryText = Color(0xFF6B7280)
private val Accent = Color(0xFF2563EB)

@Composable
fun HistoryFloatContent(
    histories: List<History>,
    expanded: Boolean,
    loading: Boolean,
    closing: Boolean,
    handleVisible: Boolean,
    handleWidth: Int,
    onExpand: () -> Unit,
    onCollapse: () -> Unit,
    onCollapseFinished: () -> Unit,
    onMoveHandle: (Float) -> Unit,
    onLoadMore: () -> Unit,
    onDragStart: () -> Unit,
    onDragEnd: () -> Unit,
) {
    MaterialTheme {
        if (expanded) {
            ExpandedHistoryPanel(
                histories = histories,
                loading = loading,
                closing = closing,
                onCollapse = onCollapse,
                onCollapseFinished = onCollapseFinished,
                onLoadMore = onLoadMore,
                onDragStart = onDragStart,
                onDragEnd = onDragEnd,
            )
        } else if (handleVisible) {
            HistoryHandle(
                onExpand = onExpand,
                onMoveHandle = onMoveHandle,
                handleWidth = handleWidth,
            )
        }
    }
}


@Composable
private fun HistoryHandle(
    onExpand: () -> Unit,
    onMoveHandle: (Float) -> Unit,
    handleWidth: Int = 32,
) {
    var active by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val interactionSource = remember { MutableInteractionSource() }
    val handleWidth by animateDpAsState(targetValue = if (active) (handleWidth + 16).dp else handleWidth.dp, label = "handleWidth")
    val handleHeight by animateDpAsState(targetValue = if (active) 108.dp else 96.dp, label = "handleHeight")
    val handleAlpha by animateFloatAsState(targetValue = if (active) 0.22f else 0.09f, label = "handleAlpha")

    Box(
        modifier = Modifier
            .width(handleWidth)
            .height(handleHeight)
            .pointerInput(Unit) {
                var totalX = 0f
                detectDragGestures(
                    onDragStart = {
                        totalX = 0f
                        active = true
                    },
                    onDragEnd = {
                        if (totalX < -20f) {
                            onExpand()
                        }
                        scope.launch {
                            delay(500)
                            active = false
                        }
                    },
                ) { change, dragAmount ->
                    change.consume()
                    totalX += dragAmount.x
                    onMoveHandle(dragAmount.y)
                }
            }
            .combinedClickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = {},
                onDoubleClick = {
                    active = true
                    scope.launch {
                        delay(500)
                        active = false
                    }
                    onExpand()
                },
            ),
        contentAlignment = Alignment.CenterEnd,
    ) {
        Surface(
            modifier = Modifier
                .width(handleWidth)
                .height(handleHeight),
            shape = RoundedCornerShape(topStart = 22.dp, bottomStart = 22.dp),
            color = Color.White.copy(alpha = handleAlpha),
            tonalElevation = 0.dp,
            shadowElevation = 0.dp,
            border = BorderStroke(1.dp, Color.White.copy(alpha = if (active) 0.24f else 0.10f)),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xFF111827).copy(alpha = if (active) 0.035f else 0.015f)),
                contentAlignment = Alignment.CenterStart,
            ) {
                Box(
                    modifier = Modifier
                        .padding(start = 8.dp)
                        .size(width = 4.dp, height = 24.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color.White.copy(alpha = if (active) 0.42f else 0.22f))
                )
            }
        }
    }
}

@Composable
private fun ExpandedHistoryPanel(
    histories: List<History>,
    loading: Boolean,
    closing: Boolean,
    onCollapse: () -> Unit,
    onCollapseFinished: () -> Unit,
    onLoadMore: () -> Unit,
    onDragStart: () -> Unit,
    onDragEnd: () -> Unit,
) {
    val listState = rememberLazyListState()
    var visible by remember { mutableStateOf(false) }
    val panelOffset by animateDpAsState(
        targetValue = if (visible && !closing) 0.dp else 220.dp,
        label = "panelOffset",
    )
    val shouldLoadMore by remember {
        derivedStateOf {
            val lastVisible = listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1
            histories.isNotEmpty() && lastVisible >= histories.lastIndex - 2
        }
    }

    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) {
            onLoadMore()
        }
    }

    LaunchedEffect(Unit) {
        visible = true
    }

    LaunchedEffect(closing) {
        if (closing) {
            visible = false
            delay(180)
            onCollapseFinished()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Transparent)
            .combinedClickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onCollapse,
            ),
        contentAlignment = Alignment.CenterEnd,
    ) {
        Card(
            modifier = Modifier
                .fillMaxHeight()
                .width(190.dp)
                .padding(top = 52.dp, bottom = 52.dp, end = 12.dp)
                .offset(x = panelOffset),
            shape = RoundedCornerShape(22.dp),
            colors = CardDefaults.cardColors(containerColor = PanelBackground),
            elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
            border = BorderStroke(1.dp, PanelStroke),
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 18.dp, top = 16.dp, end = 10.dp, bottom = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "剪贴历史",
                            color = PrimaryText,
                            fontWeight = FontWeight.SemiBold,
                            style = MaterialTheme.typography.titleMedium,
                        )
                        Text(
                            text = "${histories.size} 条记录",
                            color = SecondaryText,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                    IconButton(onClick = onCollapse) {
                        Text(text = "×", color = SecondaryText, style = MaterialTheme.typography.titleLarge)
                    }
                }

                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(histories, key = { it.id }) { history ->
                        HistoryItem(
                            item = history,
                            onDragStart = onDragStart,
                            onDragEnd = onDragEnd,
                        )
                    }

                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(54.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            if (loading) {
                                CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HistoryItem(
    item: History,
    onDragStart: () -> Unit,
    onDragEnd: () -> Unit,
) {
    val context = LocalContext.current
    val view = LocalView.current
    var copied by remember(item.id) { mutableStateOf(false) }
    var pinned by remember(item.id, item.top) { mutableStateOf(item.top) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = ItemBackground),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = BorderStroke(1.dp, Color(0xFFE9EEF5)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .combinedClickable(
                    onClick = {},
                    onLongClick = {
                        startHistoryDrag(context, view, item, onDragStart, onDragEnd)
                    },
                )
                .padding(12.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = item.type.uppercase(),
                    color = Accent,
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(Accent.copy(alpha = 0.10f))
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                )
                Spacer(modifier = Modifier.weight(1f))
                IconButton(
                    modifier = Modifier.size(34.dp),
                    onClick = {
                        pinned = !pinned
                        setHistoryPinned(item, pinned) {
                            pinned = !pinned
                        }
                    },
                ) {
                    Icon(
                        painter = painterResource(
                            if (pinned) R.drawable.baseline_push_pin_24 else R.drawable.outline_push_not_pin_24
                        ),
                        contentDescription = "pin",
                        tint = if (pinned) Accent else SecondaryText,
                    )
                }
                IconButton(
                    modifier = Modifier.size(34.dp),
                    onClick = {
                        copyToClipboard(context, item)
                        copied = true
                    },
                ) {
                    Icon(
                        painter = painterResource(
                            if (copied) R.drawable.baseline_check_24 else R.drawable.outline_content_copy_24
                        ),
                        contentDescription = "copy",
                        tint = if (copied) Color(0xFF16A34A) else SecondaryText,
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            if (item.type.lowercase() == "image") {
                HistoryImage(path = item.content)
            } else {
                Text(
                    text = item.content.take(min(260, item.content.length)),
                    color = PrimaryText,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }

            if (item.time.isNotBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = item.time,
                    color = SecondaryText,
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }

    LaunchedEffect(copied) {
        if (copied) {
            kotlinx.coroutines.delay(700)
            copied = false
        }
    }
}

@Composable
private fun HistoryImage(path: String) {
    val bitmap = remember(path) {
        BitmapFactory.decodeFile(path)?.asImageBitmap()
    }

    if (bitmap == null) {
        Text(
            text = "图片已不可用",
            color = SecondaryText,
            style = MaterialTheme.typography.bodySmall,
        )
    } else {
        Image(
            bitmap = bitmap,
            contentDescription = "image",
            modifier = Modifier
                .fillMaxWidth()
                .height(108.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFFE5E7EB)),
            contentScale = ContentScale.Crop,
        )
    }
}

private fun ignoreNextCopy() {
    MyApplication.clipChannel.invokeMethod("ignoreNextCopy", null)
}

private fun copyToClipboard(context: Context, item: History) {
    val clipboardManager = ContextCompat.getSystemService(
        context,
        ClipboardManager::class.java
    ) as ClipboardManager

    val clipData = if (item.type.lowercase() == "text") {
        ClipData.newPlainText("text", item.content)
    } else {
        getImageClipData(item.content, context)
    }
    ignoreNextCopy()
    clipboardManager.setPrimaryClip(clipData)
}

private fun startHistoryDrag(
    context: Context,
    view: View,
    item: History,
    onDragStart: () -> Unit,
    onDragEnd: () -> Unit,
) {
    val clipData = if (item.type.lowercase() == "image") {
        getImageClipData(item.content, context)
    } else {
        ClipData("text", arrayOf(ClipDescription.MIMETYPE_TEXT_PLAIN), ClipData.Item(item.content))
    }

    view.setOnDragListener { _, event ->
        when (event.action) {
            DragEvent.ACTION_DRAG_STARTED -> onDragStart()
            DragEvent.ACTION_DRAG_ENDED -> {
                onDragEnd()
                view.setOnDragListener(null)
            }
        }
        true
    }

    val flags = if (item.type.lowercase() == "image") {
        View.DRAG_FLAG_GLOBAL or View.DRAG_FLAG_GLOBAL_URI_READ
    } else {
        View.DRAG_FLAG_GLOBAL
    }
    view.startDragAndDrop(clipData, HistoryDragShadowBuilder(view, item), null, flags)
}

private class HistoryDragShadowBuilder(
    view: View,
    private val item: History,
) : DragShadowBuilder(view) {
    private val density = view.resources.displayMetrics.density
    private val width = (density * if (item.type.lowercase() == "image") 160 else 180).toInt()
    private val height = (density * if (item.type.lowercase() == "image") 108 else 72).toInt()
    private val imageBitmap = if (item.type.lowercase() == "image") BitmapFactory.decodeFile(item.content) else null

    private val contentPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        color = android.graphics.Color.rgb(17, 24, 39)
        textSize = view.resources.displayMetrics.scaledDensity * 14
    }
    private val imagePaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

    override fun onProvideShadowMetrics(outShadowSize: Point, outShadowTouchPoint: Point) {
        outShadowSize.set(width, height)
        outShadowTouchPoint.set(width / 2, height / 2)
    }

    override fun onDrawShadow(canvas: Canvas) {
        if (item.type.lowercase() == "image" && imageBitmap != null) {
            val srcRatio = imageBitmap.width.toFloat() / imageBitmap.height.toFloat()
            val dstRatio = width.toFloat() / height.toFloat()
            val src = if (srcRatio > dstRatio) {
                val srcWidth = (imageBitmap.height * dstRatio).toInt()
                val left = (imageBitmap.width - srcWidth) / 2
                android.graphics.Rect(left, 0, left + srcWidth, imageBitmap.height)
            } else {
                val srcHeight = (imageBitmap.width / dstRatio).toInt()
                val top = (imageBitmap.height - srcHeight) / 2
                android.graphics.Rect(0, top, imageBitmap.width, top + srcHeight)
            }
            canvas.drawBitmap(imageBitmap, src, RectF(0f, 0f, width.toFloat(), height.toFloat()), imagePaint)
            return
        }

        val preview = item.content.replace(Regex("\\s+"), " ").take(84)
        val firstLine = preview.take(24)
        val secondLine = preview.drop(24).take(24)
        val thirdLine = preview.drop(48).take(24)
        val baseY = contentPaint.textSize
        canvas.drawText(firstLine, 0f, baseY, contentPaint)
        if (secondLine.isNotBlank()) {
            canvas.drawText(secondLine, 0f, baseY + contentPaint.textSize + 8, contentPaint)
        }
        if (thirdLine.isNotBlank()) {
            canvas.drawText(thirdLine, 0f, baseY + (contentPaint.textSize + 8) * 2, contentPaint)
        }
    }
}

private fun getImageClipData(path: String, context: Context): ClipData {
    val file = File(path)
    val uri: Uri = FileProvider.getUriForFile(
        context,
        context.packageName + ".FileProvider",
        file
    )
    return ClipData(
        ClipDescription("image", arrayOf("image/*")),
        ClipData.Item(uri)
    )
}

private fun setHistoryPinned(item: History, pinned: Boolean, onFailed: () -> Unit) {
    item.top = pinned
    MyApplication.clipChannel.invokeMethod(
        "setTop",
        mapOf("id" to item.id, "top" to item.top),
        object : Result {
            override fun success(result: Any?) {
                if (result != true) {
                    item.top = !item.top
                    onFailed()
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                item.top = !item.top
                onFailed()
            }

            override fun notImplemented() {
                item.top = !item.top
                onFailed()
            }
        }
    )
}
