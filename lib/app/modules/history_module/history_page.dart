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
        final isSmallScreen = controller.appConfig.isSmallScreen;
        return Padding(
          padding: isSmallScreen ? const EdgeInsets.fromLTRB(6, 6, 6, 0) : 6.insetAll,
          child: Column(
            children: [
              HistoryFilter(
                controller: controller.filterController,
                showFillColor: PlatformExt.isDesktop || !isSmallScreen,
                showSearchRow: !isSmallScreen,
              ),
              const SizedBox(height: 5),
              Expanded(
                child: GetBuilder<HistoryController>(
                  builder: (controller) => Obx(
                    () => IndexedStack(
                      index: controller.loading ? 1 : 0,
                      children: [
                        // 隐藏的 child 需禁用 Ticker，否则其无限动画（如加载指示器）会在后台持续驱动帧渲染
                        TickerMode(
                          enabled: !controller.loading,
                          child: ClipListView(
                            list: controller.list,
                            parentController: controller,
                            padding: isSmallScreen ? EdgeInsets.zero : null,
                            onRefreshData: () {
                              controller.refreshData(showLoading: false);
                            },
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
                        ),
                        TickerMode(
                          enabled: controller.loading,
                          child: const Loading(),
                        ),
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
