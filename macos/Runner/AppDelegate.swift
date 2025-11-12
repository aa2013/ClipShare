import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // 返回 false 表示所有窗口都关闭后也不要退出程序
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
      // 如果窗口已经隐藏，点击 Dock 栏的图标让app重新前台显示
      if !flag {
          for window in NSApp.windows {
              if !window.isVisible {
                  window.setIsVisible(true)
              }
              window.makeKeyAndOrderFront(self)
              NSApp.activate(ignoringOtherApps: true)
          }
      }
      return true
  }
}
