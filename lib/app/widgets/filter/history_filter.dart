import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/widgets/filter/filter_detail.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HistoryFilterController {
  final allDevices = <Device>[].obs;
  final allTagNames = <String>[].obs;
  final allSources = <AppInfo>[].obs;
  final bool isBigScreen;
  final bool showContentTypeFilter;
  final void Function()? onExportBtnClicked;
  final void Function() onSearchBtnClicked;
  final Future<void> Function() loadSearchCondition;
  final void Function(SearchFilter filter) onChanged;
  final focusNode = FocusNode();
  final TextEditingController textController = TextEditingController();
  final loading = false.obs;

  SearchFilter get filter => SearchFilter(
        content: content.value,
        startDate: startDate.value,
        endDate: endDate.value,
        tags: selectedTags.value,
        devIds: selectedDevIds.value,
        appIds: selectedAppIds.value,
        onlyNoSync: onlyNoSync.value,
        type: selectedType.value,
      );

  ///region filter
  final content = "".obs;
  final startDate = "".obs;
  final endDate = "".obs;
  final selectedTags = <String>{}.obs;
  final selectedDevIds = <String>{}.obs;
  final selectedAppIds = <String>{}.obs;
  final onlyNoSync = false.obs;
  final selectedType = HistoryContentType.all.obs;

  ///endregion

  String get startDateStr => startDate.value == "" ? TranslationKey.startDate.tr : startDate.value;

  String get endDateStr => endDate.value == "" ? TranslationKey.endDate.tr : endDate.value;

  String get nowDayStr => DateTime.now().toString().substring(0, 10);

  bool get hasMoreCondition {
    return selectedTags.isNotEmpty || selectedDevIds.isNotEmpty || onlyNoSync.value || endDate.isNotEmpty || startDate.isNotEmpty || selectedAppIds.isNotEmpty;
  }

  HistoryFilterController({
    required List<Device> allDevices,
    required List<String> allTagNames,
    required List<AppInfo> allSources,
    required this.isBigScreen,
    required this.loadSearchCondition,
    required this.onChanged,
    required SearchFilter filter,
    required this.onSearchBtnClicked,
    this.showContentTypeFilter = true,
    this.onExportBtnClicked,
  }) {
    this.allDevices.addAll(allDevices);
    this.allTagNames.addAll(allTagNames);
    this.allSources.addAll(allSources);
    resetFilter(filter: filter);
  }

  void setAllDevices(List<Device> devices) {
    allDevices.value = devices;
  }

  void setAllTagNames(List<String> tagNames) {
    allTagNames.value = tagNames;
  }

  void setAllSources(List<AppInfo> sources) {
    allSources.value = sources;
  }

  void resetFilter({SearchFilter? filter}) {
    filter ??= SearchFilter();
    content.value = filter.content;
    startDate.value = filter.startDate;
    endDate.value = filter.endDate;
    selectedTags.addAll(filter.tags);
    selectedDevIds.addAll(filter.devIds);
    selectedAppIds.addAll(filter.appIds);
    onlyNoSync.value = filter.onlyNoSync;
    selectedType.value = filter.type;
  }

  String getDevNameById(devId) {
    return allDevices
        .firstWhereOrNull((item) => item.guid == devId)
        ?.name ?? "Unknown";
  }
}

class HistoryFilter extends StatelessWidget {
  final HistoryFilterController controller;

  const HistoryFilter({
    super.key,
    required this.controller,
  });

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
                    controller: controller.textController,
                    focusNode: controller.focusNode,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                      ),
                      hintText: TranslationKey.search.tr,
                      border: controller.isBigScreen || PlatformExt.isDesktop
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
                          controller.content.value = controller.textController.text;
                          controller.onSearchBtnClicked();
                          controller.focusNode.requestFocus();
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
                      controller.content.value = value;
                      controller.focusNode.requestFocus();
                      controller.onSearchBtnClicked();
                    },
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 5, right: 5),
                child: IconButton(
                  onPressed: () async {
                    await controller.loadSearchCondition();
                    final filterDetail = FilterDetail(
                      controller: controller,
                      onConfirm: (filter) {
                        controller.onChanged(filter);
                        Get.back();
                      },
                    );
                    if (controller.isBigScreen) {
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
                  icon: Obx(
                    () => Icon(
                      controller.hasMoreCondition ? Icons.playlist_add_check_outlined : Icons.menu_rounded,
                      color: controller.hasMoreCondition ? Colors.blueAccent : null,
                    ),
                  ),
                ),
              ),
              if (controller.onExportBtnClicked != null)
                Container(
                  margin: const EdgeInsets.only(left: 5, right: 5),
                  child: IconButton(
                    onPressed: controller.onExportBtnClicked,
                    tooltip: TranslationKey.export2Excel.tr,
                    icon: Icon(
                      MdiIcons.export,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (controller.showContentTypeFilter)
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
                          Obx(
                            () => RoundedChip(
                              selected: controller.selectedType.value.label == type.label,
                              onPressed: () {
                                if (controller.selectedType.value.label == type.label) {
                                  return;
                                }
                                controller.loading.value = true;
                                controller.selectedType.value = type;
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                  () {
                                    controller.onChanged(controller.filter);
                                  },
                                );
                              },
                              selectedColor: controller.selectedType.value == type ? Theme.of(context).chipTheme.selectedColor : null,
                              label: Text(type.label),
                            ),
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
