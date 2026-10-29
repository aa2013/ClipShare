import 'package:clipshare/features/tags/providers/tag_edit_controller.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 标签编辑表单：搜索、创建与勾选标签。
///
/// 自身不负责外部间距与滚动容器，由宿主（页面/弹窗）提供有界高度与水平内缩。
class TagEditForm extends ConsumerStatefulWidget {
  final int hisId;

  const TagEditForm({
    super.key,
    required this.hisId,
  });

  @override
  ConsumerState<TagEditForm> createState() => _TagEditFormState();
}

class _TagEditFormState extends ConsumerState<TagEditForm> {
  final _textController = TextEditingController();

  TagEditController get _controller => ref.read(tagEditControllerProvider(widget.hisId).notifier);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 生成胶囊形输入框边框：仅用于圆角，不绘制描边。
  OutlineInputBorder _pillBorder() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(tagEditControllerProvider(widget.hisId));
    return asyncState.when(
      loading: () => const Loading(),
      error: (err, stack) => Center(child: Text(TranslationKey.failedToLoad.tr)),
      data: (state) {
        final colorScheme = context.currentTheme.colorScheme;
        final showCreate = state.keyword.isNotEmpty && !state.tagExists;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.saving) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: EdgeInsets.all(context.isCompactScreen ? 8 : 4),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.primary.withValues(alpha: 0.06),
                  hintText: TranslationKey.tagEditPageSearchOrCreateTag.tr,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _textController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: TranslationKey.close.tr,
                          onPressed: () {
                            _textController.clear();
                            _controller.updateKeyword('');
                            setState(() {});
                          },
                        ),
                  border: _pillBorder(),
                  enabledBorder: _pillBorder(),
                  focusedBorder: _pillBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onChanged: (text) {
                  _controller.updateKeyword(text);
                  // 刷新清除按钮的可见性
                  setState(() {});
                },
              ),
            ),
            if (showCreate)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add),
                        const SizedBox(width: 5),
                        Text(
                          TranslationKey.tagEditPageCrateTagItem.trParams({'tag': state.keyword}),
                        ),
                      ],
                    ),
                    onPressed: () {
                      _controller.createTag(state.keyword);
                      _textController.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                itemCount: state.visibleTags.length,
                itemBuilder: (ctx, index) {
                  final tagName = state.visibleTags[index].tagName;
                  return _buildTagRow(state, tagName);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 单个标签行：左侧复选框，点击整行或复选框均可切换选中。
  Widget _buildTagRow(TagEditState state, String tagName) {
    final colorScheme = context.currentTheme.colorScheme;
    final selected = state.isSelected(tagName);
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      onTap: () => _controller.toggleTag(tagName, !selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (checked) => _controller.toggleTag(tagName, checked ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HighlightedText(
                text: tagName,
                keyword: state.keyword,
                style: context.currentTheme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 命中关键字片段以主色加粗展示的标签文本。
class _HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle? style;

  const _HighlightedText({
    required this.text,
    required this.keyword,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final index = keyword.isEmpty ? -1 : text.toLowerCase().indexOf(keyword.toLowerCase());
    if (index < 0) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final highlightStyle = (style ?? const TextStyle()).copyWith(
      color: context.currentTheme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + keyword.length),
            style: highlightStyle,
          ),
          TextSpan(text: text.substring(index + keyword.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
