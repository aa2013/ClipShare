import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/radio_group.dart';
import 'package:flutter/material.dart';

class SingleSelectDialog<T> extends StatelessWidget {
  final void Function(T value) onSelected;
  final List<RadioData<T>> selections;
  final T defaultValue;

  const SingleSelectDialog._private({
    super.key,
    required this.onSelected,
    required this.defaultValue,
    required this.selections,
  });

  static void show<T>({
    required BuildContext context,
    required void Function(T value) onSelected,
    required T defaultValue,
    required List<RadioData<T>> selections,
    required Widget title,
    void Function()? onCancel,
    String? cancelText,
    List<Widget>? actions,
  }) {
    Global.showDialog(
      context,
      AlertDialog(
        title: title,
        content: SingleSelectDialog._private(
          onSelected: onSelected,
          defaultValue: defaultValue,
          selections: selections,
        ),
        actions: actions ??
            [
              TextButton(
                onPressed: () {
                  if (onCancel == null) {
                    Navigator.pop(context);
                  } else {
                    onCancel.call();
                  }
                },
                child: Text(cancelText ?? "取消"),
              ),
            ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      data: selections,
      defaultValue: defaultValue,
      onSelected: onSelected,
    );
  }
}
