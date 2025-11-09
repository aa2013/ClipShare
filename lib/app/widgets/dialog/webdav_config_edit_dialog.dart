import 'dart:io';

import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/handlers/storage/web_dav_client.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/file_browser.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:get/get.dart';

class WebdavConfigEditDialog extends StatefulWidget {
  final void Function(WebDavConfig config) onOk;
  final WebDavConfig? initValue;

  const WebdavConfigEditDialog({
    super.key,
    this.initValue,
    required this.onOk,
  });

  @override
  State<StatefulWidget> createState() => _WebdavConfigEditDialogState();
}

class _WebdavConfigEditDialogState extends State<WebdavConfigEditDialog> {
  static const tag = "WebdavConfigEditDialog";
  final nameEditor = TextEditingController();
  final serverEditor = TextEditingController();
  final usernameEditor = TextEditingController();
  final passwordEditor = TextEditingController();
  final baseDirEditor = TextEditingController(text: '/');

  bool _obscurePassword = true;
  String? nameErrText;
  String? serverErrText;
  String? usernameErrText;
  String? passwordErrText;
  String? baseDirErrText;
  bool testingConnection = false;

  WebDavConfig get config => WebDavConfig(
    displayName: nameEditor.text,
    server: serverEditor.text,
    username: usernameEditor.text,
    password: passwordEditor.text,
    baseDir: baseDirEditor.text,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initValue != null) {
      reset(widget.initValue!);
    }
  }

  void reset(WebDavConfig config) {
    nameEditor.text = config.displayName;
    serverEditor.text = config.server;
    usernameEditor.text = config.username;
    passwordEditor.text = config.password;
    baseDirEditor.text = config.baseDir;
  }

  bool validateNameEditor() {
    bool isValid;
    if (nameEditor.text.isEmpty) {
      nameErrText = TranslationKey.nameRequired.tr;
      isValid = false;
    } else {
      nameErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateServerEditor() {
    bool isValid;
    if (serverEditor.text.isEmpty) {
      serverErrText = TranslationKey.webdavServerUrlRequired.tr;
      isValid = false;
    } else if (!serverEditor.text.startsWith('http://') && !serverEditor.text.startsWith('https://')) {
      serverErrText = TranslationKey.webdavUrlMustStartWithHttp.tr;
      isValid = false;
    } else if (!serverEditor.text.matchRegExp(Constants.httpUrlRegex)) {
      serverErrText = TranslationKey.pleaseInputCorrectURL.tr;
      isValid = false;
    } else {
      serverErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateUsernameEditor() {
    bool isValid;
    if (usernameEditor.text.isEmpty) {
      usernameErrText = TranslationKey.usernameRequired.tr;
      isValid = false;
    } else {
      usernameErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validatePasswordEditor() {
    bool isValid;
    if (passwordEditor.text.isEmpty) {
      passwordErrText = TranslationKey.passwordRequired.tr;
      isValid = false;
    } else {
      passwordErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateBaseDirEditor() {
    bool isValid;
    if (baseDirEditor.text == "/") {
      isValid = false;
      baseDirErrText = TranslationKey.notAllowRootPath.tr;
    } else if (baseDirEditor.text.isEmpty) {
      baseDirErrText = TranslationKey.baseDirectoryRequired.tr;
      isValid = false;
    } else if (!baseDirEditor.text.startsWith('/')) {
      baseDirErrText = TranslationKey.baseDirectoryMustStartWithSlash.tr;
      isValid = false;
    } else {
      baseDirErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateFields([bool verifyBaseDir = true]) {
    final isNameValid = validateNameEditor();
    final isServerValid = validateServerEditor();
    final isUsernameValid = validateUsernameEditor();
    final isPasswordValid = validatePasswordEditor();
    final isBaseDirValid = !verifyBaseDir || validateBaseDirEditor();

    return isNameValid && isServerValid && isUsernameValid && isPasswordValid && isBaseDirValid;
  }

  Future<void> _testConnection() async {
    if (validateFields(false)) {
      setState(() {
        testingConnection = true;
      });
      final exception = await WebDavClient(config).testConnect();
      if (!testingConnection) {
        return;
      }
      setState(() {
        testingConnection = false;
      });
      if (exception != null) {
        Global.showTipsDialog(context: context, text: "${exception.err}, ${exception.stackTrace}", title: TranslationKey.connectFailed.tr);
      } else {
        Global.showTipsDialog(context: context, text: TranslationKey.connectSuccess.tr, title: TranslationKey.connectSuccess.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(TranslationKey.configureWebdavServer.tr),
          if (PlatformExt.isMobile)
            Tooltip(
              message: TranslationKey.scan.tr,
              child: IconButton(
                onPressed: testingConnection
                    ? null
                    : () async {
                        var hasPerm = await PermissionHelper.testAndroidCameraPerm();
                        if (!hasPerm) {
                          await PermissionHelper.reqAndroidCameraPerm();
                          hasPerm = await PermissionHelper.testAndroidCameraPerm();
                          if (!hasPerm) {
                            Global.showTipsDialog(
                              context: context,
                              text: TranslationKey.noCameraPermission.tr,
                            );
                            return;
                          }
                        }
                        final json = await Get.toNamed<dynamic>(Routes.QR_CODE_SCANNER);
                        try {
                          if (json != null) {
                            final result = WebDavConfig.fromJson(json);
                            setState(() {
                              reset(result);
                            });
                          } else {
                            Global.showTipsDialog(context: context, text: TranslationKey.qrCodeScanError.tr);
                            Log.warn(tag, "scan result is null");
                          }
                        } catch (err, stack) {
                          Global.showTipsDialog(context: context, text: TranslationKey.qrCodeScanError.tr);
                          Log.error(tag, err, stack);
                        }
                      },
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.blueGrey,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEditor,
                enabled: !testingConnection,
                decoration: InputDecoration(
                  labelText: TranslationKey.configName.tr,
                  errorText: nameErrText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  validateNameEditor();
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: serverEditor,
                enabled: !testingConnection,
                decoration: InputDecoration(
                  labelText: TranslationKey.serverUrl.tr,
                  hintText: "https://example.com/webdav",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: serverErrText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  validateServerEditor();
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameEditor,
                enabled: !testingConnection,
                decoration: InputDecoration(
                  labelText: TranslationKey.username.tr,
                  errorText: usernameErrText,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  validateUsernameEditor();
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordEditor,
                enabled: !testingConnection,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: TranslationKey.password.tr,
                  errorText: passwordErrText,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onChanged: (v) {
                  validatePasswordEditor();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: TranslationKey.readonly.tr,
                      child: TextField(
                        controller: baseDirEditor,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: TranslationKey.storagePath.tr,
                          hintText: TranslationKey.storagePathHint.tr,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          errorText: baseDirErrText,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: testingConnection
                        ? null
                        : () {
                            DialogController? dialog;
                            String selectedPath = baseDirEditor.text;
                            dialog = Global.showDialog(
                              context,
                              AlertDialog(
                                title: Text(TranslationKey.selectStoragePath.tr),
                                content: SizedBox(
                                  width: 350,
                                  child: FileBrowser(
                                    onLoadFiles: (String path) async {
                                      selectedPath = path.unixPath;
                                      final tempConfig = config.copyWith(baseDir: Constants.unixDirSeparate);
                                      final list = await WebDavClient(tempConfig).list(path: path);
                                      return list.where((item) => item.isDir).map((item) => FileItem(name: item.name, isDirectory: true, fullPath: item.path)).toList();
                                    },
                                    onCreateDirectory: (current, name) {
                                      final tempConfig = config.copyWith(baseDir: Constants.unixDirSeparate);
                                      final client = WebDavClient(tempConfig);
                                      return client.createDirectory("$current/$name/");
                                    },
                                    shouldShowUpLevel: (path) => path != Constants.unixDirSeparate || path.isNullOrEmpty,
                                    initialPath: Constants.unixDirSeparate,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => dialog?.close(),
                                    child: Text(TranslationKey.dialogCancelText.tr),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (selectedPath == "/") {
                                        Global.showTipsDialog(context: context, text: TranslationKey.notAllowRootPath.tr);
                                        return;
                                      }
                                      baseDirEditor.text = selectedPath;
                                      dialog?.close();
                                      validateFields();
                                    },
                                    child: Text(TranslationKey.dialogConfirmText.tr),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: Text(TranslationKey.selection.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Visibility(
              visible: testingConnection,
              replacement: TextButton(
                onPressed: _testConnection,
                child: Text(TranslationKey.checkConnection.tr),
              ),
              child: const Loading(),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (testingConnection) {
                        setState(() {
                          testingConnection = false;
                        });
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text(TranslationKey.dialogCancelText.tr),
                  ),
                  TextButton(
                    onPressed: testingConnection
                        ? null
                        : () {
                            if (validateFields()) {
                              widget.onOk(config);
                              Navigator.of(context).pop();
                            }
                          },
                    child: Text(TranslationKey.save.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
