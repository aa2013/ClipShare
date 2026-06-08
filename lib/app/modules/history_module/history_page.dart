import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/filter/history_filter.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistoryPage extends GetView<HistoryController> {
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.filterLoading.value) {
          return const Loading();
        }
        return Padding(
          padding: 6.insetAll,
          child: Column(
            children: [
              HistoryFilter(
                controller: controller.filterController,
                showFillColor: PlatformExt.isDesktop || !controller.appConfig.isSmallScreen,
                showSearchRow: !controller.appConfig.isSmallScreen,
              ),
              const SizedBox(height: 5),
              Expanded(
                child: GetBuilder<HistoryController>(
                  builder: (controller) => Obx(
                    () => IndexedStack(
                      index: controller.loading ? 1 : 0,
                      children: [
                        ClipListView(
                          list: controller.list,
                          parentController: controller,
                          onRefreshData: controller.refreshData,
                          enableRouteSearch: true,
                          onLoadMoreData: controller.loadData,
                          imageMasonryGridViewLayout: controller.listContentType == HistoryContentType.image,
                          onUpdate: () {
                            controller.debounceUpdate();
                            controller.notifyHistoryWindow();
                          },
                          onRemove: (id) {
                            controller.removeById(id);
                            controller.updateLatestLocalClip();
                          },
                        ),
                        const Loading(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
