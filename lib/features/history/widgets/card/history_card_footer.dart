import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:flutter/material.dart';

///历史记录中的卡片显示的额外信息部分，如时间，大小等
class HistoryCardFooter extends StatefulWidget {
  final History history;

  const HistoryCardFooter({
    super.key,
    required this.history,
  });

  @override
  State<StatefulWidget> createState() {
    return _HistoryCardFooterState();
  }
}

class _HistoryCardFooterState extends State<HistoryCardFooter> {
  bool _showSimpleTime = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          widget.history.top ? const Icon(Icons.push_pin, size: 16) : const SizedBox.shrink(),
          widget.history.sync
              ? const SizedBox.shrink()
              : const Icon(
                  Icons.sync,
                  size: 16,
                  color: Colors.red,
                ),
          GestureDetector(
            child: Text(
              _showSimpleTime ? widget.history.timeStr : widget.history.time.substring(0, 19),
            ),
            onTap: () {
              setState(() {
                _showSimpleTime = !_showSimpleTime;
              });
            },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 10),
          ),
          Text(widget.history.sizeText),
        ],
      ),
    );
  }
}
