import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class UserGuideController extends GetxController with WidgetsBindingObserver {
  final current = 0.obs;
  final canNextGuide = false.obs;
  final isInitFinished = false.obs;
  final PageController pageController = PageController();
  final List<BaseGuide> guides;
  var _gotoHomePageLock = false;

  UserGuideController(this.guides);

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    if (guides.isEmpty) {
      gotoHomePage();
      return;
    }
    var f = Future(() => true);
    //只要有一个返回false就要走引导，如果全部返回true，直接跳转主页
    for (var guide in guides) {
      f = f.then((v) {
        if (v != true) return false;
        return guide.canNext();
      });
    }
    f.then((v) {
      if (v) {
        gotoHomePage();
      } else {
        isInitFinished.value = true;
      }
    });
    if (guides.isNotEmpty) {
      guides[current.value].canNext().then((v) {
        canNextGuide.value = v;
      });
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      var canNext = await guides[current.value].canNext();
      canNextGuide.value = canNext;
    }
  }

  //endregion

  //region 页面方法

  ///跳转上一项
  void gotoPre() async {
    if (current.value != 0) {
      current.value -= 1;
      await updateCanNext();
      pageController.previousPage(
        duration: 200.ms,
        curve: Curves.ease,
      );
    }
  }

  Future<void> updateCanNext() async {
    canNextGuide.value = await guides[current.value].canNext() || guides[current.value].allowSkip;
  }

  ///跳转下一项
  void gotoNext() async {
    if (current.value != guides.length - 1) {
      //允许下一步
      if (canNextGuide.value || guides[current.value].allowSkip) {
        current.value += 1;
        pageController.nextPage(
          duration: 200.ms,
          curve: Curves.ease,
        );
        await updateCanNext();
      }
    }
  }

  void gotoHomePage() {
    if (_gotoHomePageLock) {
      return;
    }
    _gotoHomePageLock = true;
    Get.offNamed(Routes.HOME);
  }

  //endregion
}
