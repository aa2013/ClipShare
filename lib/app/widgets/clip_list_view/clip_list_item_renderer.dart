part of '../clip_list_view.dart';

extension _ClipListItemRenderer on ClipListViewState {
  Widget renderItem(int i) {
    var item = widget.list[i];
    onRemoveClicked(ClipData item) {
      final onlyDeleteLocal = false.obs;
      Global.showTipsDialog(
        context: context,
        text: TranslationKey.deleteRecordAck.tr,
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
              onUpdate: widget.onUpdate,
              onRemoveClicked: onRemoveClicked,
            ),
          );
        },
      );
    }

    return ClipDataCard(
      clip: widget.list[i],
      imageMode: widget.imageMasonryGridViewLayout,
      routeToSearchOnClickChip: widget.enableRouteSearch,
      selectMode: _selectMode,
      selected: _selectedItems.contains(item),
      onTap: () {
        if (_selectMode) {
          _toggleSelectState(item);
        } else {
          var data = widget.list[i];
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
        if (!_selectMode) {
          _enableSelectMode();
        }
        HapticFeedback.mediumImpact();
        if (_selectedItems.isEmpty || _selectedItems.contains(item)) {
          _toggleSelectState(item);
          return;
        }
        var reverse = false;
        var list = List.from(widget.list);
        var start = -1;
        var end = -1;
        for (var i = 0; i < list.length; i++) {
          if (!reverse && list[i] == item && start == -1) {
            reverse = true;
          }
          if (reverse) {
            if (list[i] == item) {
              start = i;
            } else if (_selectedItems.contains(list[i])) {
              end = i;
            }
          } else {
            if (_selectedItems.contains(list[i]) && start == -1) {
              start = i;
            }
            if (list[i] == item && start != -1) {
              end = i;
              break;
            }
          }
        }
        for (var i = start; i <= end; i++) {
          _selectedItems.add(list[i]);
        }
        _refreshState();

      },
      onMoreActionsTap: (){
        showClipBottomSheet(widget.list[i]);
      },
      onLongPress: () {
        _enableSelectMode();
        _selectedItems.add(item);
        HapticFeedback.mediumImpact();
      },
      onDoubleTap: () async {
        if (widget.list[i].isFile) {
          await OpenFile.open(widget.list[i].data.content);
          return;
        }
        History history = widget.list[i].data;
        history.copyContent(context: context, showFeedback: true);
      },
      onUpdate: widget.onUpdate,
      onRemoveClicked: onRemoveClicked,
    );
  }
}
