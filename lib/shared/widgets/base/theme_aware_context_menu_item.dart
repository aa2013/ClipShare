import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

/// 使用当前应用主题文本样式的右键菜单项。
///
/// 第三方 [MenuItem] 会重新创建 [DefaultTextStyle]，导致主题中的字体族丢失。
/// 这里复用第三方菜单项的选择和焦点行为，只替换文字样式的构建方式。
final class MyMenuItem extends ContextMenuItem<void> {
  final String label;
  final IconData? icon;
  final BoxConstraints? constraints;
  final Color? color;

  const MyMenuItem({
    required this.label,
    this.icon,
    this.constraints,
    this.color,
    super.onSelected,
    super.enabled,
  });

  @override
  Widget builder(
    BuildContext context,
    ContextMenuState menuState, [
    FocusNode? focusNode,
  ]) {
    final isFocused = menuState.focusedEntry == this;
    final theme = Theme.of(context);
    final background = theme.colorScheme.surface;
    final focusedBackground = theme.colorScheme.surfaceContainer;
    final normalTextColor = Color.alphaBlend(
      (color ?? theme.colorScheme.onSurface).withValues(alpha: 0.7),
      background,
    );
    final focusedTextColor = color ?? theme.colorScheme.onSurface;
    final disabledTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.2);
    final foregroundColor = !enabled
        ? disabledTextColor
        : isFocused
            ? focusedTextColor
            : normalTextColor;
    final textStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: foregroundColor,
      height: 1.0,
    );

    return ConstrainedBox(
      constraints: constraints ?? const BoxConstraints.expand(height: 32.0),
      child: Material(
        color: !enabled
            ? Colors.transparent
            : isFocused
                ? focusedBackground
                : background,
        borderRadius: BorderRadius.circular(4.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: !enabled ? null : () => handleItemSelection(context),
          canRequestFocus: false,
          child: DefaultTextStyle(
            style: textStyle,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 32.0,
                  child: Icon(
                    icon,
                    size: 16.0,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8.0),
                SizedBox.square(
                  dimension: 32.0,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Icon(
                      isSubmenuItem ? Icons.arrow_right : null,
                      size: 16.0,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
