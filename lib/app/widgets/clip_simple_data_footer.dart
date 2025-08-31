import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:flutter/material.dart';

///历史记录中的卡片显示的额外信息部分，如时间，大小等
class ClipSimpleDataFooter extends StatefulWidget {
  final ClipData clip;

  const ClipSimpleDataFooter({super.key, required this.clip});

  @override
  State<StatefulWidget> createState() {
    return _ClipSimpleDataFooterState();
  }
}

class _ClipSimpleDataFooterState extends State<ClipSimpleDataFooter> {
  bool _showSimpleTime = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          widget.clip.data.top
              ? const Icon(Icons.push_pin, size: 16)
              : const SizedBox.shrink(),
          widget.clip.data.sync
              ? const SizedBox.shrink()
              : const Icon(
                  Icons.sync,
                  size: 16,
                  color: Colors.red,
                ),
          GestureDetector(
            child: Text(
              _showSimpleTime
                  ? widget.clip.timeStr
                  : widget.clip.data.time.substring(0, 19),
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
          Text(widget.clip.sizeText),
        ],
      ),
    );
  }
}
