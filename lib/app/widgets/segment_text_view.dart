import 'dart:async';
import 'dart:math' as math;

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/jieba_segment_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jieba_flutter/analysis/seg_token.dart';

const _tokensPerRenderChunk = 80;
const _tokensRevealBatchSize = 600;
const _tokensRevealInterval = Duration(milliseconds: 16);

class SegmentTestView extends StatefulWidget {
  final String text;
  final void Function() onClose;

  const SegmentTestView({
    super.key,
    required this.text,
    required this.onClose,
  });

  @override
  State<StatefulWidget> createState() => _SegmentTestViewState();
}

class _SegmentTestViewState extends State<SegmentTestView> {
  final List<SegToken> tokens = [];
  final Set<int> selectedTokens = {};
  int _visibleTokenCount = 0;
  int _loadGeneration = 0;
  bool _loading = false;
  bool _revealingTokens = false;

  @override
  void initState() {
    super.initState();
    _loadSegmentTokens();
  }

  @override
  void didUpdateWidget(covariant SegmentTestView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _loadSegmentTokens();
    }
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
      final result = await Get.find<JiebaSegmentService>().segment(widget.text);
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
      logger.error('SegmentTestView', err, stack);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _revealingTokens = false;
      });
      Global.showSnackBarErr(context: context, text: TranslationKey.failedToLoad.tr);
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
    if (selected) {
      selectedTokens.add(index);
    } else {
      selectedTokens.remove(index);
    }
    setState(() {});
  }

  /// 复制按原文顺序选中的分词内容，避免用户选择顺序影响最终拼接结果。
  void _copySelectedTokens() {
    final indexList = selectedTokens.toList()..sort((a, b) => a - b);
    final content = indexList.map((i) => tokens[i].word).join("");
    clipboardManager.copy(ClipboardContentType.text, content);
    Global.showSnackBarSuc(context: context, text: TranslationKey.copySuccess.tr);
    onClose();
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

  /// 关闭分词视图时递增加载代次，防止后台任务完成后重新写入已关闭页面。
  void onClose() {
    _loadGeneration++;
    widget.onClose();
    if (!mounted) {
      return;
    }
    setState(() {
      tokens.clear();
      selectedTokens.clear();
      _visibleTokenCount = 0;
      _loading = false;
      _revealingTokens = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}
