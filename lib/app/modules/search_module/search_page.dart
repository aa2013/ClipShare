import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart' as search_module;
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/filter/filter_type_segmented.dart';
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
        body: SafeArea(
          child: Padding(
            padding: 5.insetH,
            child: Column(
              children: [
                FilterTypeSegmented(
                  onSelected: (type) {
                    if (controller.searchType.label == type.label) {
                      return;
                    }
                    controller.loading.value = true;
                    controller.searchType = type;
                    Future.delayed(300.ms, controller.refreshData);
                  },
                ),
                Expanded(
                  child: ConditionWidget(
                    visible: controller.loading.value,
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
                    child: const Loading(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
