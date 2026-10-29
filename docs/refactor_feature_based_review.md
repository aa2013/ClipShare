# 重构审查报告：refactor-feature-based-structure vs dev

> 审查日期：2026-10-24
> 基线：dev 分支尖端 `9d6aac97`（downgrade linux glibc version to 2.34 and rename artifacts）；分叉点 `669a0f1c`（本机提取内容自动复制作用于所有类型）；HEAD `ca680da2`（暂存 中转，同步，日志，快捷键，备份恢复，安全 设置页面、统计页面、关于页面、实现之前的空配置todo 、数据清理）；重构自 `c1027a51`（feature-based 基础依赖同步）起共 11 个提交、908 文件变更
> 方式：按 8 个领域并行深审（数据同步协议、数据库、设备/传输、启动/全局框架、设置+配置存储、历史/剪贴板、备份恢复、规则/Lua），全程只读；所有 P0 结论已逐条人工复核源码确认。
> 豁免：多窗口、文件传输（按要求未审，但登记了其连锁影响，见第六节）。

## 一、总体结论

1. **迁移完成度高**：`lib/` 下 GetX 导入为零、floor 零残留；路由/翻译/主题/日志格式等框架层等价。
2. **协议兼容性核心达标**：消息类型枚举值、10 字节帧格式、DH+AES 握手、msgpack、各 payload 字段名、删除 tombstone、missingData/ackSync 载荷、备份包 10 个 handler 的主体字段，与 dev 逐一对齐，**dev 旧端与重构新端可以互通**。
3. **数据库层达标**：11 表列级一致、`clipshare.db` 文件名与目录定位等价、旧库可被 drift 直接打开；发现 2 处 legacy 迁移索引遗漏。
4. **主要问题集中在三种根因**：
   - **迁移中被注释/掏空的 todo**（中转连接、requestAppInfo、启动自恢复等）；
   - **riverpod 化引入的时序/取值差异**（invalidate 后读旧值、ACK 门控、启动初始化缺口）；
   - **配套接线遗漏**（启动更新检查、开机自启清理、share_handler、状态栏样式等"类迁了但没接上"）。

---

## 二、P0 — 功能损坏（3 项，均已复核）

### 1. 中转（server）模式启动后控制通道永不自动连接

- HEAD：`connectForwardServer` 全部调用点只有设置页手动开关（`settings_forward_page.dart:141/387`、`settings_overview.dart:461`）和 provider 内部重连；`app_startup_provider`、`discovery_provider`、`network_change_coordinator` 均不调。
- dev：启动（`socket_service.init()`）、每轮设备发现（`startDiscoveryDevices`）、亮屏（`onScreenOpened`）、网络恢复四个时机都会拉起中转控制连接。
- 影响：开启中转后重启 App / 切网 / 亮屏，中转模式静默失效，直到手动进设置页。

### 2. 规则"阻止同步"在补推场景失效

- HEAD：`lib/core/services/history/history_recorder_provider.dart:273-284` —— 先 `await _opRecordDao.add(opRecord)` 再判断 `syncDisabled`（仅跳过即时推送）；dev 中 syncDisabled 时操作记录完全不落库。
- 影响：HEAD 的 `getSyncRecord` 补推会把被规则禁止同步的内容发给对端，规则语义被绕过。规则执行本身 `apply()` 无差异，问题在落库顺序。

### 3. 备份包 scriptModule.bin 导出缺 `isNewData` 字段，dev 端恢复该类型 0 条

- HEAD：`lib/core/services/backup/handlers/script_module_backup_handler.dart:31` 用 drift 生成的 `module.toJson()`（仅 5 键，`isNewData` 是 Expando 不进 toJson）；dev 的 `ScriptModule.fromJson` 把 null 赋给非空 bool 直接抛错，且被 restore 循环吞掉、UI 无提示。
- 说明：仅 HEAD→dev 方向损坏（dev→HEAD 正常）；同步协议侧 HEAD 专门备好的 `scriptModuleToSyncPayload` 备份 handler 没有复用（恢复侧已用 `scriptModuleFromJson`，导出侧是对称遗漏）。

---

## 三、P1 — 与 dev 行为不一致

### 3.1 数据同步

| # | 问题 | dev 行为 | HEAD 行为 |
|---|---|---|---|
| 1 | 接收成功不再无条件回 ACK | `socket_service.dart:1053-1077`：消息可识别即 ACK，与 listener 成败无关 | 各接收 provider 以 `if (!await _apply(event)) continue` 门控；**历史删除即使成功也 `return false` 永不 ACK**（`history_sync_provider.dart:149-153`）。对端永远查不到 opSync，每次 reqMissingData 都重发全量删除记录 |
| 2 | 通知类历史不弹系统通知、不 reqAppInfo 补图标 | `_processData`：10s 时效内通知、图标缺失时向发送端 reqAppInfo | `HistoryNotificationSyncEvent` 已定义、parser 也产出，但无任何消费者 |
| 3 | 设备备注名不跨设备同步 | `device_card.dart:376` 重命名发 `Module.device` update opRecord | `device_page.dart:456` 只写本地（接收器还在、发送侧缺失） |
| 4 | 配对后不请求规则所需 appInfo、收到 appInfo 不刷新规则 | `socket_service.dart:347/894` | `session_provider.dart:420`、`session_message_handler.dart:62` 两处 todo，`RulesExecutor.requestAppInfo` 方法未迁移 |

### 3.2 设备 / 连接

| # | 问题 | dev 行为 | HEAD 行为 |
|---|---|---|---|
| 1 | 首次配对成功后不自动补同步缺失数据 | `device_controller.onPaired` → `reqMissingData()` | `DevicePaired` 事件无人触发 `requestMissingData()`，需断开重连 |
| 2 | 群发不过滤"仅已配对 + 最低版本" | `sendData(dev==null)`：`onlyPaired` + `minVersion` 过滤 | `message_sender_provider.dart` 遍历含未配对设备的在线列表；剪贴板内容会发给未配对的已连接设备 |
| 3 | 亮屏后不重新发现设备、不重连中转 | `onScreenOpened()` | `ScreenOpenedEvent` 无 discovery/forward 消费者 |
| 4 | 息屏自动断开时中转控制连接不断开 | `disConnectAllConnections` 内含 `disConnectForwardServer()` | 只停心跳监测，不断开控制连接，后台耗电/流量行为不同 |
| 5 | 握手发现"已存但未配对"即本地忘记设备 | 保留记录仅标记未配对 | `session_provider.registerCandidate` 主动 `forgetDevice`；注释称有意，但 dev 旧端重装会连带清掉本端配对记录 |

### 3.3 数据库

| # | 问题 | 说明 |
|---|---|---|
| 1 | legacy 迁移漏建 2 个索引 | `app_database.dart` `from < 5` 分支缺 `index_AppInfo_appId_devId` 唯一索引（重复行会让 `getByUniqueIndex().getSingleOrNull()` 抛错）；`from < 9` 分支缺 `index_OperationRecord_moduleEn_method`。同文件 `from < 7` 的两个索引有补，说明是遗漏非策略 |
| 2 | `imageStorePath`/`fileStorePath` 配置只写不读 | `app_paths_provider.dart:270` `_initImageStorePath` 写死 `''`（todo 从数据库读取），设置页（`settings_sync_page.dart:202/242`）仍可写入但重启即失效；老用户已持久化的自定义路径被忽略，路径全部由 `appPaths` 重算 |

### 3.4 启动 / 全局框架

| # | 问题 | dev 行为 | HEAD 行为 |
|---|---|---|---|
| 1 | 启动/回前台自动检查更新缺失 | `home_controller.dart:218/252` `showUpdateInfo(debounce:true)` | 唯一入口是设置页手动按钮（home 迁移缺口，核实仍缺） |
| 2 | Android 通知记录监听启动后不自动恢复 | 启动期 `checkAndroidEnvPermission` 自动 `startListening()` | 唯一调用点在通知设置页 |
| 3 | 3 个翻译 key 缺失，UI 显示 key 原文 | 963 个 key 全有翻译 | `discoveringSettingsModifyHeartbeatDialogInputErrorText`、`securitySettingsEnableSecurityAppPwdRequiredDialogContent/OkText` 不在 arb 中 |
| 4 | share_handler 分享接收入口未迁移 | splash `initShareHandler` 处理系统分享 | 全仓仅剩许可证条目，运行时逻辑为零，"分享到 ClipShare"无反应 |
| 5 | Android detached 启动强制帧丢失 | `_scheduleDetachedAndroidRouteFrame` | 无 `scheduleForcedFrame`，后台服务拉起场景 splash→home 可能不渲染 |

### 3.5 设置 / 配置

| # | 问题 | 说明 |
|---|---|---|
| 1 | 「invalidate 后立即 read」读到旧配置 | Riverpod 3.2.1 的 `requireValue` 在 refresh 期间返回旧值（dev 的 Rx setter 无此问题）。四处中招：①监听方式切换不即时生效（`settings_overview.dart:537` → `clipboard_service_provider.dart:246`）②WebDAV/S3 账号修改后中转用旧凭据重启（`settings_forward_page.dart:492` 连 invalidate 都没有）③中转方式切换（`:159/188`）④通知服务器地址修改后重连用旧地址（`:297`） |
| 2 | 开机自启关闭后旧快捷方式永远清不掉 | dev `setLaunchAtStartup` 开/关都删 Startup 目录旧快捷方式；HEAD toggle 无清理，检测清理被推迟到打开设置总览页且条件收窄（`isLaunchAtStartup && isSystem`），旧版升级用户会陷入"开关显示开、实际关不掉自启" |
| 3 | 剪贴板页"去授权"按钮空实现 | `settings_clipboard_page.dart:127` 仅 `//todo 权限请求`，来源记录引导授权入口失效 |

### 3.6 历史页 / 交互

| # | 问题 | dev 行为 | HEAD 行为 |
|---|---|---|---|
| 1 | 通知/截图产生的本地记录不再同步到其他设备（**需产品确认是否有意**） | 通知/截图同路径落 opRecord 并推送 | `android_notification_listener_provider.dart:99`、`screenshot_detect_provider.dart:71` 均 `emitRaw(sync:false)`，recorder 对 `!shouldSync` 直接 return |
| 2 | 移动端卡片滑动操作块缺失 | `clip_data_card.dart:190` 移动端 Slidable + "更多操作"按钮 | `history_card.dart:107` 仅多选时包 Slidable 且无 endActionPane，手机上单条删除/置顶/标签菜单不可达 |
| 3 | 小屏点击卡片无响应 | 小屏 `showModalBottomSheet` 详情 | `history_list_view.dart:301` `//todo showClipBottomSheet` |
| 4 | 截图 pending 文件兜底行为改变 | 找到文件后复制到 cache、成功 break | `screenshot_detect_provider.dart:150-176` 不复制、无 break（5 轮重复 emit），提权复制分支记录的是不存在路径 |

### 3.7 热键 / 托盘

| # | 问题 | 说明 |
|---|---|---|
| 1 | historyWindow / fileSender 两个热键 handler 整体注释 | `hot_key_provider.dart:58-180`、`182+`（多窗口迁移前置）。热键注册成功但按下无反应；根因在豁免域，热键侧行为缺失需挂账 |
| 2 | 退出热键延迟 2 秒 | HEAD `await Future.delayed(exitAppNotifyDuration)` 等满才退出；dev 发通知后不等待立即退出 |

---

## 四、P2 — 可疑/次要（精选）

| 位置 | 差异 |
|---|---|
| 同步接收侧 | 不再全局 `execSequentially` 串行，跨模块并行，tag 可能先于 history 落库（最终一致） |
| 接收历史 | 不再检查 `recordMaxLength`、来源缺失不再自动 reqAppInfo |
| resync | 从"即时发送不落库"变为"落库后推送"，多次 resync 累积 opRecord |
| `rules_page.dart:179` | 本地删除规则未走 notifier 的 `removeRule()`，Lua 用户函数残留沙箱（同步删除路径是干净的） |
| `discovery_settings.dart` | `onlyForwardMode` 丢 release 强制 false；debug 默认端口偏移（42316）丢失 |
| 中转重连 | dev 有按 devId 哈希错峰防候选风暴，HEAD 直连失败立即试中转 |
| 停止发现 | HEAD 被动组播监听常驻，"停止发现"后仍可能被新设备连上（注释称有意） |
| `add_device_dialog.dart:253` | 连接中禁用取消（dev 可中断）；`_requestPairing` 未捕获 `DeviceNotConnectedException` |
| 备份 | operationSync 导出多 `time` 键（双向兼容无害）；`Rule.regexWhiteBlackMode` 在 HEAD 可空，null 行导出会被 dev 单条拒收 |
| 工作模式 | 未配置时 dev 传 null（插件自动探测 pre10/shizuku/root），HEAD 传 none 跳过探测；pre10 自动补写逻辑注释待恢复 |
| `lockHistoryFloatLoc` | dev 无条件调用，HEAD 仅在显示悬浮窗分支内 |
| 悬浮窗文案 | locale 绑定时机竞态，非系统语言设备悬浮窗标题可能用错语言 |
| 桌面启动 | 更新下载目录清理缺失，残留安装包占盘 |
| `setSystemUIOverlayAutoStyle` | 已实现无调用，Android 状态栏样式不设置 |
| 启动失败 | `main.dart` 无 try/catch，runApp 前异常只进日志（黑屏），dev 有错误 UI |
| 设备页 | "同步数据"按钮不再受 `autoSyncMissingData` 配置影响；配对成功但写库失败无提示 |
| 统计 SQL | 去掉 uid 过滤（单用户下等价）；设备维度命名兜底增强 |

## 五、未迁移 / 待恢复清单（HEAD 中现存的 todo / 空实现）

- `storage_provider.dart`：`_sendFile`*（豁免域）
- `session_provider.dart`：`requestAppInfo`、`MsgType.file` 接收*（豁免域）
- `session_message_handler.dart`：收到 appInfo 刷新规则
- `forward_message_handler.dart`：文件转发相关*（豁免域）
- `app_paths_provider.dart`：imageStorePath 从数据库读取
- `settings_clipboard_page.dart`：去授权权限请求
- `settings_language_page.dart` / `settings_overview.dart`：设置项向子窗口 IPC 推送*（豁免域）
- `guide_bootstrap_provider.dart`：pre10 工作模式自动补写
- `hot_key_provider.dart`：两段热键 handler*（多窗口）
- `history_list_view.dart:301`：小屏详情 bottom sheet
- `app_database.dart:111`：`from < 11` 空占位（schemaVersion 仍为 10，暂无影响）
- 缺失的初始化/接线：启动/回前台更新检查、Android 通知监听自恢复、share_handler、`scheduleForcedFrame`、`setSystemUIOverlayAutoStyle`、启动清理更新下载目录

## 六、豁免域登记与 dev 侧增量

- **多窗口**：热键两段 handler、设置项向子窗口的 IPC 实时推送（主题/语言/点击粘贴/失焦关闭）、`DesktopClickOutside` 归入 `multi_window_channel_provider.dart`、`WindowsPopupUtils` / `windows_win_v_takeover` 均未迁移。
- **文件传输**：`MsgType.file` 接收、forward `sendFile`、存储 `_sendFile`、pending/syncing 进度服务均未迁移。
- **dev 分叉后的增量未带入重构分支**（`669a0f1c`（本机提取内容自动复制作用于所有类型）之后）：Android `HistoryFloatService.kt` +185 行、CI workflow 调整、`windows/runner/main.cpp` 调试多实例放行——前两者属多窗口/构建域，合并时需留意。

## 七、已确认等价的高风险面（抽样结论）

- 线协议全量字段：MessageData/BaseDeviceInfo/History/Device/HistoryTag/AppInfo/OperationRecord/Rule（`language/content` 改名兼容）/ScriptModule（`isNewData` 补齐）
- 发现组播参数与节奏、配对六位码流程与 60s 时限、心跳与息屏断连、帧格式与分包、DH+AES 握手
- Lua 沙箱 7 段模板 token 级一致；`dart_function_bridge` 13 个 C 回调逐函数等价；内置规则迁移四段转换逐字段一致；Lua 资产拷贝清单一致
- 备份 splitter 与 10 个 handler 主体（除 P0-3 一处）、备份 UI 全链路、备份文件名与进度模型
- 数据清理范围与 cron 补跑、应用锁全流程、托盘菜单与闪烁、分词 isolate 与词典安装、Excel 导出
- 84 个 ConfigKey 枚举与持久化字符串、各设置项默认值、设置框架搜索/可见性规则
- 数据库 11 表列级结构、DAO 查询语义、类型映射（枚举序列化器保证 Module→中文名与 dev 一致）、`clipshare.db` 目录定位

> memory 中的已知项核实：`screenshotDetectProvider` 启动调用**已补**（`app_startup_provider.dart:199`）；更新检查与热键两处缺口仍在（见 P1）。

## 八、建议处理优先级

1. 中转控制通道自动连接（P0-1）
2. syncDisabled 落库顺序（P0-2）、scriptModule 备份导出复用 `scriptModuleToSyncPayload`（P0-3）
3. legacy 索引补齐（P1 数据库组）
4. ACK 门控（删除事件回 ACK）
