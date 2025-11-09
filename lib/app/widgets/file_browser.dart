import 'dart:async';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/dialog/text_edit_dialog.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';

typedef FileListLoader = FutureOr<List<FileItem>> Function(String path);
typedef DirectoryCreator = Future<bool> Function(String currentPath, String name);
typedef ShouldShowUpLevel = bool Function(String currentPath);

class FileItem {
  final String name;
  final bool isDirectory;
  final String? fullPath;

  FileItem({
    required this.name,
    required this.isDirectory,
    this.fullPath,
  });
}

class FileBrowser extends StatefulWidget {
  final FileListLoader onLoadFiles;
  final DirectoryCreator? onCreateDirectory;
  final ShouldShowUpLevel shouldShowUpLevel;
  final String initialPath;

  const FileBrowser({
    super.key,
    required this.onLoadFiles,
    required this.shouldShowUpLevel,
    required this.initialPath,
    this.onCreateDirectory,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  late String _currentPath;
  List<FileItem> _files = [];
  bool _isLoading = false;
  static const tag = "FileBrowser";

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await widget.onLoadFiles(_currentPath);
      setState(() => _files = files);
    } catch (e, stack) {
      Log.error(tag, 'Error loading files: $e', stack);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTap(FileItem item) {
    if (item.isDirectory) {
      setState(() {
        _currentPath = item.fullPath?.trimEnd(Constants.unixDirSeparate) ?? Constants.unixDirSeparate;
        if (!_currentPath.startsWith(Constants.unixDirSeparate)) {
          _currentPath = Constants.unixDirSeparate + _currentPath;
        }
      });
      _loadFiles();
    } else {
      // Handle file tap if needed
      debugPrint('File tapped: ${item.name}');
    }
  }

  void _onUpLevelTap() {
    final pathParts = _currentPath.split(Constants.unixDirSeparate);
    if (pathParts.length > 1) {
      pathParts.removeLast();
      setState(() {
        _currentPath = pathParts.join(Constants.unixDirSeparate);
        if (_currentPath.isEmpty) {
          _currentPath = Constants.unixDirSeparate;
        }
      });
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filesCount = widget.shouldShowUpLevel(_currentPath) ? _files.length + 1 : _files.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示当前路径
        Row(
          children: [
            Expanded(
              child: Text(
                '${TranslationKey.current.tr}: $_currentPath',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (widget.onCreateDirectory != null)
              TextButton(
                onPressed: () {
                  Global.showDialog(
                    context,
                    TextEditDialog(
                      title: TranslationKey.createFolder.tr,
                      labelText: TranslationKey.folder.tr,
                      initStr: '',
                      verify: (s) {
                        // 验证文件夹名称是否为空
                        if (s.isEmpty) {
                          return false;
                        }
                        if (s.length > 255) {
                          return false;
                        }
                        // 验证是否包含非法字符
                        final invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
                        if (invalidChars.hasMatch(s)) {
                          return false;
                        }
                        return true;
                      },
                      errorText: TranslationKey.invalidFolderName.tr,
                      okText: TranslationKey.create.tr,
                      onOk: (v) async {
                        try {
                          setState(() {
                            _isLoading = true;
                          });
                          final result = await widget.onCreateDirectory!.call(_currentPath, v);
                          if (!result) {
                            Global.showTipsDialog(context: context, text: TranslationKey.createFailed.tr);
                            return;
                          } else {
                            await _loadFiles();
                          }
                        } catch (err, stack) {
                          Log.error(tag, err, stack);
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.create_new_folder_outlined,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(TranslationKey.create.tr),
                  ],
                ),
              ),
          ],
        ),
        // 文件列表
        Expanded(
          child: _isLoading
              ? const Loading(width: 32)
              : filesCount == 0
              ? EmptyContent()
              : ListView.builder(
                  itemCount: filesCount,
                  itemBuilder: (context, index) {
                    // 第一项显示".."返回上一级
                    if (widget.shouldShowUpLevel(_currentPath) && index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: const Text('..'),
                        onTap: _onUpLevelTap,
                      );
                    }

                    // 调整索引，因为第一项是".."
                    final fileIndex = widget.shouldShowUpLevel(_currentPath) ? index - 1 : index;
                    final file = _files[fileIndex];
                    return ListTile(
                      leading: Icon(
                        file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                      ),
                      title: Text(file.name),
                      onTap: () => _onItemTap(file),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
