import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/features/history/providers/history_export_provider.dart';
import 'package:clipshare/features/history/providers/search_provider.dart';
import 'package:clipshare/features/history/widgets/filter/filter_detail.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/search_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 历史搜索页（移动端）
class HistorySearchPage extends ConsumerStatefulWidget {
  const HistorySearchPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState extends ConsumerState<HistorySearchPage> {
  /// 本地草稿，确认提交前不写入 searchProvider
  late SearchFilter _draft;

  late final TextEditingController _textController;
  late final SearchNotifier _searchNotifier;
  late final HistoryExportNotifier _exportNotifier;

  @override
  void initState() {
    super.initState();
    _searchNotifier = ref.read(searchProvider.notifier);
    _exportNotifier = ref.read(historyExportProvider.notifier);
    //回填当前已生效条件，便于在已有搜索基础上调整
    final currentFilter = ref.read(searchProvider).filter;
    _draft = currentFilter;
    _textController = TextEditingController(text: currentFilter.content);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 提交（含输入框关键词）并返回上一页；
  /// 条件非空触发搜索，为空则由 updateFilter 回退实时列表。
  void _submit() {
    final filter = _draft.copyWith(content: _textController.text);
    _searchNotifier.updateFilter(filter);
    context.pop();
  }

  /// 导出当前搜索条件匹配的历史数据
  void _export() {
    final exportFilter = _draft.copyWith(content: _textController.text);
    _exportNotifier.export(
      context,
      (lastId) {
        final db = ref.read(appDbProvider).requireValue;
        return db.historyDao.getHistoriesPageByFilter(exportFilter, true, lastId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          decoration: context.noneBorderInputDecoration.copyWith(
            fillColor: Colors.transparent,
            hintText: TranslationKey.search.tr,
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          IconButton(
            tooltip: TranslationKey.search.tr,
            onPressed: _submit,
            icon: const Icon(Icons.search_rounded, size: 25),
          ),
          IconButton(
            tooltip: TranslationKey.export2Excel.tr,
            onPressed: _export,
            icon: const Icon(MdiIcons.export, size: 20),
          ),
        ],
      ),
      body: FilterDetail(
        value: _draft,
        devices: search.devices,
        tags: search.tags,
        sources: search.sources,
        embedded: true,
        onChanged: (filter) => setState(() => _draft = filter),
        onConfirm: _submit,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: TranslationKey.confirm.tr,
        onPressed: _submit,
        child: const Icon(Icons.check),
      ),
    );
  }
}
