import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';

class CheckboxData<T> {
  final T value;
  final String text;
  final bool isDefault;

  const CheckboxData({
    required this.value,
    required this.text,
    this.isDefault = false,
  });
}

class MultiSelectDialog<T> extends StatefulWidget {
  final void Function(List<T> values) onSelected;
  final List<CheckboxData<T>> selections;
  final List<T> defaultValues;
  final int minSelectedCnt;

  const MultiSelectDialog._private({
    super.key,
    required this.onSelected,
    required this.defaultValues,
    required this.selections,
    this.minSelectedCnt = 1,
  });

  static DialogController show<T>({
    required BuildContext context,
    required void Function(List<T> values) onSelected,
    required List<T> defaultValues,
    required List<CheckboxData<T>> selections,
    required Widget title,
    int minSelectedCnt = 1,
    void Function()? onCancel,
    bool dismissable = false,
    String? cancelText,
    String? confirmText,
  }) {
    return Global.showDialog(
      context,
      _MultiSelectDialogContent<T>(
        title: title,
        selections: selections,
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

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogContent<T> extends StatefulWidget {
  final Widget title;
  final List<CheckboxData<T>> selections;
  final List<T> initialSelectedValues;
  final void Function(List<T> values) onConfirmed;
  final void Function()? onCancel;
  final String? cancelText;
  final String? confirmText;
  final int minSelectedCnt;

  const _MultiSelectDialogContent({
    required this.title,
    required this.selections,
    required this.initialSelectedValues,
    required this.onConfirmed,
    this.minSelectedCnt = 1,
    this.onCancel,
    this.cancelText,
    this.confirmText,
  });

  @override
  State<_MultiSelectDialogContent<T>> createState() => _MultiSelectDialogContentState<T>();
}

class _MultiSelectDialogContentState<T> extends State<_MultiSelectDialogContent<T>> {
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.initialSelectedValues);

    // 确保至少选择 minSelectedCnt 项
    final minCnt = widget.minSelectedCnt;
    for (var item in widget.selections) {
      if (_selectedValues.length < minCnt) {
        _selectedValues.add(item.value);
      } else {
        break;
      }
    }
  }

  void _toggleSelection(T value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        if (_selectedValues.length <= widget.minSelectedCnt) {
          return;
        }
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedValues.isNotEmpty) {
      widget.onConfirmed(_selectedValues);
      Navigator.pop(context);
    }
  }

  void _cancel() {
    if (widget.onCancel == null) {
      Navigator.pop(context);
    } else {
      widget.onCancel!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.selections.map((item) {
              return CheckboxListTile(
                value: _selectedValues.contains(item.value),
                onChanged: (bool? selected) {
                  _toggleSelection(item.value);
                },
                title: Text(item.text),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text(widget.cancelText ?? TranslationKey.dialogCancelText.tr),
        ),
        TextButton(
          onPressed: _confirmSelection,
          child: Text(widget.confirmText ?? TranslationKey.dialogConfirmText.tr),
        ),
      ],
    );
  }
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.defaultValues);
  }

  void _toggleSelection(T value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        if (_selectedValues.length > 1) {
          _selectedValues.remove(value);
        }
      } else {
        _selectedValues.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.selections.map((item) {
        return CheckboxListTile(
          value: _selectedValues.contains(item.value),
          onChanged: (bool? selected) {
            _toggleSelection(item.value);
          },
          title: Text(item.text),
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
