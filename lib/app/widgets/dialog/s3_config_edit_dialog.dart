import 'package:clipshare/app/data/enums/obj_storage_type.dart';
import 'package:clipshare/app/data/models/exception_info.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/handlers/storage/aliyun_oss_client.dart';
import 'package:clipshare/app/handlers/storage/s3_client.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
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

class S3ConfigEditDialog extends StatefulWidget {
  final void Function(S3Config config) onOk;
  final S3Config? initValue;

  const S3ConfigEditDialog({
    super.key,
    this.initValue,
    required this.onOk,
  });

  @override
  State<StatefulWidget> createState() => _S3ConfigEditDialogState();
}

class _S3ConfigEditDialogState extends State<S3ConfigEditDialog> {
  static const tag = "S3ConfigEditDialog";
  final nameEditor = TextEditingController();
  final endPointEditor = TextEditingController();
  final accessKeyEditor = TextEditingController();
  final secretKeyEditor = TextEditingController();
  final bucketNameEditor = TextEditingController();
  final regionEditor = TextEditingController();
  final baseDirEditor = TextEditingController(text: '/');

  ObjStorageType objectStorageType = ObjStorageType.s3;
  bool _obscureSecretKey = true;
  bool _obscureAccessKey = true;

  String? nameErrText;
  String? endPointErrText;
  String? accessKeyErrText;
  String? secretKeyErrText;
  String? bucketNameErrText;
  String? baseDirErrText;
  String? regionErrText;
  bool testingConnection = false;

  S3Config get config => S3Config(
    type: objectStorageType,
    displayName: nameEditor.text,
    endPoint: endPointEditor.text,
    accessKey: accessKeyEditor.text,
    secretKey: secretKeyEditor.text,
    bucketName: bucketNameEditor.text,
    region: regionEditor.text.isNotEmpty ? regionEditor.text : null,
    baseDir: baseDirEditor.text,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initValue != null) {
      reset(config);
    }
  }

  void reset(S3Config config) {
    nameEditor.text = config.displayName;
    endPointEditor.text = config.endPoint;
    accessKeyEditor.text = config.accessKey;
    secretKeyEditor.text = config.secretKey;
    bucketNameEditor.text = config.bucketName;
    regionEditor.text = config.region ?? '';
    baseDirEditor.text = config.baseDir;
    objectStorageType = config.type;
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

  bool validateEndPointEditor() {
    bool isValid;
    if (endPointEditor.text.isEmpty) {
      endPointErrText = TranslationKey.s3EndpointRequired.tr;
      isValid = false;
    } else if (!endPointEditor.text.matchRegExp(r'[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?')) {
      endPointErrText = TranslationKey.pleaseInputCorrectDomain.tr;
      isValid = false;
    } else {
      endPointErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateAccessKeyEditor() {
    bool isValid;
    if (accessKeyEditor.text.isEmpty) {
      accessKeyErrText = TranslationKey.accessKeyRequired.tr;
      isValid = false;
    } else {
      accessKeyErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateSecretKeyEditor() {
    bool isValid;
    if (secretKeyEditor.text.isEmpty) {
      secretKeyErrText = TranslationKey.secretKeyRequired.tr;
      isValid = false;
    } else {
      secretKeyErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateBucketNameEditor() {
    bool isValid;
    if (bucketNameEditor.text.isEmpty) {
      bucketNameErrText = TranslationKey.bucketNameRequired.tr;
      isValid = false;
    } else {
      bucketNameErrText = null;
      isValid = true;
    }
    setState(() {});
    return isValid;
  }

  bool validateRegionEditor() {
    if (objectStorageType != ObjStorageType.aliyunOss) {
      return true;
    }
    bool isValid;
    if (regionEditor.text.isEmpty) {
      regionErrText = TranslationKey.regionRequired.tr;
      isValid = false;
    } else {
      regionErrText = null;
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
    final isEndPointValid = validateEndPointEditor();
    final isAccessKeyValid = validateAccessKeyEditor();
    final isSecretKeyValid = validateSecretKeyEditor();
    final isBucketNameValid = validateBucketNameEditor();
    final isBaseDirValid = !verifyBaseDir || validateBaseDirEditor();
    final isRegionValid = validateRegionEditor();

    return isRegionValid && isNameValid && isEndPointValid && isAccessKeyValid && isSecretKeyValid && isBucketNameValid && isBaseDirValid;
  }

  Future<void> _testConnection() async {
    if (validateFields(false)) {
      setState(() {
        testingConnection = true;
      });
      late final ExceptionInfo? exception;
      try {
        late final StorageClient s3Client;
        if (config.type == ObjStorageType.aliyunOss) {
          s3Client = AliyunOssClient(config);
        } else {
          s3Client = S3Client(config);
        }
        if (!testingConnection) {
          return;
        }
        exception = await s3Client.testConnect();
      } catch (err, stack) {
        exception = ExceptionInfo(err: err, stackTrace: stack);
      } finally {
        if (testingConnection) {
          setState(() {
            testingConnection = false;
          });
        }
      }
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
          Text(TranslationKey.configureS3Storage.tr),
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
                            final result = S3Config.fromJson(json);
                            setState(() {
                              reset(result);
                            });
                          } else {
                            Global.showTipsDialog(context: context, text: TranslationKey.qrCodeScanError.tr);
                            Log.warn(tag, "scan result is null");
                          }
                        } catch (err, stack) {
                          Log.error(tag, err, stack);
                          Global.showTipsDialog(context: context, text: TranslationKey.qrCodeScanError.tr);
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
          child: Container(
            margin: 5.insetV,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Storage Type Selector
                // Storage Type Selector
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ObjStorageType>(
                        value: objectStorageType,
                        decoration: InputDecoration(
                          labelText: TranslationKey.objectStorageType.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: ObjStorageType.values.map((type) {
                          return DropdownMenuItem<ObjStorageType>(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: testingConnection
                            ? null
                            : (ObjStorageType? value) {
                                if (value != null) {
                                  setState(() {
                                    objectStorageType = value;
                                    if (objectStorageType != ObjStorageType.aliyunOss) {
                                      regionErrText = null;
                                    }
                                  });
                                }
                              },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
                      onPressed: () {
                        Global.showTipsDialog(context: context, text: TranslationKey.s3TypeTips.tr);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Configuration Name
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

                // Endpoint
                TextField(
                  controller: endPointEditor,
                  enabled: !testingConnection,
                  decoration: InputDecoration(
                    labelText: TranslationKey.endpoint.tr,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    errorText: endPointErrText,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    validateEndPointEditor();
                  },
                ),
                const SizedBox(height: 16),

                // Access Key
                TextField(
                  controller: accessKeyEditor,
                  enabled: !testingConnection,
                  obscureText: _obscureAccessKey,
                  decoration: InputDecoration(
                    labelText: TranslationKey.s3AccessKey.tr,
                    errorText: accessKeyErrText,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureAccessKey ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureAccessKey = !_obscureAccessKey;
                        });
                      },
                    ),
                  ),
                  onChanged: (v) {
                    validateAccessKeyEditor();
                  },
                ),
                const SizedBox(height: 16),

                // Secret Key
                TextField(
                  controller: secretKeyEditor,
                  enabled: !testingConnection,
                  obscureText: _obscureSecretKey,
                  decoration: InputDecoration(
                    labelText: TranslationKey.s3SecretKey.tr,
                    errorText: secretKeyErrText,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSecretKey ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureSecretKey = !_obscureSecretKey;
                        });
                      },
                    ),
                  ),
                  onChanged: (v) {
                    validateSecretKeyEditor();
                  },
                ),
                const SizedBox(height: 16),

                // Bucket Name
                TextField(
                  controller: bucketNameEditor,
                  enabled: !testingConnection,
                  decoration: InputDecoration(
                    labelText: TranslationKey.bucketName.tr,
                    errorText: bucketNameErrText,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    validateBucketNameEditor();
                  },
                ),
                const SizedBox(height: 16),

                // Region (optional)
                TextField(
                  controller: regionEditor,
                  enabled: !testingConnection,
                  decoration: InputDecoration(
                    labelText: '${TranslationKey.region.tr}${objectStorageType == ObjStorageType.aliyunOss ? '' : ' (${TranslationKey.optional.tr})'}',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: const OutlineInputBorder(),
                    errorText: regionErrText,
                  ),
                  onChanged: (v) {
                    if (objectStorageType == ObjStorageType.aliyunOss) {
                      validateRegionEditor();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Base Directory
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
                            border: const OutlineInputBorder(),
                            errorText: baseDirErrText,
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
                                        final s3client = objectStorageType == ObjStorageType.aliyunOss ? AliyunOssClient(tempConfig) : S3Client(tempConfig);
                                        final list = await s3client.list(path: path);
                                        final dirs = list.where((item) => item.isDir);
                                        return dirs.map((item) => FileItem(name: item.name, isDirectory: true, fullPath: item.path)).toList();
                                      },
                                      onCreateDirectory: (current, name) {
                                        final tempConfig = config.copyWith(baseDir: Constants.unixDirSeparate);
                                        final s3client = objectStorageType == ObjStorageType.aliyunOss ? AliyunOssClient(tempConfig) : S3Client(tempConfig);
                                        return s3client.createDirectory("$current/$name/");
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
