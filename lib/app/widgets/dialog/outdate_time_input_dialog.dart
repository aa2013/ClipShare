import 'package:clipshare/app/data/enums/time_span_unit.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OutdateTimeInputDialog extends StatefulWidget {
  final void Function(int seconds) onConfirm;
  final int initValue;

  const OutdateTimeInputDialog({
    super.key,
    required this.initValue,
    required this.onConfirm,
  });

  @override
  State<StatefulWidget> createState() => _OutdateTimeInputDialogState();
}

class _OutdateTimeInputDialogState extends State<OutdateTimeInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final Map<TimeSpanUnit, String> unitMap = {};

  TimeSpanUnit _selectedUnit = TimeSpanUnit.day;

  int get numericValue => double.tryParse(_controller.text)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    for (var unit in TimeSpanUnit.values) {
      unitMap[unit] = unit.label;
    }
    _selectedUnit = TimeSpanUnit.parse(widget.initValue);
    var val = widget.initValue / _selectedUnit.magnification;
    if ("${val.toInt()}.0" == val.toString()) {
      _controller.text = val.toInt().toString();
    } else {
      _controller.text = val.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildInput(BuildContext context) {
    return Row(
      children: [
        // 输入框
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              visualDensity: VisualDensity.compact,
              hintText: TranslationKey.pleaseInput.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // 只允许数字
            ],
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        // 单位选择
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TimeSpanUnit>(
              value: _selectedUnit,
              items: unitMap.keys.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(unit.label),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(TranslationKey.syncOutDateSettingTitle.tr),
      content: buildInput(context),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: Get.back, child: Text(TranslationKey.dialogCancelText.tr)),
            TextButton(
              onPressed: () {
                widget.onConfirm(numericValue * _selectedUnit.magnification);
                Get.back();
              },
              child: Text(TranslationKey.dialogConfirmText.tr),
            ),
          ],
        ),
      ],
    );
  }
}
