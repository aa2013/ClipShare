import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:flutter/material.dart';

class RuleSettingAddDialog extends StatefulWidget {
  final Function(Rule) onChange;
  final String labelText;
  final String hintText;

  final Rule? initData;

  const RuleSettingAddDialog({
    super.key,
    required this.onChange,
    required this.labelText,
    required this.hintText,
    this.initData,
  });

  @override
  State<StatefulWidget> createState() {
    return _RuleSettingAddDialogState();
  }
}

class _RuleSettingAddDialogState extends State<RuleSettingAddDialog> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  final TextEditingController _verifyController = TextEditingController();
  String _tagName = "";
  String _rule = "";
  bool _showTagErr = false;
  bool _showRuleErr = false;
  bool _showVerifyErr = false;
  bool _useVerify = false;

  void _onChange() {
    widget.onChange(Rule(name: _tagName, rule: _rule));
  }

  @override
  void initState() {
    super.initState();
    if (widget.initData == null) return;
    _tagName = _tagController.text = widget.initData?.name ?? "";
    _rule = _ruleController.text = widget.initData?.rule ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tagController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              errorText: _showTagErr ? "${widget.labelText}${TranslationKey.cannotEmpty.tr}" : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (txt) {
              _tagName = txt;
              setState(() {
                _showTagErr = txt == "";
              });
              _onChange();
            },
          ),
          const SizedBox(
            height: 10
          ),
          TextField(
            controller: _ruleController,
            decoration: InputDecoration(
              labelText: TranslationKey.ruleAddDialogLabel.tr,
              hintText: TranslationKey.ruleAddDialogHint.tr,
              errorText: _showRuleErr ? TranslationKey.ruleCannotEmpty.tr : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (txt) {
              _rule = txt;
              _onChange();
              setState(() {
                _showRuleErr = txt == "";
              });
              setState(() {
                try {
                  _showVerifyErr = !_verifyController.text.matchRegExp(_rule);
                } catch (e) {
                  _showVerifyErr = true;
                }
              });
            },
          ),
          const SizedBox(
            height: 10
          ),
          CheckboxListTile(
            title: Text(TranslationKey.validationTesting.tr),
            value: _useVerify,
            onChanged: (v) {
              setState(() {
                _useVerify = v ?? false;
              });
            },
          ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _useVerify,
            child: TextField(
              controller: _verifyController,
              decoration: InputDecoration(
                labelText: _showVerifyErr ? TranslationKey.validationFailed.tr : TranslationKey.verify.tr,
                hintText: TranslationKey.pleaseInput.tr,
                border: OutlineInputBorder(
                  borderSide: _showVerifyErr
                      ? const BorderSide(color: Colors.red)
                      : const BorderSide(),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: _showVerifyErr
                      ? const BorderSide(color: Colors.red)
                      : const BorderSide(),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: _showVerifyErr
                      ? const BorderSide(color: Colors.red)
                      : const BorderSide(),
                ),
                labelStyle:
                    TextStyle(color: _showVerifyErr ? Colors.red : null),
              ),
              onChanged: (txt) {
                setState(() {
                  try {
                    _showVerifyErr = !txt.matchRegExp(_rule);
                  } catch (e) {
                    _showVerifyErr = true;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
