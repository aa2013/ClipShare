import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/widgets/clip/clip_native_drag_item_wrapper.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip/app_icon.dart';
import 'package:clipshare/app/widgets/clip/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/clip/clip_simple_data_footer.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';

///多窗口下一些数据拿不到所以单独写一个
class ClipDataCardCompact extends StatefulWidget {
  static const double selectedBorderWidth = 2;
  static const double selectedBorderRadius = 12;

  final String devName;
  final ClipData clip;
  final void Function(int id, bool isTop) onTopChanged;
  final void Function(int id) onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onMoreActionsTap;
  final VoidCallback onCopied;
  final bool selectMode;
  final bool selected;
  ///开启后单击条目直接复制粘贴（Win+V弹窗场景，由父窗口传入，避免子窗口isolate无ConfigService）
  final bool clickToPaste;

  const ClipDataCardCompact({
    super.key,
    required this.clip,
    required this.devName,
    required this.onTopChanged,
    required this.onDelete,
    required this.onCopied,
    this.onTap,
    this.onLongPress,
    this.onToggleSelected,
    this.onMoreActionsTap,
    this.selectMode = false,
    this.selected = false,
    this.clickToPaste = false,
  });

  @override
  State<StatefulWidget> createState() => _ClipDataCardCompactState();
}

class _ClipDataCardCompactState extends State<ClipDataCardCompact> with TickerProviderStateMixin {
  final multiWindowService = Get.find<MultiWindowChannelService>();
  late final SlidableController _slidableController = SlidableController(this);
  bool _slided = false;
  /// 正在粘贴的条目 id 集合（static 跨卡片共享）：单击粘贴模式下防重入。
  /// 用 Set 做 test-and-set（add 返回 false 即已在粘贴中）——单槽 int 有两个洞：
  /// ①先完成的条目会把锁清掉，放行仍在飞的后一条；②交错点不同条目时同一条可重入。
  static final _pastingIds = <int>{};

  ///右键菜单
  void showMenu(Offset? position, BuildContext context) {
    final clip = widget.clip;
    final menu = ContextMenu(
      entries: [
        MenuItem(
          label: clip.data.top
              ? TranslationKey.cancelTopUp.tr
              : TranslationKey.topUp.tr,
          icon: clip.data.top ? Icons.push_pin : Icons.push_pin_outlined,
          onSelected: () {
            var id = clip.data.id;
            //置顶取反
            var isTop = !clip.data.top;
            widget.onTopChanged.call(id, isTop); // 修改这里
            setState(() {
              clip.data.top = isTop;
            });
          },
        ),
        MenuItem(
          label: TranslationKey.copyContent.tr,
          icon: Icons.copy,
          onSelected: () {
            if (clip.isFile) {
              OpenFile.open(clip.data.content);
              return;
            }
            multiWindowService.copy(0, clip.data.id);
            Global.showSnackBarSuc(
              context: context,
              text: TranslationKey.copySuccess.tr,
            );
          },
        ),
        MenuItem(
          label: TranslationKey.delete.tr,
          icon: Icons.delete,
          onSelected: () {
            widget.onDelete.call(clip.data.id);
          },
        ),
      ],
      position: position,
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
  }

  ///复制并粘贴到上一个窗口，单击粘贴与双击粘贴共用
  Future<void> _copyAndPaste() async {
    final clip = widget.clip;
    // test-and-set：同一条目已在粘贴中则丢弃（双击=两次 onTap 的原始缺陷）；
    // 不同条目并行放行（置顶连粘），跨条目顺序由主 isolate 的 _copyChain 保证
    if (!_pastingIds.add(clip.data.id)) return;
    try {
      if (clip.isFile) {
        await OpenFile.open(clip.data.content);
        return;
      }
      await multiWindowService.copy(0, clip.data.id);
      // 粘贴已完成（copy await 返回后粘贴动作已执行完），等待短暂延迟后关闭弹窗。
      await Future.delayed(300.ms);
      widget.onCopied.call();
    } catch (e) {
      // 粘贴失败（如窗口引用失效，copy 是 IPC 会 reject）：不向上抛，
      // 否则调用点未 await 会变成 unhandled async error。
      debugPrint("copyAndPaste failed: $e");
    } finally {
      _pastingIds.remove(clip.data.id);
    }
  }

  @override
  void initState() {
    super.initState();
    _slidableController.animation.addListener(() {
      _slided = _slidableController.animation.value != 0;
    });
  }

  @override
  void dispose() {
    _slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final child = SizedBox(
      height: 150,
      child: Card(
        elevation: 0,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            if (_slided) {
              _slidableController.close();
              return;
            }
            if (widget.selectMode) {
              widget.onTap?.call();
              return;
            }
            //开启单击粘贴时，单击直接复制并粘贴上屏
            if (widget.clickToPaste) {
              _copyAndPaste();
            }
          },
          onDoubleTap: widget.selectMode || widget.clickToPaste
              ? null
              : () async {
                  await _copyAndPaste();
                },
          onLongPress: widget.onLongPress,
          onSecondaryTapDown: (details) {
            showMenu(details.globalPosition - const Offset(0, 70), context);
          },
          borderRadius: BorderRadius.circular(
            ClipDataCardCompact.selectedBorderRadius,
          ),
          child: Container(
            margin: widget.selectMode && widget.selected
                ? null
                : const EdgeInsets.all(ClipDataCardCompact.selectedBorderWidth),
            decoration: widget.selectMode && widget.selected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      width: ClipDataCardCompact.selectedBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(
                      ClipDataCardCompact.selectedBorderRadius,
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (clip.data.source != null)
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          child: AppIcon(appId: clip.data.source!),
                        ),
                      RoundedChip(
                        avatar: const Icon(Icons.devices_rounded),
                        backgroundColor: const Color(0x1a000000),
                        label: Text(
                          widget.devName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: ClipSimpleDataContent(
                      clip: clip,
                      imgOnlyView: true,
                      imgSingleView: true,
                    ),
                  ),
                  const SizedBox(height: 1),
                  ClipSimpleDataFooter(clip: clip),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        ClipDataCardCompact.selectedBorderRadius,
      ),
      child: _buildSlidable(
        widget.selectMode
            ? child
            : ClipNativeDragItemWrapper(
                clip: widget.clip,
                child: child,
              ),
      ),
    );
  }

  /// 紧凑卡片在多选模式下复用滑动补选入口，保持与主窗体一致的区间补选手势。
  Widget _buildSlidable(Widget child) {
    return Slidable(
      controller: _slidableController,
      key: ValueKey(widget.clip.data.id),
      startActionPane: ActionPane(
        motion: const SizedBox.shrink(),
        extentRatio: 0.01,
        dismissible: DismissiblePane(
          onDismissed: () {},
          dismissThreshold: 0.1,
          confirmDismiss: () {
            _slidableController.close();
            widget.onToggleSelected?.call();
            return Future.value(false);
          },
        ),
        children: const [],
      ),
      endActionPane: widget.selectMode
          ? null
          : ActionPane(
              extentRatio: 0.3,
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    final onMoreActionsTap = widget.onMoreActionsTap;
                    if (onMoreActionsTap != null) {
                      onMoreActionsTap();
                    } else {
                      showMenu(null, context);
                    }
                  },
                  autoClose: true,
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  icon: Icons.menu,
                  borderRadius: BorderRadius.circular(
                    ClipDataCardCompact.selectedBorderRadius,
                  ),
                  label: TranslationKey.moreActions.tr,
                ),
              ],
            ),
      child: child,
    );
  }
}
