<p align="center">
  <span>简体中文</span> |
  <a href="./README_EN.md">English</a>
</p>

# ClipShare

ClipShare 是一个基于 Flutter 的跨平台剪贴板同步工具，支持文本、图片、文件、短信等内容在多设备间同步。

- 官网：[https://clipshare.coclyun.top](https://clipshare.coclyun.top)
- 相关仓库
  + 中转程序：[ForwardServer](https://github.com/aa2013/ClipShareForwardServer)
  + 剪贴板监听插件：[ClipboardListener](https://github.com/aa2013/ClipboardListener)

## 项目起源

该项目源于我想找一个 Android 平台上的剪贴板同步工具，但是基本上在 Andorid10+ 系统上都无法后台无感同步和公网环境下同步（本人是个懒人）于是决定自己来实现。

当前除 iOS 以外均已发布，iOS 版本还处于测试阶段，若需要参与 iOS 版本的测试和开发，请拉去对应分支代码：

+ ClipShare: [ClipShare-ios-dev](https://github.com/aa2013/ClipShare/tree/ios-support-dev) 
+ 剪贴板插件: [ClipboardListener-ios](https://github.com/aa2013/ClipboardListener/tree/ios) 。

## 技术现状与规划

### 当前技术栈

- Flutter + Dart（跨平台 UI 与业务层）
- 平台原生能力（Android / Windows / Linux / macOS）
- 状态管理：当前以 `GetX` 为主, 后续计划逐步将状态管理从 `GetX` 迁移到 `Riverpod`。

## 核心能力

- 多设备剪贴板同步（文本、图片、文件、短信）
- 局域网设备发现与直连同步
- 公网中转同步（Forward Server）
- WebDAV / S3 对象存储中转
- 历史记录管理（搜索、筛选、标签、统计、导出 Excel）
- 文件拖拽发送与同步进度跟踪
- 安全能力：应用密码、重新验证、加密密钥配置等
+ 规则管理 (当前为纯正则匹配，1.5.0 将会支持自定义脚本和内容提取)

## 同步方案

ClipShare 当前支持三类同步方案：

+ 内网：
  + 同网段设备自动发现后通过 Socket 通信同步。
+ 公网：
  + 中转服务：通过中转服务做数据转发。
  + WebDAV / S3 做存储中转，配合通知服务触发变更通知。

> 注意：WebDAV/S3 存储中转 当前仍然为实验性功能

中转程序项目仓库：[ForwardServer](https://github.com/aa2013/ClipShareForwardServer)

## Android 剪贴板监听说明

Android 侧目前主要有两类监听路径：

1. 系统日志方式：大多数系统可用，但在部分 ROM（如部分 OriginOS ）可能拿不到可用日志。
2. 系统隐藏 API 方式：通过 shell/root 进程反射调用隐藏 API，兼容性更广，但在深度魔改系统上仍可能受限。

## 支持平台

| 平台 | 状态 | 说明 |
| --- | --- | --- |
| Android | ✅ | 已支持 |
| Windows | ✅ | 已支持                                                    |
| Linux | ✅ | 已支持                                                    |
| macOS | ✅ | 已支持                                                    |
| iOS | ⚠️ | 仓库包含 iOS 工程，当前发布流程未包含 iOS，仍处于测试阶段 |

## 项目结构

### 顶层目录

```text
assets/      # 静态资源（图片、内置 markdown、脚本等）
docs/        # 文档资源
go/          # Go 服务（通知服务）
lib/         # Flutter 主体代码，通常都是在这个目录下
scripts/     # 本地构建与打包脚本
android/     # Android 项目原生工程，通常仅当需要编写原生代码混合开发时才会修改
windows/     # Windows 项目原生工程，通常仅当需要编写原生代码混合开发时才会修改
macos/       # Macos 项目原生工程，通常仅当需要编写原生代码混合开发时才会修改
linux/       # Linux 项目原生工程，通常仅当需要编写原生代码混合开发时才会修改
ios/         # iOS 项目原生工程，通常仅当需要编写原生代码混合开发时才会修改
```

### Flutter 核心目录（`lib/app`）

``` 
lib/app/
  data/          # 数据模型、枚举、仓储、数据库实体与 DAO
  exceptions/    # 自定义异常
  handlers/      # 业务处理器（同步、存储、备份、Socket、引导等）
  listeners/     # 事件监听器（设备状态、历史变化、窗口事件等）
  modules/       # 页面模块（每个模块通常含 page/controller/bindings）
  routes/        # 路由定义
  services/      # 全局服务（配置、数据库、设备、托盘、传输、标签等）
  theme/         # 主题配置
  translations/  # 国际化翻译
  utils/         # 工具类与扩展
  widgets/       # 可复用 UI 组件
  utils/         # 工具类和一系列扩展方法，项目中所有常量都位于 `utils/Constants.dart`
```

### 主要页面模块说明

| 模块 | 作用 |
| --- | --- |
| `home_module` | 主页面入口与导航 |
| `history_module` | 历史记录展示与操作 |
| `device_module` | 设备发现、配对、连接管理 |
| `search_module` | 历史检索与过滤 |
| `settings_module` | 应用配置页面 |
| `statistics_module` | 统计图表与数据分析 |
| `sync_file_module` | 文件同步相关页面 |
| `authentication_module` | 应用鉴权与密码保护 |
| `log_module` | 日志查看与问题排查 |
| `clean_data_module` | 数据清理 |
| `db_editor_module` | 数据库调试与 SQL 执行 |
| `update_log_module` | 更新日志展示 |
| `about_module` | 关于页 |
| `user_guide_module` | 首次使用引导 |
| `qr_code_scanner_module` | 二维码扫描页 |
| `working_mode_selection_module` | Android 工作模式选择（如 Shizuku/Root/忽略） |
| `debug_module` | 调试能力入口 |

### services 模块补充说明（文本化）

`services/` 是运行期核心支撑层，主要负责：

- 配置读写（`config_service.dart`）
- 数据库生命周期（`db_service.dart`）
- 设备状态维护（`device_service.dart`）
- 剪贴板与来源记录（`clipboard_service.dart`、`clipboard_source_service.dart`）
- 同步与连接管理（`transport/`）
- 托盘与窗口行为（`tray_service.dart`、`window_service.dart`、`window_control_service.dart`）
- 文件同步管理（`history_sync_progress_service.dart`、`syncing_file_progress_service.dart`、`pending_file_service.dart`）

## 国际化（i18n）说明

项目 i18n 基于 `TranslationKey` 枚举统一管理翻译键，新增语言建议按以下步骤：

1. 在 `lib/app/data/enums/translation_key.dart` 增加键。
2. 在 `lib/app/translations/` 下新增对应语言翻译文件。
3. 在 `app_translations.dart` 注册语言映射。
4. 在设置页语言选项中补充新语言。

这样可以保证所有语言的键空间一致，便于做缺失检查和维护。

## 开发环境要求

- Flutter `3.35.x`（CI 使用 `3.35.3`）
- Dart SDK `>=3.8.0 <4.0.0`
- Android 构建需要 JDK 17
- Linux 桌面构建需安装 GTK 等依赖（见 `.github/workflows/build-linux.yml`）

## 本地运行

```bash
flutter pub get
flutter run
```

## 脚本

项目提供了相关脚本（位于 `scripts/`）：

### 构建与打包

> Windows, Linux, macOS 需要使用 [Fastforge](https://fastforge.dev/getting-started)

- Android APK：`scripts/build_apk.bat`
- Windows Release（便携版）：`scripts/build_windows.bat`
- Windows EXE 打包（Fastforge）：`scripts/build_windows_exe.bat`
- Linux 打包（Fastforge, deb/appimage/rpm）：`scripts/build_linux.sh pack`
- macOS DMG 打包 (Fastforge)：`scripts/build_macos.sh`

GitHub Actions 也提供了对应平台流水线，见 `.github/workflows/`：

- `build-all.yml`
- `build-android.yml`
- `build-windows.yml`
- `build-linux.yml`
- `build-macos.yml`
- `build-notify-docker-image.yml`

### 代码生成

- 数据库代码生成：`scripts/db_gen.bat`
- 应用图标生成：`scripts/icon_gen.bat`

## 数据库代码生成

本项目基于 `sqlite`, 使用 [floor](https://pub.dev/packages/floor) 框架

后续也可能迁移数据库框架

步骤：
+ 1. 若需新增表
  + 1.1 在 `lib/app/data/repository/entity/tables` 新增实体类，使用注解标记
  + 1.2 然后在 `lib/app/data/repository/dao` 新增Dao接口，使用注解标记
  + 1.3 然后 `lib/app/services/db_service.dart` 中的 `tables` 添加实体类
  + 1.4 然后 `lib/app/services/db_service.dart` 中的 `_AppDb` 添加对应的 Dao 的 getter 字段
+ 2. 修改SQL
  + 2.1 修改对应 Dao 中的接口上的 SQL

+ 3. 最后 `cd scripts` 进入脚本目录，执行 `db_gen.bat` 进行代码生成即可


## 可选：自建通知服务（对象存储中转配套）

仓库内提供 Go 实现的通知服务：`go/notification`。

- 默认监听端口：`8083`
- Docker Compose 示例：`go/notification/docker-compose.yml`

启动（本地 Go）：

```bash
cd go/notification
go run . -port 8083
```

## 许可证

本项目使用 [GPL-3.0](./LICENSE) 许可证。
