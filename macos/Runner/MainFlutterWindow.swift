import Cocoa
import FlutterMacOS
import LaunchAtLogin
import desktop_multi_window
import window_manager
import irondash_engine_context
import super_native_extensions

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
        // 多窗口引擎不会自动复用主窗口插件注册表，需要把子窗口依赖的原生插件补注册。
        WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
        IrondashEngineContextPlugin.register(with: controller.registrar(forPlugin: "IrondashEngineContextPlugin"))
        SuperNativeExtensionsPlugin.register(with: controller.registrar(forPlugin: "SuperNativeExtensionsPlugin"))
    }
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
      super.order(place, relativeTo: otherWin)
      hiddenWindowAtLaunch()
  }
}
