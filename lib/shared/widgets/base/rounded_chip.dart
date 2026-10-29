import 'package:flutter/material.dart';

class RoundedChip extends RawChip {
  /// 项目统一圆角 chip；边框交给 ChipTheme 控制，调用点显式传 side 时仍可覆盖。
  const RoundedChip({
    super.key,
    super.avatar,
    required super.label,
    super.labelStyle,
    super.labelPadding,
    super.onDeleted,
    super.deleteIconColor,
    super.deleteButtonTooltipMessage,
    super.side,
    super.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(50)),
    ),
    super.clipBehavior = Clip.none,
    super.focusNode,
    super.autofocus = false,
    super.color,
    super.backgroundColor,
    super.padding,
    super.visualDensity = const VisualDensity(
      horizontal: VisualDensity.minimumDensity,
      vertical: VisualDensity.minimumDensity,
    ),
    super.materialTapTargetSize,
    super.elevation,
    super.shadowColor,
    super.surfaceTintColor,
    super.iconTheme,
    super.onPressed,
    super.deleteIcon,
    super.avatarBorder,
    super.checkmarkColor,
    super.defaultProperties,
    super.disabledColor,
    super.isEnabled,
    super.onSelected,
    super.pressElevation,
    super.selected,
    super.selectedColor,
    super.selectedShadowColor,
    super.showCheckmark,
    super.tapEnabled,
    super.tooltip,
  }) : super();
}
