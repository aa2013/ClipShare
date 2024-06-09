﻿#include "clip_listener_window.h"

#include <codecvt>
#include <sstream>
#include <flutter/encodable_value.h>
#include "flutter/standard_method_codec.h"
#include <atlenc.h>
#include <fstream>
#include <atlimage.h>
#include <chrono>
#include <filesystem>
#include <regex>
namespace fs = std::filesystem;
typedef unsigned char uchar;
bool INNER_COPY = FALSE;
#pragma warning(disable : 4996)  // 禁用废弃警告
#pragma warning(disable : 4334)  // 禁用警告：32 位移位的结果被隐式转换为 64 位(是否希望进行 64 位移位?) 
ClipListenerWindow::ClipListenerWindow(flutter::MethodChannel<flutter::EncodableValue>* channel): channel_(channel)
{
}

ClipListenerWindow::~ClipListenerWindow()
{
}

std::string GetCurrentTimeWithMilliseconds()
{
	// 获取当前时间点
	auto now = std::chrono::system_clock::now();

	// 将时间点转换为 time_t 类型
	std::time_t time = std::chrono::system_clock::to_time_t(now);

	// 获取时间结构体
	std::tm tm_time = *std::localtime(&time);

	// 获取毫秒数
	auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

	// 格式化时间字符串
	std::ostringstream oss;
	oss << std::put_time(&tm_time, "%Y-%m-%d %H:%M:%S") << '.' << std::setw(3) << std::setfill('0') << milliseconds.
		count();

	return oss.str();
}

std::wstring Utf16FromUtf8(const std::string& string)
{
	int size_needed = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), -1, nullptr, 0);
	if (size_needed == 0)
	{
		return {};
	}
	std::wstring wstrTo(size_needed, 0);
	int converted_length = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), -1, &wstrTo[0], size_needed);
	if (converted_length == 0)
	{
		return {};
	}
	return wstrTo;
}

bool ClipListenerWindow::OnCreate()
{
	if (!Win32Window::OnCreate())
	{
		return false;
	}

	channel_->SetMethodCallHandler([this](const auto& call, auto result)
	{
		if (call.method_name() == "copy")
		{
			INNER_COPY = TRUE;
			auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
			auto type = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
			auto content = std::get<std::string>(arguments->at(flutter::EncodableValue("content")));
			bool res = InnerCopy(type, content);
			result->Success(flutter::EncodableValue(res));
		}
	});
	// std::stringstream ss;
	// ss << GetHandle();
	// std::string s("listener handle: " + ss.str() + "\n");
	// std::wstring wideString(s.begin(), s.end());
	// OutputDebugString(wideString.c_str());
	// 注册为剪贴板查看器
	hWndNextViewer_ = SetClipboardViewer(GetHandle());

	return true;
}

void ClipListenerWindow::OnDestroy()
{
	Win32Window::OnDestroy();
	// 移除剪贴板查看器
	ChangeClipboardChain(GetHandle(), hWndNextViewer_);
}

void ClipListenerWindow::SendClip(std::string& type, std::wstring& content)
{
	// 定义一个 locale，用于字符集转换
	std::locale loc("en_US.UTF-8");

	// 创建一个 codecvt 对象
	std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;

	// 将宽字符字符串转换为窄字符字符串
	std::string str = converter.to_bytes(content);
	// 构建要传递的参数
	flutter::EncodableMap args;
	args[flutter::EncodableValue("content")] = flutter::EncodableValue(str.c_str());
	args[flutter::EncodableValue("type")] = flutter::EncodableValue(type.c_str());

	// 调用Flutter方法
	channel_->InvokeMethod("onClipboardChanged", std::make_unique<flutter::EncodableValue>(args));
}

//复制图片到剪贴板
bool BitmapToClipboard(HBITMAP hBM, HWND hWnd)
{
	if (!::OpenClipboard(hWnd))
		return false;
	::EmptyClipboard();

	BITMAP bm;
	::GetObject(hBM, sizeof(bm), &bm);

	BITMAPINFOHEADER bi;
	::ZeroMemory(&bi, sizeof(BITMAPINFOHEADER));
	bi.biSize = sizeof(BITMAPINFOHEADER);
	bi.biWidth = bm.bmWidth;
	bi.biHeight = bm.bmHeight;
	bi.biPlanes = 1;
	bi.biBitCount = bm.bmBitsPixel;
	bi.biCompression = BI_RGB;
	if (bi.biBitCount <= 1)	// make sure bits per pixel is valid
		bi.biBitCount = 1;
	else if (bi.biBitCount <= 4)
		bi.biBitCount = 4;
	else if (bi.biBitCount <= 8)
		bi.biBitCount = 8;
	else // if greater than 8-bit, force to 24-bit
		bi.biBitCount = 24;

	// Get size of color table.
	SIZE_T dwColTableLen = (bi.biBitCount <= 8) ? (1 << bi.biBitCount) * sizeof(RGBQUAD) : 0;

	// Create a device context with palette
	HDC hDC = ::GetDC(nullptr);
	HPALETTE hPal = static_cast<HPALETTE>(::GetStockObject(DEFAULT_PALETTE));
	HPALETTE hOldPal = ::SelectPalette(hDC, hPal, FALSE);
	::RealizePalette(hDC);

	// Use GetDIBits to calculate the image size.
	::GetDIBits(hDC, hBM, 0, static_cast<UINT>(bi.biHeight), nullptr,
		reinterpret_cast<LPBITMAPINFO>(&bi), DIB_RGB_COLORS);
	// If the driver did not fill in the biSizeImage field, then compute it.
	// Each scan line of the image is aligned on a DWORD (32bit) boundary.
	if (0 == bi.biSizeImage)
		bi.biSizeImage = ((((bi.biWidth * bi.biBitCount) + 31) & ~31) / 8) * bi.biHeight;

	// Allocate memory
	HGLOBAL hDIB = ::GlobalAlloc(GMEM_MOVEABLE, sizeof(BITMAPINFOHEADER) + dwColTableLen + bi.biSizeImage);
	if (hDIB)
	{
		union tagHdr_u
		{
			LPVOID             p;
			LPBYTE             pByte;
			LPBITMAPINFOHEADER pHdr;
			LPBITMAPINFO       pInfo;
		} Hdr;

		Hdr.p = ::GlobalLock(hDIB);
		// Copy the header
		::CopyMemory(Hdr.p, &bi, sizeof(BITMAPINFOHEADER));
		// Convert/copy the image bits and create the color table
		int nConv = ::GetDIBits(hDC, hBM, 0, static_cast<UINT>(bi.biHeight),
			Hdr.pByte + sizeof(BITMAPINFOHEADER) + dwColTableLen,
			Hdr.pInfo, DIB_RGB_COLORS);
		::GlobalUnlock(hDIB);
		if (!nConv)
		{
			::GlobalFree(hDIB);
			hDIB = nullptr;
		}
	}
	if (hDIB)
		::SetClipboardData(CF_DIB, hDIB);
	::CloseClipboard();
	::SelectPalette(hDC, hOldPal, FALSE);
	::ReleaseDC(nullptr, hDC);
	return nullptr != hDIB;
}

bool ClipListenerWindow::InnerCopy(std::string type, std::string content, int retry)
{
	// 尝试打开剪贴板
	bool isOpen = OpenClipboard(nullptr);
	if (!isOpen)
	{
		if (retry > 5)
		{
			return false;
		}
		Sleep(100);
		return InnerCopy(type, content, retry + 1);
	}

	// 清空剪贴板内容
	EmptyClipboard();
	std::wstring data = Utf16FromUtf8(content).c_str();
	HGLOBAL hClipboardData = nullptr;
	//文本类型
	if (type == "Text")
	{
		// 分配全局内存，用于存放文本
		hClipboardData = GlobalAlloc(GMEM_MOVEABLE, (wcslen(data.c_str()) + 1) * sizeof(wchar_t));
		if (!hClipboardData)
		{
			CloseClipboard();
			std::cerr << "Failed to allocate memory for clipboard!" << std::endl;
			return false;
		}
		// 将文本复制到全局内存中
		auto const pchData = static_cast<wchar_t*>(GlobalLock(hClipboardData));
		if (!pchData)
		{
			CloseClipboard();
			std::cerr << "Failed to lock!" << std::endl;
			return false;
		}
		wcscpy_s(pchData, wcslen(data.c_str()) + 1, data.c_str());
		GlobalUnlock(hClipboardData);

		// 将全局内存放入剪贴板
		SetClipboardData(CF_UNICODETEXT, hClipboardData);
	}
	if (type == "Image")
	{
		CImage image;
		if (FAILED(image.Load(std::wstring(content.begin(), content.end()).c_str()))) {
			return false;
		}
		HBITMAP hBitmap = image.Detach();
		if (hBitmap == nullptr) {
			std::cerr << "Failed to load image." << std::endl;
			return false;
		}
		BitmapToClipboard(hBitmap, nullptr);
		DeleteObject(hBitmap);
	}
	// 关闭剪贴板
	CloseClipboard();
	if (hClipboardData)
	{
		//释放GlobalAlloc分配的内存
		GlobalFree(hClipboardData);
	}
	return true;
}

std::wstring* GetClipboardText()
{
	// 尝试获取剪贴板中的数据
	const HANDLE hData = GetClipboardData(CF_UNICODETEXT);
	if (hData == nullptr)
	{
		CloseClipboard();
		return nullptr;
	}

	// 锁定内存并获取数据
	const wchar_t* pszText = static_cast<wchar_t*>(GlobalLock(hData));
	if (pszText == nullptr)
	{
		CloseClipboard();
		return nullptr;
	}

	// 释放内存和关闭剪贴板
	GlobalUnlock(hData);
	// 复制数据到字符串
	return new std::wstring(pszText);
}

bool DIBToPNG(const HBITMAP hbtmip, const std::wstring* outputPath)
{
	CImage image;
	// 从 HBITMAP 创建图像
	image.Attach(hbtmip);
	auto path = outputPath->c_str();
	std::string folderPath = fs::path(path).parent_path().string();
	if (!fs::exists(folderPath))
	{
		fs::create_directories(folderPath);
	}
	// 保存为 PNG 格式
	if (image.Save(path, Gdiplus::ImageFormatPNG) != S_OK)
	{
		return false;
	}
	return true;
}

std::wstring getExecutableDir() {
	wchar_t buffer[MAX_PATH];
	DWORD length = GetModuleFileNameW(NULL, buffer, MAX_PATH);
	if (length == 0) {
		// Handle error
		return L"";
	}
	std::wstring path(buffer, length);
	size_t pos = path.find_last_of(L"\\/");
	return (std::wstring::npos == pos) ? L"" : path.substr(0, pos + 1);
}
std::wstring* GetClipboardImg()
{
	// 尝试获取剪贴板中的数据
	const HANDLE hData = GetClipboardData(CF_DIB);
	if (hData == nullptr)
	{
		CloseClipboard();
		return nullptr;
	}

	// 锁定内存并获取数据
	void* pData = GlobalLock(hData);
	if (pData == nullptr)
	{
		CloseClipboard();
		return nullptr;
	}
	// 将 CF_DIB 数据转换为 HBITMAP
	const HDC hdc = GetDC(nullptr);
	const auto info = static_cast<BITMAPINFO*>(pData);
	const auto header = static_cast<const BITMAPINFOHEADER*>(pData);
	//创建位图，位图数据从 header + 1 开始
	const HBITMAP hBitmap = CreateDIBitmap(hdc, header, CBM_INIT, header + 1, info, DIB_RGB_COLORS);
	if (hBitmap == nullptr)
		return nullptr;
	auto currentTime = GetCurrentTimeWithMilliseconds();
	// 使用正则表达式替换所有冒号和空格
	std::regex reg("[:.]");
	currentTime = std::regex_replace(currentTime, reg, "-");
	reg = std::regex(" +");
	currentTime = std::regex_replace(currentTime, reg, "_");
	auto timeStr = std::wstring(currentTime.begin(), currentTime.end());
	auto execDir = getExecutableDir();
	// 拼接图片临时存储路径
	const auto path = new std::wstring(execDir + L"tmp/" + timeStr + L".png");
	//位图转PNG存储
	auto res = DIBToPNG(hBitmap, path);
	ReleaseDC(nullptr, hdc);
	//获取存储的绝对路径
	auto absolutePath = fs::absolute(path->c_str()).string();
	return res ? new std::wstring(absolutePath.begin(), absolutePath.end()) : nullptr;
}

std::wstring* ClipListenerWindow::GetClipboardDataCustom(std::string& type, int retry)
{
	std::wstring* data = nullptr;
	// 尝试打开剪贴板
	bool isOpen = OpenClipboard(nullptr);
	if (!isOpen)
	{
		if (retry > 5)
			return nullptr;
		Sleep(100);
		return GetClipboardDataCustom(type, retry + 1);
	}

	// 尝试获取剪贴板中的数据
	if (IsClipboardFormatAvailable(CF_UNICODETEXT))
	{
		data = GetClipboardText();
		type = "Text";
	}
	if (IsClipboardFormatAvailable(CF_DIB))
	{
		data = GetClipboardImg();
		type = "Image";
	}

	CloseClipboard();
	return data;
}

LRESULT ClipListenerWindow::MessageHandler(HWND hwnd, UINT const uMsg, WPARAM const wParam,
                                           LPARAM const lParam) noexcept
{
	// hwnd: 表示窗口的句柄（handle），是消息发送或接收的窗口的标识符。在函数内，您可以使用这个句柄与窗口进行交互。
	//
	// uMsg : 表示窗口消息的标识符。它指定了要处理的消息类型。例如，WM_DRAWCLIPBOARD 表示剪贴板内容发生变化的消息。
	// WM_DRAWCLIPBOARD 中，wParam 和 lParam 分别表示剪贴板触发事件的原因和相关的句柄。
	//
	// 	wParam : 通常用于传递一些消息相关的信息，如通知消息的原因、按下的键值等。
	//
	// 	lParam : 通常用于传递指针或句柄，指向消息相关的数据结构或对象。

	std::string s("listener handle: " + std::to_string(uMsg) + "\n");
	std::wstring wideString(s.begin(), s.end());
	OutputDebugString(wideString.c_str());
	switch (uMsg)
	{
	case WM_DRAWCLIPBOARD:
		{
			// 剪贴板内容发生变化
			std::string type;
			// 处理剪贴板变化的代码可以放在这里
			std::wstring* text = GetClipboardDataCustom(type);
			if (text != nullptr && *text != lastText)
			{
				//内部复制不发送
				if(!INNER_COPY)
				{
					SendClip(type, *text);
					lastText = *text;
				}
				INNER_COPY = FALSE;
			}
			// 转发消息给下一个剪贴板查看器
			SendMessage(hWndNextViewer_, WM_DRAWCLIPBOARD, wParam, lParam);
		}
		break;
	case WM_CHANGECBCHAIN:
		{
			// 处理剪贴板链的变化
			if ((HWND)wParam == hWndNextViewer_)
				hWndNextViewer_ = (HWND)lParam;
			else if (hWndNextViewer_ != nullptr)
				SendMessage(hWndNextViewer_, uMsg, wParam, lParam);
		}
		break;
	}

	return Win32Window::MessageHandler(hwnd, uMsg, wParam, lParam);
}
