import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/history/widgets/filter/filter_detail.dart';
import 'package:clipshare/features/history/widgets/filter/filter_type_segmented.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/search_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:window_manager/window_manager.dart';

/// 历史过滤器：受控纯 widget。
///
/// 只根据 [value] 与筛选数据源渲染，并通过回调上报变化；不持有任何业务状态，
/// 也不依赖状态管理库，便于主窗口（searchProvider）与弹窗各自接入。
class HistoryFilter extends StatelessWidget {
  /// 当前筛选条件。
  final SearchFilter value;

  /// 可筛选设备（本机在前）。
  final List<Device> devices;

  /// 全部标签名。
  final List<String> tags;

  /// 全部来源（应用）信息。
  final List<AppInfo> sources;

  final bool showFillColor;
  final bool showSearchRow;
  final bool showTypeRow;

  /// 筛选条件变化回调。
  final ValueChanged<SearchFilter> onChanged;

  /// 触发搜索。
  final VoidCallback onSearch;

  /// 导出回调；为 null 时不展示导出按钮。
  final VoidCallback? onExport;

  /// 宽屏打开更多筛选面板的回调；为 null 时回退底部弹窗。
  final void Function(Widget detail)? onShowDetail;

  const HistoryFilter({
    super.key,
    required this.value,
    required this.devices,
    required this.tags,
    required this.sources,
    required this.showFillColor,
    required this.onChanged,
    required this.onSearch,
    this.showSearchRow = true,
    this.showTypeRow = true,
    this.onExport,
    this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        children: [
          if (showSearchRow)
            HistoryFilterSearchRow(
              value: value,
              devices: devices,
              tags: tags,
              sources: sources,
              showFillColor: showFillColor,
              onChanged: onChanged,
              onSearch: onSearch,
              onExport: onExport,
              onShowDetail: onShowDetail,
            ),
          if (showTypeRow)
            HistoryFilterTypeRow(
              value: value,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

/// 搜索输入行：搜索框、更多筛选按钮、导出按钮。
class HistoryFilterSearchRow extends StatefulWidget {
  final SearchFilter value;
  final List<Device> devices;
  final List<String> tags;
  final List<AppInfo> sources;
  final bool showFillColor;
  final ValueChanged<SearchFilter> onChanged;
  final VoidCallback onSearch;
  final VoidCallback? onExport;
  final void Function(Widget detail)? onShowDetail;

  const HistoryFilterSearchRow({
    super.key,
    required this.value,
    required this.devices,
    required this.tags,
    required this.sources,
    required this.showFillColor,
    required this.onChanged,
    required this.onSearch,
    this.onExport,
    this.onShowDetail,
  });

  @override
  State<HistoryFilterSearchRow> createState() => _HistoryFilterSearchRowState();
}

class _HistoryFilterSearchRowState extends State<HistoryFilterSearchRow> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value.content);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant HistoryFilterSearchRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部重置搜索条件时同步输入框；避免覆盖用户正在输入的内容。
    if (widget.value.content != oldWidget.value.content &&
        widget.value.content != _textController.text) {
      _textController.text = widget.value.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 是否存在搜索框以外的筛选条件（用于高亮更多筛选按钮）。
  bool get _hasMoreCondition {
    final f = widget.value;
    return f.tags.isNotEmpty ||
        f.devIds.isNotEmpty ||
        f.onlyNoSync ||
        f.endDate.isNotEmpty ||
        f.startDate.isNotEmpty ||
        f.appIds.isNotEmpty;
  }

  /// 打开更多筛选面板：宽屏走外部注入的 [HistoryFilterSearchRow.onShowDetail]，
  /// 否则弹出底部弹窗。
  void _openFilterDetail(BuildContext context) {
    final detail = FilterDetailSheet(
      value: widget.value,
      devices: widget.devices,
      tags: widget.tags,
      sources: widget.sources,
      onChanged: widget.onChanged,
      onConfirm: widget.onSearch,
      onClose: null,
    );
    if (!context.isCompactScreen) {
      widget.onShowDetail?.call(detail);
      return;
    }
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      builder: (sheetContext) => FilterDetailSheet(
        value: widget.value,
        devices: widget.devices,
        tags: widget.tags,
        sources: widget.sources,
        onChanged: widget.onChanged,
        onConfirm: widget.onSearch,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                autofocus: false,
                onTap: () {
                  // 弹窗 WS_EX_NOACTIVATE 不激活、收不到键盘输入（搜索框无法打字）。
                  windowManager.focus();
                },
                onChanged: (text) =>
                    widget.onChanged(widget.value.copyWith(content: text)),
                textAlignVertical: TextAlignVertical.center,
                decoration: context.noneBorderInputDecoration.copyWith(
                  fillColor: widget.showFillColor ? null : Colors.transparent,
                  hintText: TranslationKey.search.tr,
                  suffixIcon: Tooltip(
                    message: TranslationKey.search.tr,
                    child: IconButton(
                      onPressed: () {
                        widget.onChanged(
                          widget.value.copyWith(content: _textController.text),
                        );
                        widget.onSearch();
                        _focusNode.requestFocus();
                      },
                      icon: const Icon(
                        Icons.search_rounded,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                onTapOutside: (_) => _focusNode.unfocus(),
                onSubmitted: (value) {
                  widget.onChanged(widget.value.copyWith(content: value));
                  _focusNode.requestFocus();
                  widget.onSearch();
                },
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 5, right: 5),
            child: IconButton(
              onPressed: () => _openFilterDetail(context),
              tooltip: TranslationKey.moreFilter.tr,
              icon: Icon(
                _hasMoreCondition
                    ? Icons.playlist_add_check_outlined
                    : Icons.menu_rounded,
                color: _hasMoreCondition ? Colors.blueAccent : null,
              ),
            ),
          ),
          if (widget.onExport != null)
            Container(
              margin: const EdgeInsets.only(left: 5, right: 5),
              child: IconButton(
                onPressed: widget.onExport,
                tooltip: TranslationKey.export2Excel.tr,
                icon: const Icon(
                  MdiIcons.export,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 内容类型筛选行。
class HistoryFilterTypeRow extends StatelessWidget {
  final SearchFilter value;
  final ValueChanged<SearchFilter> onChanged;

  const HistoryFilterTypeRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 5),
      child: FilterTypeSegmented(
        selectedType: value.type,
        onSelected: (type) {
          if (value.type.label == type.label) {
            return;
          }
          onChanged(value.copyWith(type: type));
        },
      ),
    );
  }
}
