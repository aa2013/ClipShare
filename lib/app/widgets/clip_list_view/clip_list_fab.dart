part of '../clip_list_view.dart';

extension _ClipListFab on ClipListViewState {
  Widget _buildFloatingActionButton() {
    const fabSize = ExpandableFabSize.regular;
    const distance = 145.0;
    final multiSelected = _selectMode && _selectedItems.length > 1;
    final fab = <Widget>[
      Visibility(
        visible: _selectMode,
        child: Positioned(
          right: 85,
          bottom: 15,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffc3e8ff),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child:
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "${_selectedItems.length} / ${widget.list.length}",
                  style: TextStyle(
                    fontSize: 20,
                    color: appConfig.currentIsDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
            ),),
          ),),
      ),
      Visibility(
        visible: _showBackToTopButton,
        child: AnimatedPositioned(
          right: 15,
          bottom: _selectMode ? 85 : 15,
          duration: 300.ms,
          child: Tooltip(
            message: TranslationKey.backToTop.tr,
            child: FloatingActionButton(
              onPressed: () {
                Future.delayed(100.ms, () {
                  _scrollController.animateTo(
                    0,
                    duration: 500.ms,
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ),),
      ),
      Visibility(
        visible: _selectMode,
        child: ExpandableFab(
          distance: distance,
          type: ExpandableFabType.fan,
          overlayStyle: const ExpandableFabOverlayStyle(blur: 8),
          openButtonBuilder: RotateFloatingActionButtonBuilder(
            fabSize: fabSize,
            child: Tooltip(
              message: TranslationKey.moreActions.tr,
              child: const Icon(Icons.menu),
            ),
          ),
          closeButtonBuilder: DefaultFloatingActionButtonBuilder(
            fabSize: fabSize,
            child: Tooltip(
              message: TranslationKey.close.tr,
              child: const Icon(Icons.close),
            ),
          ),
          children: [
            _fabButtonFun(
              onPressed: _exitSelectionMode,
              tooltip: "${TranslationKey.deselect.tr} (${Constants.selectionExitShortcutLabel})",
              child: const Icon(MdiIcons.cancel),
            ),
            _fabButtonFun(
              onPressed: _showSelectedDeleteDialog,
              tooltip: "${TranslationKey.delete.tr} (${Constants.selectionDeleteShortcutLabel})",
              child: const Icon(Icons.delete_forever),
            ),
            _fabButtonFun(
              onPressed: multiSelected ? () async {
                var list = _selectedItems.toList()..sort((a, b) => a.data.id.compareTo(b.data.id));
                var content = list.map((item) => item.data.content).join('\n');
                await clipboardManager.copy(ClipboardContentType.text, content);
                if (!mounted) {
                  return;
                }
                Global.showSnackBarSuc(text: TranslationKey.copySuccess.tr, context: context);
                _cancelSelectionMode();
              } : null,
              tooltip: TranslationKey.copyMergedContent.tr,
              child: const Icon(Icons.content_copy_rounded),
            ),
            _fabButtonFun(
              onPressed: multiSelected ? () {
                final historyController = Get.find<HistoryController>();
                var loaded = false;
                historyController.export((_) {
                  if (loaded) {
                    return [];
                  }
                  loaded = true;
                  return _selectedItems.where((item) => !item.isFile)
                      .map((item) => item.data)
                      .toList();
                }).whenComplete(() => _cancelSelectionMode());
              } : null,
              tooltip: TranslationKey.output.tr,
              child: const Icon(MdiIcons.export),
            ),
          ],
        ),
      ),
    ];
    return SizedBox.expand(child: Stack(children: fab),);
  }

  FloatingActionButton _fabButtonFun({
    required VoidCallback? onPressed,
    String? tooltip,
    Widget? child,
  }) {
    final bgColor = onPressed == null ? Colors.grey[400]: null;
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: bgColor,
      child: child,
    );
  }
}
