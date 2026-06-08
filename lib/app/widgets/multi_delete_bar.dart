import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class MultiDeleteBar extends StatefulWidget implements PreferredSizeWidget {
  final bool automaticallyImplyLeading;
  final Widget normalChild;
  final void Function()? onCancel;
  final void Function(List<dynamic> selected) onDelete;

  const MultiDeleteBar({
    super.key,
    required this.normalChild,
    this.automaticallyImplyLeading = false,
    this.onCancel,
    required this.onDelete,
  });

  @override
  State<StatefulWidget> createState() {
    return MultiDeleteBarState();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MultiDeleteBarState extends State<MultiDeleteBar> {
  int _total = 0;
  final List<dynamic> _selected = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
  }

  void setItemsCnt(int total) {
    assert(total >= 0);
    if (total > 0) {
      assert(total > _selected.length);
    }
    if (total == 0) {
      clear();
    } else {
      _total = total;
    }
    setState(() {});
  }

  bool get isSelecting => _total > 0;

  int get selectedLength => _selected.length;

  bool addOrRemoveWillDeleteItem(
      dynamic item, bool Function(dynamic item) test) {
    int beforeCnt = _selected.length;
    _selected.removeWhere(test);
    int afterCnt = _selected.length;
    bool isAdd = beforeCnt == afterCnt;
    if (isAdd) {
      _selected.add(item);
    }
    setState(() {});
    return isAdd;
  }

  void clear() {
    _total = 0;
    _selected.clear();
    widget.onCancel?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _total > 0
        ? AppBar(
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            title: Text(
              TranslationKey.multiChoiceModeSelectedText
                  .trParams({"text": '${_selected.length}/$_total'}),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  clear();
                },
                icon: const Icon(Icons.close),
              ),
              IconButton(
                onPressed: () {
                  clear();
                  widget.onDelete(_selected);
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          )
        : widget.normalChild;
  }
}
