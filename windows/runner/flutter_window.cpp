﻿#include "flutter_window.h"

#include <codecvt>
#include <Windows.h>

#include <optional>
#include <thread>
#include <.plugin_symlinks/desktop_multi_window/windows/base_flutter_window.h>
#include <flutter/encodable_value.h>

#include "flutter/standard_method_codec.h"
#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include <vector>
#include <shlobj.h>
#include <atlbase.h> // CComPtr
#include "utils.h"
#include "window_manager/window_manager_plugin.h"

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
		//HWND hwnd = flutter_view_controller->view()->GetNativeWindow();
		//hwnd = GetParent(hwnd);
		//// 获取当前窗口样式
		//LONG style = GetWindowLong(hwnd, GWL_STYLE);

		//// 移除最大化和最小化按钮的样式标志
		//style &= ~WS_MAXIMIZEBOX; // 移除最大化按钮
		//style &= ~WS_MINIMIZEBOX; // 移除最小化按钮
		//// 添加WS_POPUP样式，使窗口成为弹窗
		//style |= WS_POPUP;

		//// 设置新的窗口样式
		//SetWindowLong(hwnd, GWL_STYLE, style);

		////设置置顶
		//::SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
		});
	flutter_controller_->ForceRedraw();
	return true;
}

void FlutterWindow::OnDestroy() {
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
	}

	return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
