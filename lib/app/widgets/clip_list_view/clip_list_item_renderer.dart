part of '../clip_list_view.dart';

extension _ClipListItemRenderer on ClipListViewState {
  Widget renderItem(int i) => renderClip(widget.list[i]);
  Widget renderClip(ClipData item) {
    final controller = widget.parentController;
    final VoidCallback? locate = widget.filtered && controller is HistoryController ? () {
      homeCtrl.showingHistorySearch.value = false;
      HistoryLocator.reveal(controller.filterController, () => controller.refreshData(showLoading: false),
        () => setState(() => _anchor = item.data.id));
    } : null;
    onRemoveClicked(ClipData item) {
      final onlyDeleteLocal = false.obs;
      Global.showTipsDialog(
        context: context,
        text: TranslationKey.clipListDeleteRecordDialogContent.tr,
        title: TranslationKey.deleteTips.tr,
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
        showCancel: true,
        showNeutral: item.isFile || item.isImage,
        neutralText: TranslationKey.deleteWithFiles.tr,
        onOk: () => deleteItem(item, onlyDeleteLocal: onlyDeleteLocal.value),
        onNeutral: () => deleteItem(item, deleteFile: true, onlyDeleteLocal: onlyDeleteLocal.value),
      );
    }
    showClipBottomSheet(ClipData data){
      showModalBottomSheet(
        isScrollControlled: true,
        clipBehavior: Clip.antiAlias,
        context: context,
        elevation: 100,
        builder: (BuildContext context) {
          return SafeArea(
            child: ClipDetailDialog(
              dlgContext: context,
              clip: data,
              onLocate: locate,
              onUpdate: widget.onUpdate,
              onRemoveClicked: onRemoveClicked,
            ),
          );
        },
      );
    }

    return ClipDataCard(
      clip: item,
      onLocate: locate,
      imageMode: _anchor == null && widget.imageMasonryGridViewLayout,
      routeToSearchOnClickChip: widget.enableRouteSearch,
      selectMode: _selectionController.enabled,
      selected: _selectionController.contains(item),
      onTap: () {
        if (_selectionController.enabled) {
          _toggleSelectState(item);
        } else {
          var data = item;
          if (isBigScreen) {
            homeCtrl.pushDrawer(
              widget: ClipboardDetailDrawer(clipData: data),
              beforeClosed: () {
                homeCtrl.resetDrawerWidth();
                return true;
              },
            );
          } else {
            showClipBottomSheet(data);
          }
        }
      },
      onToggleSelected: (){
        if (!_selectionController.enabled) {
          _enableSelectMode();
        }
        HapticFeedback.mediumImpact();
        _selectionController.selectRange(List<ClipData>.from(widget.list), item);
        _refreshState();
      },
      onMoreActionsTap: (){
        showClipBottomSheet(item);
      },
      onLongPress: () {
        _enableSelectMode();
        _selectionController.toggleItem(item);
        HapticFeedback.mediumImpact();
        _refreshState();
      },
      onDoubleTap: () async {
        if (item.isFile) {
          await OpenFile.open(item.data.content);
          return;
        }
        History history = item.data;
        history.copyContent(context: context, showFeedback: true);
      },
      onUpdate: widget.onUpdate,
      onRemoveClicked: onRemoveClicked,
    );
  }
}
