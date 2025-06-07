import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/widgets/filter/filter_detail.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HistoryFilter extends StatefulWidget {
  List<Device> allDevices;
  List<String> allTagNames;
  Future<void> Function() loadSearchCondition;
  bool isBigScreen;
  bool showContentTypeFilter;
  SearchFilter? filter;
  void Function()? onExportBtnClicked;
  void Function(SearchFilter filter) onChanged;

  HistoryFilter({
    super.key,
    required this.allDevices,
    required this.allTagNames,
    required this.loadSearchCondition,
    required this.isBigScreen,
    this.showContentTypeFilter = true,
    required this.onChanged,
    this.onExportBtnClicked,
    this.filter,
  });

  @override
  State<StatefulWidget> createState() => _HistoryFilterState();
}

class _HistoryFilterState extends State<HistoryFilter> {
  bool loading = true;
  TextEditingController textController = TextEditingController();
  FocusNode searchFocus = FocusNode();
  var filter = SearchFilter();

  bool get hasMoreCondition {
    return filter.tags.isNotEmpty || filter.devIds.isNotEmpty || filter.onlyNoSync || filter.endDate.isNotEmpty || filter.startDate.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (widget.filter != null) {
      filter = widget.filter!;
      textController.text = filter.content;
    }
  }

  void notifyChanged() {
    widget.onChanged(filter.copy());
    if (PlatformExt.isDesktop) {
      searchFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: TextField(
                    controller: textController,
                    focusNode: searchFocus,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                      ),
                      hintText: TranslationKey.search.tr,
                      border: widget.isBigScreen || PlatformExt.isDesktop
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4), // 边框圆角
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1.0,
                              ), // 边框样式
                            )
                          : InputBorder.none,
                      suffixIcon: InkWell(
                        onTap: () {
                          filter.content = textController.text;
                          notifyChanged();
                        },
                        splashColor: Colors.black12,
                        highlightColor: Colors.black12,
                        borderRadius: BorderRadius.circular(50),
                        child: Tooltip(
                          message: TranslationKey.search.tr,
                          child: const Icon(
                            Icons.search_rounded,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                    onSubmitted: (value) {
                      filter.content = value;
                      notifyChanged();
                    },
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, right: 5),
                child: IconButton(
                  onPressed: () async {
                    await widget.loadSearchCondition();
                    final filterDetail = FilterDetail(
                      searchFilter: filter,
                      allDevices: widget.allDevices,
                      allTagNames: widget.allTagNames,
                      isBigScreen: widget.isBigScreen,
                      onConfirm: (filter) {
                        this.filter = filter;
                        setState(() {});
                        notifyChanged();
                        Get.back();
                      },
                    );
                    if (widget.isBigScreen) {
                      final homeController = Get.find<HomeController>();
                      homeController.openEndDrawer(drawer: filterDetail);
                    } else {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        clipBehavior: Clip.antiAlias,
                        context: context,
                        builder: (context) => filterDetail,
                      );
                    }
                  },
                  tooltip: TranslationKey.moreFilter.tr,
                  icon: Icon(
                    hasMoreCondition ? Icons.playlist_add_check_outlined : Icons.menu_rounded,
                    color: hasMoreCondition ? Colors.blueAccent : null,
                  ),
                ),
              ),
              if (widget.onExportBtnClicked != null)
                Container(
                  margin: const EdgeInsets.only(left: 5, right: 5),
                  child: IconButton(
                    onPressed: widget.onExportBtnClicked,
                    tooltip: TranslationKey.export2Excel.tr,
                    icon: Icon(
                      MdiIcons.export,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.showContentTypeFilter)
            Container(
              margin: const EdgeInsets.only(top: 5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var type in [
                      HistoryContentType.all,
                      HistoryContentType.text,
                      HistoryContentType.image,
                      HistoryContentType.file,
                      HistoryContentType.sms,
                    ])
                      Row(
                        children: [
                          RoundedChip(
                            selected: filter.type.label == type.label,
                            onPressed: () {
                              if (filter.type.label == type.label) {
                                return;
                              }
                              setState(() {
                                loading = true;
                                filter.type = type;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                notifyChanged,
                              );
                            },
                            selectedColor: filter.type == type ? Theme.of(context).chipTheme.selectedColor : null,
                            label: Text(type.label),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
