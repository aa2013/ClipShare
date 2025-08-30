import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart' as search_module;
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/filter/history_filter.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SearchPage extends GetView<search_module.SearchController> {
  final appConfig = Get.find<ConfigService>();

  @override
  Widget build(BuildContext context) {
    controller.screenWidth = MediaQuery.of(context).size.width;
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: controller.isBigScreen ? 0 : null,
          automaticallyImplyLeading: !controller.isBigScreen,
          backgroundColor: controller.isBigScreen ? Colors.transparent : Theme.of(context).colorScheme.inversePrimary,
          title: Obx(
            () {
              if (controller.filterLoading.value) {
                return const SizedBox.shrink();
              }
              return HistoryFilter(controller: controller.filterController);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
          child: Column(
            children: [
              const SizedBox(
                height: 5,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var type in [
                      HistoryContentType.all,
                      HistoryContentType.text,
                      HistoryContentType.image,
                      HistoryContentType.file,
                      HistoryContentType.sms,
                      HistoryContentType.notification,
                    ])
                      Row(
                        children: [
                          RoundedChip(
                            selected: controller.searchType.label == type.label,
                            onPressed: () {
                              if (controller.searchType.label == type.label) {
                                return;
                              }
                              controller.loading.value = true;
                              controller.searchType = type;
                              Future.delayed(200.ms, controller.refreshData);
                            },
                            selectedColor: controller.searchType == type ? Theme.of(context).chipTheme.selectedColor : null,
                            label: Text(type.label),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Expanded(
                child: ConditionWidget(
                  visible: controller.loading.value,
                  child: const Loading(),
                  replacement: ClipListView(
                    list: controller.list,
                    parentController: controller,
                    onRefreshData: controller.refreshData,
                    onUpdate: controller.sortList,
                    onRemove: (id) {
                      controller.list.removeWhere(
                        (element) => element.data.id == id,
                      );
                    },
                    onLoadMoreData: (minId) {
                      return controller.loadData(minId);
                    },
                    detailBorderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    imageMasonryGridViewLayout: controller.searchType == HistoryContentType.image,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
