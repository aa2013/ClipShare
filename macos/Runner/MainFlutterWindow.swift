import Cocoa
import FlutterMacOS
import LaunchAtLogin
import desktop_multi_window
import window_manager
import desktop_drop

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Add FlutterMethodChannel platform code
    FlutterMethodChannel(
        name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(LaunchAtLogin.isEnabled)
      case "launchAtStartupSetEnabled":
        if let arguments = call.arguments as? [String: Any] {
            LaunchAtLogin.isEnabled = arguments["setEnabledValue"] as! Bool
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    //
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
        // 注册插件到当前窗口
        WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
        DesktopDropPlugin.register(with: controller.registrar(forPlugin: "DesktopDropPlugin"))
    }
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
