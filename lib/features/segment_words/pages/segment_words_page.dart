import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/file_util.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/features/segment_words/providers/jieba_segment_provider.dart';
import 'package:clipshare/features/segment_words/providers/jieba_segment_service.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/keyboard_shortcut.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/blur_background.dart';
import 'package:clipshare/shared/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jieba_flutter/analysis/seg_token.dart';

const _tag = 'SegmentWordsPage';
const _tokensPerRenderChunk = 80;
const _tokensRevealBatchSize = 600;
const _tokensRevealInterval = Duration(milliseconds: 16);

/// 分词页路由参数，go_router 通过 extra 携带待分词文本。
class SegmentWordsRouteArgs {
  final String text;

  const SegmentWordsRouteArgs({required this.text});
}

/// 确保分词环境就绪：校验词典文件、必要时引导下载安装、初始化分词 worker。
///
/// 返回 true 表示可以进入分词页；false 表示当前无法分词（已给出提示）。
Future<bool> ensureJiebaSegmentReady(BuildContext context, WidgetRef ref) async {
  final service = ref.read(jiebaSegmentServiceProvider);
  final dirPath = await service.getJiebaSegmentFileDirPath();
  final dictFilePath = '$dirPath/dict.txt'.normalizePath;
  final probEmitFilePath = '$dirPath/prob_emit.txt'.normalizePath;
  final hasDict = await File(dictFilePath).exists() && await File(probEmitFilePath).exists();
  if (!hasDict) {
    if (context.mounted) {
      _showJiebaInstallDialog(context, ref, dirPath);
    }
    return false;
  }
  if (service.isInitializedFor(dirPath)) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }
  final dialog = dialogManager.loading(
    context,
    loadingText: TranslationKey.loading.tr,
  );
  try {
    final ok = await service.ensureInitialized(dirPath);
    if (!ok && context.mounted) {
      snackbar.error(context, TranslationKey.failedToLoad.tr);
    }
    return ok;
  } finally {
    await dialog.close();
  }
}

/// 词典缺失提示弹窗：支持一键下载安装或跳转 GitHub 手动下载。
void _showJiebaInstallDialog(BuildContext context, WidgetRef ref, String dirPath) {
  dialogManager.tips(
    context,
    selectable: true,
    text: TranslationKey.notFoundJiebaFiles.trParams({'dirPath': dirPath}),
    actions: DialogActions(
      confirm: DialogAction(
        text: TranslationKey.installJiebaDictFile.tr,
        onPressed: () => unawaited(_downloadJiebaFiles(context, ref)),
      ),
      neutral: DialogAction(
        text: TranslationKey.downloadFromGithub.tr,
        onPressed: () => jiebaGithubUrl.askOpenUrl(context),
      ),
      cancel: const DialogAction(),
    ),
  );
}

/// 下载 jieba.zip 并解压到词典目录，完成后提示用户。
Future<void> _downloadJiebaFiles(BuildContext context, WidgetRef ref) async {
  final appPaths = await ref.read(appPathsProvider.future);
  final service = ref.read(jiebaSegmentServiceProvider);
  const fileName = 'jieba.zip';
  final downPath = isAndroid
      ? '$androidDownloadPath/ClipShare/$fileName'
      : '${appPaths.documentsPath}/temp/$fileName';
  if (!context.mounted) {
    return;
  }
  dialogManager.downloading(
    context,
    url: jiebaDownloadUrl,
    filePath: downPath,
    content: const Text(fileName),
    onFinished: (success) async {
      if (!success) {
        if (context.mounted) {
          snackbar.error(context, TranslationKey.downloadFailed.tr);
        }
        return;
      }
      try {
        final dirPath = await service.getJiebaSegmentFileDirPath();
        await FileUtil.extractZipFile(File(downPath), Directory(dirPath));
        if (context.mounted) {
          snackbar.success(context, TranslationKey.jiebaFileInstallSuccess.tr);
        }
        await File(downPath).delete();
      } catch (err, stack) {
        logger.error(_tag, err, stack);
      }
    },
    onError: (error, stack) => logger.error(_tag, error, stack),
  );
}

/// 分词页面。
///
/// 以透明路由叠加在历史页之上，外层高斯模糊保留前一个页面背景；
/// 文本通过 [SegmentWordsRouteArgs] 路由参数传入。
class SegmentWordsPage extends ConsumerStatefulWidget {
  final String text;

  const SegmentWordsPage({
    super.key,
    required this.text,
  });

  @override
  ConsumerState<SegmentWordsPage> createState() => _SegmentWordsPageState();
}

class _SegmentWordsPageState extends ConsumerState<SegmentWordsPage> {
  final List<SegToken> tokens = [];
  final Set<int> selectedTokens = {};
  int _visibleTokenCount = 0;
  int _loadGeneration = 0;
  bool _loading = false;
  bool _revealingTokens = false;

  JiebaSegmentService get _service => ref.read(jiebaSegmentServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadSegmentTokens();
  }

  /// 异步从分词服务获取结果，并用加载代次丢弃旧文本的过期回写。
  Future<void> _loadSegmentTokens() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _revealingTokens = false;
      _visibleTokenCount = 0;
      tokens.clear();
      selectedTokens.clear();
    });
    try {
      final result = await _service.segment(widget.text);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        tokens
          ..clear()
          ..addAll(result);
      });
      unawaited(_revealTokensInBatches(generation));
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _revealingTokens = false;
      });
      snackbar.error(context, TranslationKey.failedToLoad.tr);
    }
  }

  /// 将分词结果分批揭示给 UI，避免长文本一次性触发大量 chip 构建和布局。
  Future<void> _revealTokensInBatches(int generation) async {
    if (tokens.isEmpty) {
      return;
    }
    setState(() {
      _revealingTokens = true;
    });
    while (mounted && generation == _loadGeneration && _visibleTokenCount < tokens.length) {
      setState(() {
        _visibleTokenCount = math.min(_visibleTokenCount + _tokensRevealBatchSize, tokens.length);
        _revealingTokens = _visibleTokenCount < tokens.length;
      });
      if (_revealingTokens) {
        await Future<void>.delayed(_tokensRevealInterval);
      }
    }
  }

  /// 切换指定 token 的选中状态，索引始终对应完整分词结果中的位置。
  void _toggleTokenSelection(int index, bool selected) {
    setState(() {
      if (selected) {
        selectedTokens.add(index);
      } else {
        selectedTokens.remove(index);
      }
    });
  }

  /// 复制按原文顺序选中的分词内容，避免用户选择顺序影响最终拼接结果。
  Future<void> _copySelectedTokens() async {
    final indexList = selectedTokens.toList()..sort((a, b) => a - b);
    final content = indexList.map((i) => tokens[i].word).join('');
    final copied = await clipboardManager.copy(ClipboardContentType.text, content);
    if (!mounted) {
      return;
    }
    if (copied) {
      snackbar.success(context, TranslationKey.copySuccess.tr);
      onClose();
    } else {
      snackbar.error(context, TranslationKey.copyFailed.tr);
    }
  }

  /// 构建一段 token 的 Wrap，外层列表按块懒加载以降低长文本首屏渲染压力。
  Widget _buildTokenChunk(int chunkIndex) {
    final start = chunkIndex * _tokensPerRenderChunk;
    final end = math.min(start + _tokensPerRenderChunk, _visibleTokenCount);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(end - start, (offset) {
          final index = start + offset;
          final token = tokens[index];
          return RoundedChip(
            label: Text(token.word),
            showCheckmark: false,
            selected: selectedTokens.contains(index),
            onSelected: (selected) => _toggleTokenSelection(index, selected),
          );
        }),
      ),
    );
  }

  /// 根据加载阶段渲染占位或分块列表，确保超长文本不会一次性进入布局树。
  Widget _buildTokenList() {
    if (_loading && tokens.isEmpty) {
      return Loading(description: Text(TranslationKey.segmenting.tr));
    }
    final chunkCount = (_visibleTokenCount / _tokensPerRenderChunk).ceil();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTokenChunk(index),
              childCount: chunkCount,
            ),
          ),
        ),
        if (_revealingTokens)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  /// 关闭分词页；递增加载代次，防止后台任务完成后回写已关闭页面。
  void onClose() {
    _loadGeneration++;
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomKeyboardListener(
        shortcuts: [
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.escape},
            onTrigger: onClose,
          ),
        ],
        child: SizedBox.expand(
          child: BlurBackground(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildTokenList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: TranslationKey.copyContent.tr,
                        child: IconButton(
                          onPressed: _copySelectedTokens,
                          icon: const Icon(Icons.copy, color: Colors.blueGrey),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: TranslationKey.close.tr,
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
