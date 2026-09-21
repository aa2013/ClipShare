/// 窗体控制按钮点击回调
abstract mixin class WindowControlClickedListener {
  void onCloseBtnClicked(bool isHide) {}

  void onMaximizeBtnClicked() {}

  void onMinimizeBtnClicked() {}

  void onUnMaximizeBtnClicked() {}
}
