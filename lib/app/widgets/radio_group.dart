import 'package:flutter/material.dart';

class RadioData<T> {
  final T value;
  final String label;
  Widget? widget;

  RadioData({
    required this.value,
    required this.label,
    this.widget,
  });
}

class RadioGroup<T> extends StatefulWidget {
  final List<RadioData<T>> data;
  final Axis direction;
  final T defaultValue;
  final void Function(T value) onSelected;

  const RadioGroup({
    super.key,
    required this.data,
    this.direction = Axis.vertical,
    required this.defaultValue,
    required this.onSelected,
  });

  @override
  State<StatefulWidget> createState() {
    return _RadioGroupState<T>();
  }
}

class _RadioGroupState<T> extends State<RadioGroup<T>> {
  late T groupValue;

  @override
  Widget build(BuildContext context) {
    groupValue = widget.defaultValue;
    List<RadioListTile<T>> widgets = List.generate(
      widget.data.length,
      (index) {
        var v = widget.data[index].value;
        return RadioListTile<T>(
          value: v,
          groupValue: groupValue,
          selected: groupValue == v,
          title: widget.data[index].widget ?? Text(widget.data[index].label),
          onChanged: (T? value) {
            groupValue = v;
            setState(() {});
            widget.onSelected(value as T);
          },
        );
      },
    );
    return widget.direction == Axis.horizontal
        ? Row(children: widgets)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets,
          );
  }
}
