import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';

import '../base/radio_group.dart' as rg;

class SingleSelectDialog<T> extends StatelessWidget {
  final void Function(T value) onSelected;
  final List<rg.RadioData<T>> selections;
  final T defaultValue;

  const SingleSelectDialog._private({
    super.key,
    required this.onSelected,
    required this.defaultValue,
    required this.selections,
  });

  static DialogController show<T>({
    required BuildContext context,
    required void Function(T value) onSelected,
    required T defaultValue,
    required List<rg.RadioData<T>> selections,
    required Widget title,
    void Function()? onCancel,
    String? cancelText,
    List<Widget>? actions,
  }) {
    return dialogManager.open(
      context,
      AlertDialog(
        title: title,
        content: SingleSelectDialog._private(
          onSelected: onSelected,
          defaultValue: defaultValue,
          selections: selections,
        ),
        actions:
            actions ??
            [
              TextButton(
                onPressed: () {
                  if (onCancel == null) {
                    Navigator.pop(context);
                  } else {
                    onCancel.call();
                  }
                },
                child: Text(cancelText ?? TranslationKey.dialogCancelText.tr),
              ),
            ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return rg.RadioGroup<T>(
      data: selections,
      defaultValue: defaultValue,
      onSelected: onSelected,
    );
  }
}
