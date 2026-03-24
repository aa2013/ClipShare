import 'package:clipshare/app/data/models/old_rule.dart';
import 'package:clipshare/app/modules/views/settings/rule_item.dart';
import 'package:flutter/material.dart';

class RuleImportPreview extends StatefulWidget {
  final void Function() onCancel;
  final void Function(List<OldRule> rules) onConfirm;
  final List<OldRule> data;

  const RuleImportPreview({
    super.key,
    required this.data,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<StatefulWidget> createState() => _RuleImportPreview();
}

class _RuleImportPreview extends State<RuleImportPreview> {
  final Set<OldRule> selectedList = {};

  @override
  void initState() {
    super.initState();
    selectedList.addAll(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 450,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.data.length,
              itemBuilder: (context, i) {
                final rule = widget.data[i];
                return RuleItem(
                  backgroundColor: Colors.transparent,
                  selected: selectedList.contains(rule),
                  rule: widget.data[i],
                  selectionMode: true,
                  action: const SizedBox.shrink(),
                  onTap: () {
                    if (selectedList.contains(rule)) {
                      selectedList.remove(rule);
                    } else {
                      selectedList.add(rule);
                    }
                    setState(() {});
                  },
                  onSelectionChange: (v) {
                    if (v) {
                      selectedList.add(rule);
                    } else {
                      selectedList.remove(rule);
                    }
                    setState(() {});
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: () {
                  widget.onConfirm(selectedList.toList(growable: false));
                },
                child: const Text("导入"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
