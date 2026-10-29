import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:flutter/material.dart';

/// 应用选择页共享搜索栏：收起时展示标题（可选），展开时展示搜索输入框。
///
/// 小屏放在标题栏、大屏放在 [AppSelectionForm] 顶部，过滤逻辑由外部
/// 通过 [onSearchChanged] 统一处理，避免两处重复实现搜索 UI。
class AppSelectionSearchBar extends StatefulWidget {
  /// 收起时显示的标题文字；为空时仅展示放大镜按钮。
  final String? placeholder;

  /// 首次构建时是否直接展开输入框。
  final bool initiallyExpanded;

  /// 输入内容变化时回调（清空时回调空字符串）。
  final ValueChanged<String> onSearchChanged;

  const AppSelectionSearchBar({
    super.key,
    this.placeholder,
    this.initiallyExpanded = false,
    required this.onSearchChanged,
  });

  @override
  State<AppSelectionSearchBar> createState() => _AppSelectionSearchBarState();
}

class _AppSelectionSearchBarState extends State<AppSelectionSearchBar> {
  final _textController = TextEditingController();

  late bool _showTextInput = widget.initiallyExpanded;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 展开输入框并聚焦。
  void _expand() {
    setState(() {
      _showTextInput = true;
    });
  }

  /// 收起输入框并清空搜索关键字。
  void _collapseAndClear() {
    _textController.clear();
    widget.onSearchChanged('');
    setState(() {
      _showTextInput = false;
    });
  }

  /// 仅清空输入内容与搜索关键字，输入框保持展开状态。
  void _clearOnly() {
    _textController.clear();
    widget.onSearchChanged('');
    setState(() {});
  }

  /// 生成胶囊形圆角边框样式：仅用于圆角，不绘制描边。
  OutlineInputBorder _pillBorder() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showTextInput ? _buildInputField() : _buildCollapsed();
  }

  /// 收起态：显示占位标题（可选）与放大镜按钮，点击后展开输入框。
  Widget _buildCollapsed() {
    final placeholder = widget.placeholder;
    if (placeholder == null) {
      return IconButton(
        tooltip: TranslationKey.search.tr,
        onPressed: _expand,
        icon: const Icon(Icons.search),
      );
    }
    return InkWell(
      onTap: _expand,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(placeholder),
          const Icon(Icons.search),
        ],
      ),
    );
  }

  /// 展开态：搜索输入框，右侧提供清除按钮。
  Widget _buildInputField() {
    // 大屏下对齐标签管理的胶囊填充搜索框样式。
    if (!context.isCompactScreen) {
      final colorScheme = context.currentTheme.colorScheme;
      return TextField(
        controller: _textController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colorScheme.primary.withValues(alpha: 0.06),
          hintText: TranslationKey.search.tr,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _textController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: TranslationKey.close.tr,
                  onPressed: _clearOnly,
                ),
          border: _pillBorder(),
          enabledBorder: _pillBorder(),
          focusedBorder: _pillBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
        onChanged: (text) {
          widget.onSearchChanged(text);
          // 刷新清除按钮的可见性
          setState(() {});
        },
      );
    }
    return TextField(
      controller: _textController,
      autofocus: true,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        hintText: TranslationKey.search.tr,
        hintStyle: const TextStyle(fontSize: 13),
        border: InputBorder.none,
        suffixIcon: IconButton(
          onPressed: _collapseAndClear,
          tooltip: TranslationKey.close.tr,
          icon: const Icon(Icons.clear),
        ),
      ),
      onChanged: widget.onSearchChanged,
    );
  }
}