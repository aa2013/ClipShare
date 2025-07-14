import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/views/tag_edit_page.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClipTagRowView extends StatelessWidget {
  final int hisId;
  final Color? clipBgColor;
  final bool? routeToSearchOnClickChip;
  final homeController = Get.find<HomeController>();

  final tagService = Get.find<TagService>();
  bool? showAddIcon = false;

  ClipTagRowView({
    super.key,
    required this.hisId,
    this.clipBgColor,
    this.routeToSearchOnClickChip,
    this.showAddIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () {
          var tags = tagService.getTagList(hisId);
          return Row(
            children: [
              for (var tag in tags)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  child: RoundedChip(
                    onPressed: () {
                      if (routeToSearchOnClickChip == true) {
                        //导航至搜索页面
                        homeController.gotoSearchPage(null, tag);
                      }
                    },
                    avatar: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ConditionWidget(
                visible: showAddIcon == true,
                child: const SizedBox(width: 5),
              ),
              ConditionWidget(
                visible: showAddIcon == true,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    TagEditPage.goto(hisId);
                  },
                  icon: Row(
                    children: [
                      Text(TranslationKey.tag.tr),
                      const Icon(Icons.add, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
