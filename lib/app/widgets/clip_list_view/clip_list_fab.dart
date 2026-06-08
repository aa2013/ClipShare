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
              onPressed: () {
                _cancelSelectionMode();
                appConfig.disableMultiSelectionMode(true);
                _refreshState();
              },
              tooltip: TranslationKey.deselect.tr,
              child: const Icon(MdiIcons.cancel),
            ),
            _fabButtonFun(
              onPressed: () async {
                void multiDelete(bool deleteFile, [bool onlyDeleteLocal = false]) async {
                  Get.back();
                  Global.showLoadingDialog(
                    context: context,
                    loadingText: TranslationKey.deleting.tr,
                  );
                  for (var item in _selectedItems) {
                    await deleteItem(item, deleteFile: true, onlyDeleteLocal: onlyDeleteLocal);
                  }
                  Get.back();
                  Global.showSnackBarSuc(
                    context: context,
                    text: TranslationKey.deleteCompleted.tr,
                  );
                  appConfig.disableMultiSelectionMode(true);
                  _cancelSelectionMode();
                }
                DialogController? dialog;
                final onlyDeleteLocal = false.obs;
                dialog = await Global.showTipsDialog(
                  context: context,
                  text: TranslationKey.clipListViewDeleteAsk.trParams({"length": _selectedItems.length.toString()}),
                  showCancel: true,
                  autoDismiss: false,
                  customWidget: Container(
                    margin: 10.insetT,
                    child: Obx(() {
                      return CheckboxListTile(
                          title: Text(TranslationKey.onlyLocal.tr),
                          value: onlyDeleteLocal.value,
                          onChanged: (selected) {
                            onlyDeleteLocal.value = selected ?? false;
                          });
                    }),
                  ),
                  showNeutral: _selectedItems.any((item) => item.isFile),
                  neutralText: TranslationKey.deleteWithFiles.tr,
                  onCancel: () {
                    dialog!.close();
                  },
                  onNeutral: () => multiDelete(true, onlyDeleteLocal.value),
                  onOk: () => multiDelete(false, onlyDeleteLocal.value),
                );
              },
              tooltip: TranslationKey.delete.tr,
              child: const Icon(Icons.delete_forever),
            ),
            _fabButtonFun(
              onPressed: multiSelected ? () async {
                var list = _selectedItems.toList()..sort((a, b) => a.data.id.compareTo(b.data.id));
                var content = list.map((item) => item.data.content).join('\n');
                await clipboardManager.copy(ClipboardContentType.text, content);
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
      child: child,
      backgroundColor: bgColor,
    );
  }
}
