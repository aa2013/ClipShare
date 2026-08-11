#include "flutter_window.h"

#include <codecvt>
#include <Windows.h>
#include <cstdio>

#include <optional>
#include <thread>
#include <vector>
#include <.plugin_symlinks/desktop_multi_window/windows/base_flutter_window.h>
#include <flutter/encodable_value.h>

#include "flutter/standard_method_codec.h"
#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include <shlobj.h>
#include <atlbase.h> // CComPtr
#include "utils.h"
#include "window_manager/window_manager_plugin.h"
#include <irondash_engine_context/irondash_engine_context_plugin_c_api.h>
#include <super_native_extensions/super_native_extensions_plugin_c_api.h>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
	: project_(project) {
}

FlutterWindow::~FlutterWindow() {
}

bool FlutterWindow::OnCreate() {
	if (!Win32Window::OnCreate()) {
		return false;
	}

	RECT frame = GetClientArea();

	// The size here must match the window dimensions to avoid unnecessary surface
	// creation / destruction in the startup path.
	flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
		frame.right - frame.left, frame.bottom - frame.top, project_);
	// Ensure that basic setup of the controller was successful.
	if (!flutter_controller_->engine() || !flutter_controller_->view()) {
		return false;
	}
	RegisterPlugins(flutter_controller_->engine());
	SetChildContent(flutter_controller_->view()->GetNativeWindow());

	DesktopMultiWindowSetWindowCreatedCallback([](void* controller) {
		auto* flutter_view_controller = reinterpret_cast<flutter::FlutterViewController*>(controller);
		auto* registry = flutter_view_controller->engine();
		WindowManagerPluginRegisterWithRegistrar(registry->GetRegistrarForPlugin("WindowManagerPlugin"));
		IrondashEngineContextPluginCApiRegisterWithRegistrar(registry->GetRegistrarForPlugin("IrondashEngineContextPluginCApi"));
		SuperNativeExtensionsPluginCApiRegisterWithRegistrar(registry->GetRegistrarForPlugin("SuperNativeExtensionsPluginCApi"));
	});

	// 点击外部关闭弹窗：注册 Raw Input(RIDEV_INPUTSINK) 全局鼠标监听。
	// 无需前台焦点即可接收鼠标事件；sink 用主窗口 HWND，WM_INPUT 由主线程消息循环处理。
	click_outside_channel_ = new flutter::MethodChannel<flutter::EncodableValue>(
		flutter_controller_->engine()->messenger(), "clipshare/click_outside",
		&flutter::StandardMethodCodec::GetInstance());
	click_outside_channel_->SetMethodCallHandler(
		[this](const flutter::MethodCall<flutter::EncodableValue>& call,
			   std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
			if (call.method_name() == "enable") {
				// 弹窗显示期间开启监听；带 500ms 宽限期，避免弹窗刚显示时被误关。
				// 真正原因：enable 在窗口可见之前发出（Dart 侧先 enable 再走 IPC 显示），
				// 冷创建时窗口出现前的延迟可能超过 150ms，宽限期过短会在弹窗刚出现时
				// 把用户随后的第一次点击当成 dismiss。500ms 与子窗口 onWindowBlur 的抑制一致。
				watching_click_ = true;
				watching_since_ = GetTickCount64();
				result->Success();
			} else if (call.method_name() == "disable") {
				watching_click_ = false;
				result->Success();
			} else {
				result->NotImplemented();
			}
		});

	RAWINPUTDEVICE rid{};
	rid.usUsagePage = 0x01;  // Generic Desktop
	rid.usUsage = 0x02;      // Mouse
	rid.dwFlags = RIDEV_INPUTSINK;
	rid.hwndTarget = GetHandle();
	// 注册失败时整个点击检测会静默失效且无从诊断，故检查返回值并输出日志
	// （OutputDebugStringA 可用 DebugView 观察；失败常见于窗口句柄无效/重复注册）。
	if (!RegisterRawInputDevices(&rid, 1, sizeof(rid))) {
		char buf[128];
		sprintf_s(buf, sizeof(buf), "[clipshare] RegisterRawInputDevices(INPUTSINK) failed, err=%lu", GetLastError());
		OutputDebugStringA(buf);
	}

	flutter_controller_->ForceRedraw();
	return true;
}

void FlutterWindow::OnDestroy() {
	// 反注册 Raw Input，避免窗口销毁后残留监听。
	// 注意：RIDEV_REMOVE 是按进程移除鼠标 raw input 注册（非按窗口）——若未来有其他
	// 插件（如 super_native_extensions）注册了鼠标 raw input，会被此处连带移除，需留意。
	RAWINPUTDEVICE rid{};
	rid.usUsagePage = 0x01;
	rid.usUsage = 0x02;
	rid.dwFlags = RIDEV_REMOVE;
	rid.hwndTarget = nullptr;
	RegisterRawInputDevices(&rid, 1, sizeof(rid));

	delete click_outside_channel_;
	click_outside_channel_ = nullptr;

	if (flutter_controller_) {
		flutter_controller_ = nullptr;
	}

	Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
	WPARAM const wparam,
	LPARAM const lparam)

	noexcept
{
	// Give Flutter, including plugins, an opportunity to handle window messages.
	if (flutter_controller_)
	{
		std::optional <LRESULT> result =
			flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
				lparam);
		if (result)
		{
			return *
				result;
		}
	}

	switch (message)
	{
	case WM_FONTCHANGE:
		flutter_controller_->engine()->ReloadSystemFonts();
		break;
	case WM_INPUT: {
		// 弹窗可见期间监听全局鼠标按下：点击非本进程窗口 → 通知 Dart 关闭弹窗。
		// 宽限期 500ms（与 enable 侧一致）：覆盖弹窗显示初期的点击，避免刚出现就被误关。
		if (watching_click_ && GetTickCount64() - watching_since_ >= 500) {
			UINT size = 0;
			if (GetRawInputData((HRAWINPUT)lparam, RID_INPUT, nullptr, &size,
								sizeof(RAWINPUTHEADER)) != (UINT)-1 && size > 0) {
				std::vector<BYTE> buffer(size);
				if (GetRawInputData((HRAWINPUT)lparam, RID_INPUT, buffer.data(), &size,
									sizeof(RAWINPUTHEADER)) != (UINT)-1) {
					RAWINPUT* raw = reinterpret_cast<RAWINPUT*>(buffer.data());
					if (raw->header.dwType == RIM_TYPEMOUSE) {
						const USHORT down = raw->data.mouse.usButtonFlags &
							(RI_MOUSE_LEFT_BUTTON_DOWN | RI_MOUSE_RIGHT_BUTTON_DOWN |
							 RI_MOUSE_MIDDLE_BUTTON_DOWN | RI_MOUSE_BUTTON_4_DOWN |
							 RI_MOUSE_BUTTON_5_DOWN);
						if (down) {
							POINT pt;
							GetCursorPos(&pt);
							HWND root = GetAncestor(WindowFromPoint(pt), GA_ROOT);
							DWORD pid = 0;
							if (root) {
								GetWindowThreadProcessId(root, &pid);
							}
							// 点击非本进程窗口视为外部（点击主窗口/弹窗不触发）
							if (pid != GetCurrentProcessId() && click_outside_channel_) {
								click_outside_channel_->InvokeMethod(
									"onClickOutside",
									std::make_unique<flutter::EncodableValue>());
							}
						}
					}
				}
			}
		}
		// WM_INPUT 必须交给 DefWindowProc 完成清理
		return DefWindowProc(hwnd, message, wparam, lparam);
	}
	}

	return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
