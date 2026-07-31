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
  });

  @override
  State<StatefulWidget> createState() => _ClipDataCardCompactState();
}

class _ClipDataCardCompactState extends State<ClipDataCardCompact> with TickerProviderStateMixin {
  final multiWindowService = Get.find<MultiWindowChannelService>();
  late final SlidableController _slidableController = SlidableController(this);
  bool _slided = false;

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
            }
          },
          onDoubleTap: widget.selectMode
              ? null
              : () async {
                  if (clip.isFile) {
                    await OpenFile.open(clip.data.content);
                    return;
                  }
                  await multiWindowService.copy(0, clip.data.id);
                  Global.showSnackBarSuc(
                    context: context,
                    text: TranslationKey.copySuccess.tr,
                  );
                  await Future.delayed(1000.ms);
                  widget.onCopied.call();
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
