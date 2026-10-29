import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/widgets/dialogs/multi_select_dialog.dart';
import 'package:flutter/widgets.dart';

DialogController showMultiSelectDialog<T>({
  required BuildContext context,
  required void Function(List<T> values) onSelected,
  required List<T> defaultValues,
  required List<CheckboxData<T>> selections,
  required Widget title,
  TextStyle? textStyle,
  int minSelectedCnt = 1,
  void Function()? onCancel,
  bool dismissable = false,
  String? cancelText,
  String? confirmText,
}) {
  return dialogManager.open(
    context,
    MultiSelectDialogContent<T>(
      title: title,
      selections: selections,
      textStyle: textStyle,
      initialSelectedValues: defaultValues,
      onConfirmed: onSelected,
      onCancel: onCancel,
      cancelText: cancelText,
      confirmText: confirmText,
      minSelectedCnt: minSelectedCnt,
    ),
    dismissible: dismissable,
  );
}
