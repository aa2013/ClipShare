import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/constants/assets.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'environment_selection_card.dart';

class EnvironmentSelections extends StatefulWidget {
  final void Function(EnvironmentType? selected) onSelected;

  /// 外部已选中的工作模式，用于初始展示与外部变更后的回显。
  final EnvironmentType? selected;

  const EnvironmentSelections({
    super.key,
    required this.onSelected,
    this.selected,
  });

  @override
  State<StatefulWidget> createState() => _EnvironmentSelectionsState();
}

class _EnvironmentSelectionsState extends State<EnvironmentSelections> with AutomaticKeepAliveClientMixin, ClipboardListener {
  EnvironmentType? _selectedEnv;
  bool requesting = false;
  EnvironmentType? requestingPerm;
  DialogController? loadingController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedEnv = widget.selected;
    clipboardManager.addListener(this);
  }

  @override
  void didUpdateWidget(EnvironmentSelections oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      setState(() {
        _selectedEnv = widget.selected;
      });
    }
  }

  @override
  Future<void> onPermissionStatusChanged(EnvironmentType environment, bool isGranted) async {
    logger.debug(
      'EnvironmentSelections',
      'onPermissionStatusChanged $environment $isGranted',
    );
    if (!requesting || requestingPerm != environment) return;
    //关闭等待弹窗
    await loadingController?.close();
    loadingController = null;
    setState(() {
      requesting = false;
      requestingPerm = null;
    });
    if (isGranted) {
      setState(() {
        _selectedEnv = environment;
        widget.onSelected(_selectedEnv);
      });
    } else {
      if (environment == EnvironmentType.shizuku) {
        if (mounted) {
          await dialogManager.tips(
            context,
            title: TranslationKey.requestFailed.tr,
            text: TranslationKey.shizukuRequestFailedDialogText.tr,
            actions: DialogActions(
              confirm: DialogAction(
                onPressed: context.pop,
              ),
            ),
          );
        }
      } else if (environment == EnvironmentType.root) {
        if (mounted) {
          await dialogManager.tips(
            context,
            title: TranslationKey.requestFailed.tr,
            text: TranslationKey.rootRequestFailedDialogText.tr,
          );
        }
      }
    }
  }

  @override
  void onClipboardChanged(ClipboardContentType type, String content, ClipboardSource? source) {
    // TODO: implement onClipboardChanged
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        EnvironmentSelectionCard(
          selected: _selectedEnv == EnvironmentType.shizuku,
          icon: Image.asset(
            shizukuLogoPath,
            width: 48,
            height: 48,
          ),
          tipContent: Row(
            children: [
              Text(
                TranslationKey.shizukuMode.tr,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              GestureDetector(
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blueGrey,
                  size: 20,
                ),
                onTap: () {
                  dialogManager.tips(
                    context,
                    text: TranslationKey.shizukuModeBatteryOptimiseTips.tr,
                  );
                },
              ),
            ],
          ),
          tipDesc: Text(
            TranslationKey.shizukuModeDesc.tr,
            style: const TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
          onTap: () {
            setState(() {
              requesting = true;
              requestingPerm = EnvironmentType.shizuku;
            });
            loadingController = dialogManager.loading(context, loadingText: TranslationKey.waitingRequestResult.tr);
            clipboardManager.requestPermission(EnvironmentType.shizuku);
          },
        ),
        EnvironmentSelectionCard(
          selected: _selectedEnv == EnvironmentType.root,
          icon: Image.asset(
            rootLogoPath,
            width: 48,
            height: 48,
          ),
          tipContent: Text(
            TranslationKey.rootMode.tr,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tipDesc: Text(
            TranslationKey.rootModeDesc.tr,
            style: const TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
          onTap: () {
            setState(() {
              requesting = true;
              requestingPerm = EnvironmentType.root;
            });
            loadingController = dialogManager.loading(context, loadingText: TranslationKey.waitingRequestResult.tr);
            clipboardManager.requestPermission(EnvironmentType.root);
          },
        ),
        EnvironmentSelectionCard(
          selected: _selectedEnv == EnvironmentType.none,
          onTap: () {
            setState(() {
              _selectedEnv = EnvironmentType.none;
              widget.onSelected.call(EnvironmentType.none);
              requestingPerm = null;
              requesting = false;
            });
          },
          icon: const Icon(
            Icons.block_outlined,
            size: 40,
            color: Colors.blueGrey,
          ),
          tipContent: Text(
            TranslationKey.ignoreMode.tr,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tipDesc: Text(
            TranslationKey.ignoreModeDesc.tr,
            style: const TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
        ),
      ],
    );
  }
}
