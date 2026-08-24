// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get unitWord => '字';

  @override
  String get dialogCancelText => '取消';

  @override
  String get dialogAuthorizationButtonText => '去授权';

  @override
  String get floatPermRequestDialogTitle => '请求悬浮窗权限';

  @override
  String get floatPermRequestDialogContent =>
      '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，当剪贴板发生变化时应用需要通过读取系统日志以及悬浮窗权限间接进行剪贴板读取。\n\n点击确定跳转页面授权悬浮窗权限';

  @override
  String get requiredPermDialogTitle => '必要权限缺失';

  @override
  String get floatPermMissingDialogContent => '请授予悬浮窗权限，否则无法后台读取剪贴板';

  @override
  String get shizukuPermRequestDialogTitle => 'Shizuku权限请求';

  @override
  String get shizukuPermRequestDialogContent =>
      '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，需要依赖 Shizuku，否则只能被动接收剪贴板数据而不能自动同步';

  @override
  String get dontShowAgain => '不再提示';

  @override
  String get dontShowAgainConfirm => '确认不再提示？';

  @override
  String get notificationPermRequestDialogTitle => '请求通知权限';

  @override
  String get notificationPermRequestDialogContent => '用于发送系统通知';

  @override
  String get batteryOptimization => '电池优化';

  @override
  String get batteryOptimizationPermRequestDialogContent =>
      '取消电池优化以提高后台留存率\n若点击[去授权]后无反应，请自行在手机设置中查找相关设置项';

  @override
  String get selectWorkMode => '选择工作模式';

  @override
  String get completed => '已完成';

  @override
  String get completedGuideDesc => '已完成全部设置';

  @override
  String get floatPermGuideTitle => '悬浮窗权限';

  @override
  String floatPermGuideDesc(String appName) {
    return '由于高版本Android系统限制，$appName需要通过悬浮窗获取剪贴板焦点，开启悬浮窗后还可以随时从屏幕边缘查看剪贴板历史并进行拖拽选择';
  }

  @override
  String get notificationPermGuideTitle => '通知权限';

  @override
  String get notificationPermGuideDesc => '开启通知，以启动前台服务';

  @override
  String get storagePermGuideTitle => '存储权限';

  @override
  String get storagePermGuideDesc => '同步图片与文件时需要存储权限，否则无法保存文件。';

  @override
  String get batteryOptimizationPermGuideDesc =>
      '为了保证后台存活需要将其从电池优化中移除\n此外，请在后台任务卡片中加锁并手机管家中设置允许自启！\n若点击[去授权]后无反应，请自行在手机设置中查找相关设置项';

  @override
  String get aboutPageInstructionsItemName => '使用说明';

  @override
  String get aboutPageJoinQQGroupItemName => '加入QQ群';

  @override
  String get aboutPageWebsiteItemName => '查看官网';

  @override
  String get aboutPageLogsItemName => '更新日志';

  @override
  String get aboutPageVersionItemName => '软件版本';

  @override
  String get authenticationPageTitle => '身份验证';

  @override
  String get authenticationPageBackendTimeoutVerificationTitle => '超时验证';

  @override
  String get authenticationPageUsePassword => '使用密码';

  @override
  String get authenticationPageStartVerification => '开始验证';

  @override
  String get authenticationPageRequireAuthentication => '需要身份验证';

  @override
  String get deviceAdditionFailedDialogText => '设备添加失败';

  @override
  String get rename => '重命名';

  @override
  String get devicePageDisconnect => '断开连接';

  @override
  String get devicePageReconnect => '重新连接';

  @override
  String get devicePageUnpairedDialogContent => '是否要取消配对？';

  @override
  String get devicePageUnpairedButtonText => '取消配对';

  @override
  String get devicePagePairingDialogTitle => '请输入配对码';

  @override
  String get devicePagePairingTimeoutText => '配对超时！';

  @override
  String get devicePagePairingErrorText => '配对码错误！';

  @override
  String get devicePagePairingDialogConfirmText => '配对！';

  @override
  String devicePageMyDevicesText(String length) {
    return '我的设备($length)';
  }

  @override
  String get devicePageForwardServerText => '中转连接';

  @override
  String devicePageDiscoverDevicesText(String length) {
    return '发现设备($length)';
  }

  @override
  String get devicePageRediscoverTooltip => '重新发现设备';

  @override
  String get devicePageManuallyTooltip => '手动添加设备';

  @override
  String get devicePageStopDiscoveringTooltip => '停止发现';

  @override
  String get sms => '短信';

  @override
  String get homeAppBarSyncingProgressText => '同步中';

  @override
  String get search => '搜索';

  @override
  String get logPageAppBarTitle => '日志记录';

  @override
  String get all => '全部';

  @override
  String get text => '文本';

  @override
  String get image => '图片';

  @override
  String get file => '文件';

  @override
  String get moreFilter => '更多筛选项';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get filterByDate => '筛选日期';

  @override
  String get filterByContentType => '筛选类型';

  @override
  String get filterBySource => '筛选来源';

  @override
  String get saveTopData => '保留置顶数据';

  @override
  String get removeLocalFiles => '同时移除本地文件';

  @override
  String get saveFilterConfig => '保存过滤器配置';

  @override
  String get saveAutoCleanConfig => '保存自动清理配置';

  @override
  String get noDataFromFilter => '过滤器未查询到数据';

  @override
  String filterCleaningConfirmation(String cnt) {
    return '查询到有 $cnt 条数据，此操作不可恢复，是否继续？';
  }

  @override
  String get syncRecordsCleaningConfirmation => '清理设备同步记录将会导致数据在下次连接后重新同步';

  @override
  String get onlyNotSync => '仅未同步';

  @override
  String get syncRecordsCleanBtn => '清理所选设备同步记录';

  @override
  String get optionRecordsCleaningConfirmation => '清理设备操作记录将会导致未同步的数据不会再次自动同步';

  @override
  String get optionRecordsCleanBtn => '清理所选设备操作记录';

  @override
  String get autoCleanFrequency => '清理频率';

  @override
  String get execTime => '执行时间';

  @override
  String get nextExecTime => '预计下次清理时间：';

  @override
  String get errorCronTips => '请输入正确的 UnixCron 表达式';

  @override
  String get filterTips => '若对应过滤器不选择则表示全选\n日期范围不会作为过滤配置保存';

  @override
  String get autoCleanConfigTitle => '自动清理';

  @override
  String get daily => '每天';

  @override
  String get weekly => '每周';

  @override
  String get selectWeekDay => '选择周';

  @override
  String get deleteItemsUnit => '条';

  @override
  String get pleaseSelectDevices => '请先选择设备';

  @override
  String get saveSuccess => '保存成功！';

  @override
  String get pleaseSaveFilterConfig => '请先保存过滤器配置';

  @override
  String get saveFailed => '保存失败！';

  @override
  String get updateSuccess => '更新成功！';

  @override
  String get updateFailed => '更新失败！';

  @override
  String get confirm => '确定';

  @override
  String get toToday => '定位到今天';

  @override
  String get clear => '清除';

  @override
  String get settingsSearchHint => '搜索设置...';

  @override
  String get filterByDevice => '筛选设备';

  @override
  String get filterByTag => '筛选标签';

  @override
  String get envStatusLoadingText => '正在加载环境状态';

  @override
  String get shizukuModeStatusTitle => 'Shizuku 模式';

  @override
  String shizukuModeRunningDesc(String version) {
    return '服务已运行，API $version';
  }

  @override
  String get rootModeStatusTitle => 'Root 模式';

  @override
  String get rootModeRunningDesc => '已授权，服务已运行';

  @override
  String get serverNotRunningDesc => '服务未运行，部分功能不可用';

  @override
  String get envPermissionIgnored => '已忽略权限';

  @override
  String get envPermissionIgnoredDesc => '部分功能可能不可用';

  @override
  String get noSpecialPermissionRequired => '无需特殊权限';

  @override
  String get switchWorkingMode => '切换工作模式';

  @override
  String get commonSettingsRunAtStartup => '开机启动';

  @override
  String get commonSettingsRunMinimize => '启动时最小化窗口';

  @override
  String get floatWindow => '悬浮窗';

  @override
  String get commonSettingsShowHistoriesFloatWindow => '显示历史记录悬浮窗';

  @override
  String get commonSettingsShowHistoriesFloatWindowTips =>
      '双击或者向左拖拉把手调出历史记录悬浮面板';

  @override
  String get historyFloatTitle => '剪贴历史';

  @override
  String get historyFloatCountTemplate => '{count} 条记录';

  @override
  String get historyFloatImageUnavailable => '图片已不可用';

  @override
  String commonSettingsHistoriesFloatWindowHandleWidthValue(String width) {
    return '悬浮窗把手宽度：$width';
  }

  @override
  String get commonSettingsHistoriesFloatWindowHandleColor => '悬浮窗把手颜色';

  @override
  String get commonSettingsHistoriesFloatWindowHandleColorTips =>
      '选择悬浮窗颜色，修改后会实时同步。';

  @override
  String get commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle =>
      '透明度应用到整个把手';

  @override
  String get commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips =>
      '开启后，把手边框、竖条和内部装饰层会一起跟随所选颜色的透明度。';

  @override
  String get commonSettingsEnhanceBackgroundKeepAliveTitle => '增强后台保活';

  @override
  String get commonSettingsEnhanceBackgroundKeepAliveDesc =>
      '显示一个1像素的悬浮窗，以在某些设备中尝试增强后台保活能力';

  @override
  String get commonSettingsLockHistoriesFloatWindowPosition => '锁定悬浮窗位置';

  @override
  String get preferenceSettingsRememberWindowSize => '记住上次窗口大小';

  @override
  String get preferenceSettingsWindowSizeRecordValue => '记录值';

  @override
  String get preferenceSettingsWindowSizeDefaultValue => '默认值';

  @override
  String get commonSettingsTheme => '主题';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get themeAuto => '跟随系统';

  @override
  String get themeLight => '亮色模式';

  @override
  String get themeDark => '暗色模式';

  @override
  String get permissionSettingsGroupName => '权限';

  @override
  String get permissionSettingsNotificationTitle => '通知权限';

  @override
  String get permissionSettingsNotificationDesc => '用于启动前台服务';

  @override
  String get permissionSettingsFloatTitle => '悬浮窗权限';

  @override
  String get permissionSettingsFloatDesc => '高版本系统中通过悬浮窗获取剪贴板焦点';

  @override
  String get permissionSettingsBatteryOptimiseTitle => '电池优化';

  @override
  String get permissionSettingsBatteryOptimiseDesc => '添加电池优化防止被后台系统杀死';

  @override
  String get permissionSettingsSmsTitle => '短信读取';

  @override
  String get permissionSettingsSmsDesc => '已开启短信同步功能，请授予短信读取权限';

  @override
  String get discoveringSettingsGroupName => '发现';

  @override
  String get discoveringSettingsLocalDeviceName => '设备名称';

  @override
  String get discoveringSettingsDeviceNameCopyTip => '已复制设备id';

  @override
  String get copyDeviceId => '复制设备id';

  @override
  String get modifyDeviceName => '修改设备名称';

  @override
  String get deviceName => '设备名称';

  @override
  String get modifyDeviceNameCompletedTooltip => '修改后重启软件生效';

  @override
  String get port => '端口';

  @override
  String discoveringSettingsPortDesc(String port) {
    return '默认值 $port。修改后可能无法被自动发现';
  }

  @override
  String get modifyPort => '修改端口';

  @override
  String get modifyPortErrorText => '端口号范围0-65535';

  @override
  String get discoveringSettingsModifyPortCompletedTooltip => '修改后重启软件生效';

  @override
  String get allowDiscovering => '可被发现';

  @override
  String get discoveringSettingsAllowDiscoveringDesc => '可以被其它设备自动发现';

  @override
  String get discoveringSettingsOnlyForwardDiscoveringTitle => '仅中转发现（调试用）';

  @override
  String get discoveringSettingsOnlyForwardDiscoveringDesc => '仅在开发环境中显示该功能';

  @override
  String get discoveringSettingsHeartbeatIntervalTitle => '心跳检测间隔';

  @override
  String get discoveringSettingsHeartbeatIntervalDesc => '检测设备存活。默认30s，0不检测';

  @override
  String get discoveringSettingsHeartbeatIntervalTooltip => '说明';

  @override
  String get enable => '启用';

  @override
  String get dontDetect => '不检测';

  @override
  String get discoveringSettingsHeartbeatIntervalDialogContent =>
      '当设备切换网络时无法自动检测到设备是否掉线\n启用心跳检测将会定时检查设备存活情况。';

  @override
  String get discoveringSettingsModifyHeartbeatDialogTitle => '心跳间隔';

  @override
  String get discoveringSettingsModifyHeartbeatDialogInputLabel =>
      '心跳间隔单位秒，0为禁用检测';

  @override
  String get forwardSettingsGroupName => '中转';

  @override
  String get forwardSettingsForwardTitle => '使用中转服务';

  @override
  String get forwardSettingsForwardDownloadTooltip => '下载中转程序';

  @override
  String get forwardSettingsForwardDesc => '通过中转服务可在公网环境下进行数据同步';

  @override
  String get forwardSettingsForwardEnableRequiredText => '请先设置中转服务器地址';

  @override
  String get forwardSettingsForwardAddressTitle => '中转服务器地址';

  @override
  String get forwardSettingsForwardAddressDesc => '请使用可信地址或自行搭建';

  @override
  String get configure => '配置';

  @override
  String get change => '更改';

  @override
  String get securitySettingsGroupName => '安全';

  @override
  String get securitySettingsEnableSecurityTitle => '启用安全认证';

  @override
  String get securitySettingsEnableSecurityDesc => '启用密码或生物识别认证请先创建应用密码';

  @override
  String get securitySettingsEnableSecurityAppPwdModifyTitle => '更改密码';

  @override
  String get createAppPwd => '新建应用密码';

  @override
  String get changeAppPwd => '更改应用密码';

  @override
  String get create => '新建';

  @override
  String get securitySettingsReverificationTitle => '密码重新验证';

  @override
  String get securitySettingsReverificationDesc => '在后台指定时长后重新验证密码';

  @override
  String securitySettingsReverificationValue(String value) {
    return '$value 分钟';
  }

  @override
  String get hotKeySettingsGroupName => '快捷键';

  @override
  String get hotKeySettingsHistoryTitle => '历史弹窗';

  @override
  String get hotKeySettingsHistoryDesc => '在屏幕任意位置唤起历史记录弹窗';

  @override
  String get hotKeySettingsHistoryTakeOverWinVTooltip => '已接管 Win+V';

  @override
  String get hotKeySettingsCombinationInvalidText => '快捷键必须是控制键和非控制键的组合！';

  @override
  String hotKeySettingsSaveKeysDialogText(String keys) {
    return '是否保存快捷键（$keys）设置？';
  }

  @override
  String hotKeySettingsSaveKeysFailedText(String err) {
    return '设置失败 $err';
  }

  @override
  String get sendFile => '文件发送';

  @override
  String get hotKeySettingsFileDesc => '将选定的文件同步到其他设备（桌面无效）';

  @override
  String get syncSettingsGroupName => '同步';

  @override
  String get syncSettingsSmsPermissionRequired => '请先授予短信读取权限';

  @override
  String get syncSettingsStoreImg2PicturesTitle => '图片存储至相册中';

  @override
  String syncSettingsStoreImg2PicturesDesc(String appName) {
    return '将保存至 Pictures/$appName 中';
  }

  @override
  String get syncSettingsStoreImg2PicturesNoPermText => '无读写权限，需要进行授权';

  @override
  String get syncSettingsStoreImg2PicturesCancelPerm => '用户取消授权！';

  @override
  String get syncSettingsStoreImagePathTitle => '图片存储路径';

  @override
  String get syncSettingsStoreFilePathTitle => '文件存储路径';

  @override
  String get selection => '选择';

  @override
  String get syncSettingsAutoCopyImgTitle => '自动复制图片';

  @override
  String get syncSettingsAutoCopyImgDesc => '启用后若其他设备复制了图片本机也会自动复制';

  @override
  String get logSettingsGroupName => '日志';

  @override
  String get logSettingsEnableTitle => '启用日志记录';

  @override
  String logSettingsEnableDesc(String size) {
    return '将会占据额外空间，已产生 $size 日志';
  }

  @override
  String get openFolder => '打开文件夹';

  @override
  String get openFilePos => '打开文件位置';

  @override
  String get tips => '提示';

  @override
  String get logSettingsDeleteLogFilesDialogContent => '是否删除日志文件？';

  @override
  String get statisticsSettingsGroupName => '统计';

  @override
  String get about => '关于';

  @override
  String get errorDialogTitle => '错误';

  @override
  String get selfDeviceName => '本机';

  @override
  String get save => '保存';

  @override
  String get saved => '已保存';

  @override
  String get saveFileNotSupportDialogText => '不支持的类型';

  @override
  String get pieDataStatisticsLocalItemLabel => '本地';

  @override
  String get pieDataStatisticsSyncItemLabel => '同步';

  @override
  String get statisticsPageAppBarText => '统计分析';

  @override
  String get statisticsPageFilterRangeText => '统计范围';

  @override
  String get refresh => '刷新';

  @override
  String get statisticsPageHistoryTypeCntTitle => '各类别记录数量';

  @override
  String get statisticsPageSyncRatePie => '同步比例';

  @override
  String get statisticsPageHistoryCntForDevice => '各设备记录数量';

  @override
  String get statisticsPageHistoryTagCnt => '各标签记录数量';

  @override
  String get syncingFilePageHistoryTabText => '历史';

  @override
  String get syncingFilePageReceiveTabText => '接收进度';

  @override
  String get syncingFilePageSendTabText => '发送进度';

  @override
  String get dragFileToSend => '拖拽文件以发送';

  @override
  String get deleting => '删除中...';

  @override
  String get deletingSuccess => '删除成功';

  @override
  String get partialDeletionFailed => '部分删除失败';

  @override
  String get deletionFailed => '删除失败';

  @override
  String get deselect => '取消选择';

  @override
  String get delete => '删除';

  @override
  String get deleteWithFiles => '连带文件删除';

  @override
  String syncingFilePageDeleteSelectedDialogContent(String length) {
    return '是否删除选中的 $length 项？\n发送记录的文件不会被删除';
  }

  @override
  String get onlyDeleteRecordsText => '仅删除记录';

  @override
  String get failedToReadUpdateLog => '读取更新日志失败！';

  @override
  String get skipGuide => '跳过此项';

  @override
  String get previousGuide => '上一步';

  @override
  String get nextGuide => '下一步';

  @override
  String get finishGuide => '完成';

  @override
  String get previewPageNoSuchFile => '图片不存在或已被删除';

  @override
  String get copyPathSuccess => '复制路径成功';

  @override
  String get tagEditPageAppBarTitle => '编辑标签';

  @override
  String get tagEditPageSearchOrCreateTag => '搜索或创建标签';

  @override
  String tagEditPageCrateTagItem(String tag) {
    return '创建 \"$tag\" 标签';
  }

  @override
  String get updateLogPageAppBarTitle => '更新日志';

  @override
  String get failedToReadFile => '文件读取失败';

  @override
  String welcome(String appName) {
    return '欢迎使用 $appName';
  }

  @override
  String get welcomeContent => '在使用前我们还需要进行一些必要权限请求以及设置';

  @override
  String get startNow => '现在开始';

  @override
  String get name_ => '名称';

  @override
  String get ruleContent => '规则';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get revoke => '撤销';

  @override
  String get importRules => '导入规则';

  @override
  String importRulesSuccess(String length) {
    return '成功导入$length条';
  }

  @override
  String get importFromNet => '从网络导入';

  @override
  String get importFromLocal => '从本地导入';

  @override
  String get urlFormatErrorText => '请输入正确的URL';

  @override
  String get fetch => '获取';

  @override
  String get fetchingData => '正在获取数据...';

  @override
  String get failedToLoad => '加载失败';

  @override
  String get noSuchFile => '选择的文件路径不存在!';

  @override
  String get addRule => '添加规则';

  @override
  String get importRule => '导入规则';

  @override
  String get import => '导入';

  @override
  String get add => '添加';

  @override
  String get modify => '修改';

  @override
  String get output => '导出';

  @override
  String get outputRule => '导出规则';

  @override
  String get outputSuccess => '导出成功！';

  @override
  String get outputFailed => '导出失败';

  @override
  String get exitSelectionMode => '退出选择模式';

  @override
  String get selectAll => '全选';

  @override
  String get cancelSelectAll => '取消全选';

  @override
  String get multipleChoiceOperationAppBarTitle => '多选操作';

  @override
  String get forwardServerNotAllowedSendFile => '连接的中转服务器不允许文件同步';

  @override
  String get sendFailed => '发送失败';

  @override
  String get forwardServerUnknownResult => '未知的返回结果';

  @override
  String get forwardServerConnectFailed => '中转服务器连接失败';

  @override
  String get devicePairingRequestNotificationContent => '新配对请求';

  @override
  String get devicePairingRequestDialogTitle => '配对请求';

  @override
  String pairingCodeDialogContent(String devName) {
    return '来自 $devName 的配对请求\n配对码:';
  }

  @override
  String get cancelCurrentPairing => '取消该次配对';

  @override
  String get deviceDiscoveryStatusViaBroadcast => '广播发现';

  @override
  String get deviceDiscoveryStatusViaScan => '扫描网络';

  @override
  String get deviceDiscoveryStatusViaForward => '中转发现';

  @override
  String get newVersionDialogTitle => '新版本';

  @override
  String get newVersionDialogSkipText => '忽略该次更新';

  @override
  String get newVersionDialogOkText => '下载更新';

  @override
  String get defaultLinkTagName => '链接';

  @override
  String get unknownHistoryContentType => '未知';

  @override
  String get allHistoryContentType => '全部';

  @override
  String get textHistoryContentType => '文本';

  @override
  String get imageHistoryContentType => '图片';

  @override
  String get richTextHistoryContentType => '富文本';

  @override
  String get smsHistoryContentType => '短信';

  @override
  String get fileHistoryContentType => '文件';

  @override
  String get dialogConfirmText => '确定';

  @override
  String get dialogNeutralText => '中立按钮';

  @override
  String get dialogRestoreDefaultText => '恢复默认值';

  @override
  String get open => '打开';

  @override
  String get openLink => '打开链接';

  @override
  String get moment => '刚刚';

  @override
  String get minutesAgo => '分钟前';

  @override
  String get hoursAgo => '小时前';

  @override
  String get connectFailed => '连接失败';

  @override
  String get connectSuccess => '连接成功';

  @override
  String get connect => '连接';

  @override
  String get addDeviceDialogTitle => '添加设备';

  @override
  String get errorFormatIp => '请输入正确的IPv4/v6地址';

  @override
  String get inputPassword => '输入密码';

  @override
  String get inputAgain => '再次输入';

  @override
  String get inputErrorAndAgain => '输入错误，请重新输入';

  @override
  String get immediately => '立即';

  @override
  String get minute => '分钟';

  @override
  String get alreadyNewestAppVersion => '已是最新版本';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get topUp => '置顶';

  @override
  String get cancelTopUp => '取消置顶';

  @override
  String get copyContent => '复制内容';

  @override
  String get copyMergedContent => '合并复制';

  @override
  String get syncRecord => '同步记录';

  @override
  String get resyncRecord => '重新同步';

  @override
  String get openFile => '打开文件';

  @override
  String get openFileFolder => '打开所在文件夹';

  @override
  String get tagsManagement => '标签管理';

  @override
  String get copySuccess => '复制成功';

  @override
  String get copyFailed => '复制失败';

  @override
  String get clipboardContent => '剪贴板详情';

  @override
  String get deleteRecord => '删除记录';

  @override
  String multiDeleteAsk(String length) {
    return '是否删除选中的 $length 项？';
  }

  @override
  String get deleteCompleted => '删除完成';

  @override
  String get shareFile => '分享文件';

  @override
  String get deleteTips => '删除提示';

  @override
  String get clipListDeleteRecordDialogContent => '确定删除该记录？';

  @override
  String get backToTop => '返回顶部';

  @override
  String get fold => '收起';

  @override
  String get unfold => '展开';

  @override
  String get clipboard => '剪贴板';

  @override
  String get close => '关闭';

  @override
  String get tag => '标签';

  @override
  String get pleaseInput => '请输入';

  @override
  String get forward => '中转';

  @override
  String get notCompatible => '版本不兼容';

  @override
  String notCompatibleDialogText(
    String minName,
    String minCode,
    String selfName,
    String selfCode,
  ) {
    return '与该设备的软件版本不兼容，设备连接和数据同步功能可能异常。\n最低版本要求为 $minName($minCode)\n当前软件版本为 $selfName($selfCode)';
  }

  @override
  String get emptyData => '无数据';

  @override
  String get shizukuMode => 'Shizuku 模式';

  @override
  String get shizukuModeDesc => '无需 Root，需要安装 Shizuku，重启手机后需要重新激活';

  @override
  String get shizukuModeBatteryOptimiseTips =>
      '为保证正常授权，请确保将 Shizuku 添加到电池优化白名单并允许后台运行';

  @override
  String get shizukuRequestFailedDialogText =>
      'Shizuku 权限请求失败，请确保已启动Shizuku并重试';

  @override
  String get requestFailed => '请求失败';

  @override
  String get selectInstallerType => '选择安装包格式';

  @override
  String get openPathAfterDownload => '下载后打开文件夹';

  @override
  String get updateFromZipTips => 'zip便携版本下载后也可自动进行更新操作';

  @override
  String get requestSuccess => '请求成功';

  @override
  String get clipboardPermissionRequestFailed => '剪贴板权限请求需要 Shizuku 或 Root 权限';

  @override
  String get rootMode => 'Root模式';

  @override
  String get rootModeDesc => '以 Root 权限启动，重启手机无需重新激活';

  @override
  String get waitingRequestResult => '等待请求结果';

  @override
  String get applyingSettings => '正在应用设置...';

  @override
  String get rootRequestFailedDialogText => '似乎没有 Root 权限，可选择 Shizuku 模式启动';

  @override
  String get ignoreMode => '忽略';

  @override
  String get ignoreModeDesc => '剪贴板将无法后台监听，只能被动同步';

  @override
  String multiChoiceModeSelectedText(String text) {
    return '已选择 $text 项';
  }

  @override
  String get goAuthorize => '去授权';

  @override
  String get cannotEmpty => '不能为空';

  @override
  String get ruleCannotEmpty => '规则不能为空';

  @override
  String get ruleAddDialogLabel => '规则';

  @override
  String get ruleAddDialogHint => '请输入正则表达式';

  @override
  String get validationTesting => '验证测试';

  @override
  String get validationFailed => '验证失败';

  @override
  String get verify => '验证';

  @override
  String get stop => '停止';

  @override
  String get failed => '失败';

  @override
  String get pleaseInputKey => '请输入密钥';

  @override
  String get forwardServerUnlimitedDevices => '白名单设备无任何限制';

  @override
  String get publicForwardServer => '公开服务器';

  @override
  String get forwardServerSyncFileRateLimit => '文件同步限速';

  @override
  String get forwardServerCannotSyncFile => '该中转服务器不可进行文件同步';

  @override
  String get forwardServerNoLimits => '无任何限制';

  @override
  String get noLimits => '无限制';

  @override
  String get deviceUnit => '台';

  @override
  String get day => '天';

  @override
  String get hour => '小时';

  @override
  String get second => '秒';

  @override
  String get forwardServerKeyNotStarted => '未开始计时';

  @override
  String get exhausted => '已耗尽';

  @override
  String get forwardServerDeviceConnectionLimit => '设备同时连接限制';

  @override
  String get forwardServerLifeSpan => '有效期';

  @override
  String get forwardServerRemainingTime => '剩余时间';

  @override
  String get forwardServerRateLimit => '速率限制';

  @override
  String get forwardServerRemark => '备注';

  @override
  String get configureForwardServerDialogTitle => '配置中转服务器';

  @override
  String get domainAndIp => '域名/ip';

  @override
  String get host => '主机';

  @override
  String get useKey => '使用密钥';

  @override
  String get accessKey => '访问密钥';

  @override
  String get pleaseInputAccessKey => '请输入访问密钥';

  @override
  String get checkConnection => '连接检测';

  @override
  String get pleaseInputValidPort => '请输入合法的端口';

  @override
  String get pleaseInputValidDomainOrIpv4_6 => '请输入合法的域名或IPv4/v6地址';

  @override
  String get historyRecord => '历史记录';

  @override
  String get myDevice => '我的设备';

  @override
  String get fileTransfer => '文件传输';

  @override
  String get appSettings => '应用设置';

  @override
  String get syncFile => '文件同步';

  @override
  String get preference => '偏好';

  @override
  String get preferenceSettingsRecordsDialogLocation => '历史记录弹窗显示位置';

  @override
  String get preferenceSettingsRecordsDialogSize => '记住上次弹窗尺寸';

  @override
  String get preferenceSettingsAutoClosePopupOnBlurTitle => '自动关闭弹窗';

  @override
  String get preferenceSettingsAutoClosePopupOnBlurDesc => '当弹窗失去焦点时自动关闭';

  @override
  String get current => '当前';

  @override
  String get followMousePos => '跟随鼠标位置';

  @override
  String get rememberLastPos => '记住上次位置';

  @override
  String get showOnRecentTasks => '在最近任务中显示';

  @override
  String get showOnRecentTasksDesc => '强迫症选项，若关闭则会在后台卡片中隐藏';

  @override
  String get showLocalIpAddress => '查看本机IP';

  @override
  String get localIpAddress => '本机IP';

  @override
  String get syncAutoCloseSettingTitle => '息屏自动断连';

  @override
  String get syncAutoCloseSettingDesc =>
      '息屏一段时间后断开同步连接（约2~10分钟）。如需后台保持连接，请勿启用此功能。';

  @override
  String get scan => '扫描二维码';

  @override
  String get noCameraPermission => '请授予相机权限';

  @override
  String get noPhotoPermission => '请授予相册权限';

  @override
  String get noNotificationPermission => '请授予通知权限';

  @override
  String get permissionSettingsIOSPhotosTitle => '相册权限';

  @override
  String get permissionSettingsIOSPhotosDesc => '无相册权限将无法保存图片到相册';

  @override
  String get qrCodeScannerPageTitle => '扫描二维码连接设备';

  @override
  String get qrCodeScanError => '扫描出错，请检查';

  @override
  String get attemptingToConnect => '尝试连接中';

  @override
  String get forwardServerStatus => '中转服务状态';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '已断开';

  @override
  String get initializing => '初始化中';

  @override
  String get connecting => '连接中';

  @override
  String get forwardMode => '中转模式';

  @override
  String get deviceId => '设备 ID';

  @override
  String get forwardServerNotConnected => '未连接中转服务器';

  @override
  String get cleanData => '数据清理';

  @override
  String get syncSettingsAutoCopyScreenShotTitle => '自动复制截图';

  @override
  String get syncSettingsAutoCopyScreenShotDesc => '部分系统可能在后台会有延迟';

  @override
  String get showMoreItemsInRow => '在一行中显示更多项';

  @override
  String get showMoreItemsInRowDesc => '当宽度足够时，历史记录和设备列表等将会在一行显示多项';

  @override
  String get filter => '过滤器';

  @override
  String get monday => '周一';

  @override
  String get tuesday => '周二';

  @override
  String get wednesday => '周三';

  @override
  String get thursday => '周四';

  @override
  String get friday => '周五';

  @override
  String get saturday => '周六';

  @override
  String get sunday => '周日';

  @override
  String get defaultClipboardServerNotificationCfgErrorTitle => '错误';

  @override
  String get defaultClipboardServerNotificationCfgErrorTextPrefix => '警告';

  @override
  String get defaultClipboardServerNotificationCfgRunningTitle =>
      '服务运行中Shizuku 模式';

  @override
  String get defaultClipboardServerNotificationCfgRootRunningText =>
      'Root 模式错误';

  @override
  String get startSendFileToast => '文件已开始发送，请查看发送进度';

  @override
  String get folder => '文件夹';

  @override
  String get removeFromPendingList => '从发送列表中移除';

  @override
  String get onlineDevices => '在线设备';

  @override
  String get noOnlineDevices => '无在线设备';

  @override
  String get pendingFiles => '待发送文件';

  @override
  String get clearPendingFiles => '清除待发送列表';

  @override
  String pendingFileLen(String len) {
    return '共 $len 个文件';
  }

  @override
  String get addFilesFromSystem => '从系统添加文件';

  @override
  String get viewPendingFiles => '查看待发送文件';

  @override
  String get sendFiles => '发送文件';

  @override
  String get unWriteablePathTips => '选择的位置无法写入，请重新选择';

  @override
  String get clipboardListeningWay => '剪贴板监听方式';

  @override
  String get clipboardListeningWayTips => '说明';

  @override
  String get clipboardListeningWithSystemHiddenApi => '系统隐藏API';

  @override
  String get clipboardListeningWithSystemLogs => '系统日志';

  @override
  String get clipboardListeningWayTipsDetail =>
      '提供两种监听模式，但可能不是都适用与您的设备，默认使用系统日志监听，但并不都适用，在某些设备上面发现可能无效。\n\n如：系统日志监听在 OriginOS 上无效，请根据实际情况启用';

  @override
  String clipboardListeningWayToggleConfirmContent(String way) {
    return '你确认切换监听模式吗？\n\n将切换到 $way';
  }

  @override
  String get closeOnSameHotKeyTitle => '使用相同快捷键关闭弹窗';

  @override
  String get closeOnSameHotKeyDesc => '默认鼠标点击窗体关闭按钮，启用后可以使用相同的快捷键打开和关闭弹窗';

  @override
  String get saveToAlbum => '保存至相册';

  @override
  String get openWithOtherApplications => '使用其它应用打开';

  @override
  String get enableAutoSyncOnScreenOpenedTitle => '屏幕亮起时发现设备';

  @override
  String get enableAutoSyncOnScreenOpenedDesc =>
      '当屏幕亮起将会扫描网络以发现设备，若启用了息屏后断开网络连接选项，当息屏时切换网络后可能不会自动连接设备';

  @override
  String get deviceDiscoveryStatusViaPaired => '连接已配对设备';

  @override
  String get export2Excel => '导出为Excel';

  @override
  String get export2ExcelFileName => '历史记录导出.xlsx';

  @override
  String get historyOutputTips => '确认按当前筛选条件导出吗？\n不会导出文件同步记录';

  @override
  String get exporting => '导出中...';

  @override
  String get modifyContent => '修改内容';

  @override
  String get confirmModifyContent => '确认更新内容？';

  @override
  String get modifyContentConfirmExitAndNoSave => '退出且不保存';

  @override
  String get unsavedTips => '内容未提交，是否确认退出该页面？';

  @override
  String get done => '完成';

  @override
  String get download => '下载';

  @override
  String get downloading => '下载中';

  @override
  String devDisconnectNotifyContent(String devName) {
    return '设备 $devName 连接断开';
  }

  @override
  String devConnectedNotifyContent(String devName) {
    return '设备 $devName 已连接';
  }

  @override
  String get clipboardSettingsGroupName => '剪贴板';

  @override
  String get clipboardSettingsTakeOverWinVTitle => '接管 Win+V';

  @override
  String get clipboardSettingsTakeOverWinVDesc => '使用 Win+V 唤起历史弹窗';

  @override
  String get clipboardSettingsTakeOverWinVDialogContent =>
      '接管 Win+V 会修改当前用户的系统热键配置，并重启资源管理器以立即生效。是否继续？';

  @override
  String get clipboardSettingsRestoreWinVOnExitTitle => '程序退出自动恢复';

  @override
  String get clipboardSettingsRestoreWinVOnExitDesc => '程序退出/卸载时自动恢复 Win+V';

  @override
  String get clipboardSettingsSourceRecordTitle => '记录剪贴板内容来源';

  @override
  String get clipboardSettingsSourceRecordAndroidDesc => '需要开启无障碍服务辅助记录';

  @override
  String get permissionSettingsAccessibilityTitle => '无障碍权限';

  @override
  String get permissionSettingsAccessibilityDesc => '启用无障碍权限以辅助记录剪贴板来源';

  @override
  String get noAccessibilityPermTips => '无障碍服务未启动，无法检测到用户主动复制的来源，是否授权无障碍服务权限？';

  @override
  String appIconLoadError(String appName) {
    return 'App图标加载失败($appName)';
  }

  @override
  String get clipboardSettingsSourceRecordTitleTooltip => '说明';

  @override
  String get clipboardSettingsSourceRecordDialogContent =>
      '来源检测分为两种：前台复制和其他app后台复制，前台复制需要借助无障碍权限来检测，后台复制可通过dumpsys来获取（有数百毫秒的延迟）。\n\n来源检测不能保证完全准确，主要通过无障碍识别，有可能会误标记到其他应用上面';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysTitle =>
      '通过 dumpsys 记录后台复制来源';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysTitleTooltip => '说明';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysDialogContent =>
      '如果有应用在后台复制有可能会误识别，通过 dumpsys 检测是谁写入了剪贴板以纠正';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysAndroidDesc =>
      '需要 Root 或 Shizuku 权限，同时会有数百毫秒的延迟';

  @override
  String get source => '来源';

  @override
  String get clearSourceConfirmText => '确认清除该记录的来源信息吗？';

  @override
  String get clearSuccess => '清除成功';

  @override
  String get clearFailed => '清除失败';

  @override
  String get selectApplication => '选择应用';

  @override
  String get preferenceSettingsDevDisconnNotification => '设备连接断开时发起系统通知';

  @override
  String get preferenceSettingsDevConnNotification => '设备连接后发起系统通知';

  @override
  String get preferenceSettingsNotifyOnReceivedFile => '接收文件后发起通知';

  @override
  String get preferenceSettingsNotifyOnReceivedFileDesc => '点击通知后自动打开文件';

  @override
  String get notification => '通知';

  @override
  String get aboutPageDatabaseVersionItemName => '数据库版本';

  @override
  String get newVersionAvailable => '发现新版本';

  @override
  String get showMainWindow => '显示主窗口';

  @override
  String get exitApp => '退出程序';

  @override
  String exitAppViaHotKey(String appName) {
    return '正在通过快捷键退出 $appName';
  }

  @override
  String get clearHotKeyConfirm => '确认要清除该快捷键吗？';

  @override
  String get pleaseEnterHotKey => '请按下快捷键';

  @override
  String get userApp => '用户应用';

  @override
  String get systemApp => '系统应用';

  @override
  String get fileNotFound => '未找到文件';

  @override
  String get openingFile => '正在打开文件';

  @override
  String get syncData => '同步数据';

  @override
  String get syncSettingsAutoSyncMissingDataTitle => '自动同步数据';

  @override
  String get syncSettingsAutoSyncMissingDataDesc => '在设备连接后自动同步断连期间缺失的数据';

  @override
  String get syncingData => '同步数据中';

  @override
  String get content => '内容';

  @override
  String get title => '标题';

  @override
  String get preferenceSettingsShowMobileNotificationTitle => '接收移动端设备通知';

  @override
  String get preferenceSettingsShowMobileNotificationDesc =>
      '已连接的移动端设备的通知将显示在本设备（需在源设备开启通知记录功能）';

  @override
  String get permissionSettingsNotificationRecordTitle => '通知历史访问权限';

  @override
  String get permissionSettingsNotificationRecordDesc =>
      '该权限用于记录通知历史。在某些设备上，授予此权限可能导致应用进程无法完全终止。如需停止应用，可点击此处取消授权后再进行操作。';

  @override
  String get noNotificationRecordPermTips => '无通知历史访问权限，无法记录通知历史';

  @override
  String get recordNotification => '记录通知历史';

  @override
  String get logSettingsAutoUploadCrashLogTitle => '崩溃日志自动上传';

  @override
  String get logSettingsAutoUploadCrashLogDesc =>
      '当 app 因崩溃闪退时上传崩溃错误日志供开发者分析问题';

  @override
  String get logSettingsAutoUploadCrashLogTips =>
      '此日志依赖于 ACRA 崩溃日志工具，仅上传必要的信息和崩溃堆栈供分析，崩溃日志可能会在再次启动应用时才会上传';

  @override
  String get backupRestore => '备份和恢复';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get backupSettingDesc => '导出备份为单独文件以供后续恢复数据库内容';

  @override
  String get restoreSettingDesc => '从备份文件中恢复数据';

  @override
  String get startUp => '开始';

  @override
  String get userCancelled => '用户已取消';

  @override
  String get cancelled => '已取消';

  @override
  String get exportFailedAndViewLogs => '导出失败，详情查看日志';

  @override
  String get exportSuccess => '导出成功';

  @override
  String get importing => '导入中';

  @override
  String get importFailed => '导入失败';

  @override
  String get importSuccess => '导入成功';

  @override
  String get restoreRestartPrompt => '请手动重启应用以加载最新的数据和配置信息';

  @override
  String get loading => '加载中';

  @override
  String get segmenting => '分词中';

  @override
  String get auto => '自动';

  @override
  String get doubleClick2OpenPath => '双击打开路径';

  @override
  String get editDb => '编辑数据库';

  @override
  String get enterSQLHere => '在此输入SQL...';

  @override
  String get optionalTables => '可选表名：';

  @override
  String get execSQL => '执行SQL';

  @override
  String get execSQLNoLimitTips =>
      '似乎是select语句但是未使用limit限制，如果数据过多可能会导致卡死，是否继续？';

  @override
  String get toggleSQLLimitCheck => '启用/禁用查询limit检测';

  @override
  String get result => '结果';

  @override
  String get execFailed => '执行失败';

  @override
  String get notificationServerStatus => '通知服务状态';

  @override
  String get notificationServerTips =>
      '使用存储服务作为中转时无法自动得知需要同步数据，需要依赖通知服务进行通知。\n可自建也可使用公共通知服务，通知内容不含任何敏感信息。';

  @override
  String get forwardSettingsWebDAVTitle => 'WebDAV配置信息';

  @override
  String get forwardSettingsS3Title => '对象存储配置信息';

  @override
  String get configureWebDAVServer => '配置 WebDAV';

  @override
  String get webdavServerUrlRequired => '请输入 WebDAV 服务器 URL';

  @override
  String get webdavUrlMustStartWithHttp => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get usernameRequired => '请输入用户名';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get baseDirectoryRequired => '请选择存储目录';

  @override
  String get baseDirectoryMustStartWithSlash => '基础目录必须以 / 开头';

  @override
  String get serverUrl => '服务器 URL';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get storagePath => '存储路径';

  @override
  String get storagePathHint => '选择基路径';

  @override
  String get pleaseInputCorrectURL => '请输入正确的URL';

  @override
  String get nameRequired => '请输入配置名称';

  @override
  String get configName => '配置名称';

  @override
  String get noConfig => '无配置';

  @override
  String get s3EndpointRequired => 'S3端点地址为必填项';

  @override
  String get accessKeyRequired => 'Access Key为必填项';

  @override
  String get secretKeyRequired => 'Secret Key为必填项';

  @override
  String get bucketNameRequired => '存储桶名称为必填项';

  @override
  String get configureS3Storage => '配置S3存储';

  @override
  String get endpoint => 'EndPoint';

  @override
  String get s3AccessKey => 'AccessKey';

  @override
  String get s3SecretKey => 'SecretKey';

  @override
  String get bucketName => '存储桶名称';

  @override
  String get region => '区域';

  @override
  String get optional => '可选';

  @override
  String get objectStorageType => '对象存储类型';

  @override
  String get standardS3Protocol => '标准S3协议';

  @override
  String get aliyunOss => '阿里云OSS';

  @override
  String get pleaseInputCorrectDomain => '请输入正确的域名';

  @override
  String get notificationServerConfigure => '通知服务配置';

  @override
  String get notificationServerAddress => '通知服务地址';

  @override
  String get regionRequired => '区域为必填项';

  @override
  String get pleaseInputCorrectWsURL => '请输入正确的地址 (ws:// 或 wss://) ';

  @override
  String get selectStoragePath => '选择存储路径';

  @override
  String get readonly => '只读';

  @override
  String get version => '版本';

  @override
  String get changeForwardWayConfirm => '是否确认切换中转方式？将会断开当前的中转相关的连接';

  @override
  String get s3 => '对象存储';

  @override
  String get none => '无';

  @override
  String get forwardServer => '中转服务器';

  @override
  String get forwardSettingsForwardEnableRequiredWebDAVText => '请先配置 WebDAV 服务';

  @override
  String get forwardSettingsForwardEnableRequiredS3Text => '请先配置 对象存储 服务';

  @override
  String get createFolder => '新建文件夹';

  @override
  String get invalidFolderName => '无效的名称，不能包含特殊字符且长度小于255';

  @override
  String get createFailed => '创建失败';

  @override
  String get notAllowRootPath => '不可使用根路径';

  @override
  String get rootPathCannotEnableForward => '存储路径不能为根路径';

  @override
  String get s3TypeTips =>
      '标准S3协议的对象存储产品均可直接填写配置使用\n\n已测试腾讯云、七牛云均正常\n\n阿里云OSS需要单独填写';

  @override
  String get forwardWay => '中转方式';

  @override
  String get backupTypeConfig => '配置信息';

  @override
  String get backupTypeAppInfo => '剪贴板来源';

  @override
  String get backupTypeDevice => '已配对设备信息';

  @override
  String get backupTypeHistory => '历史记录';

  @override
  String get backupTypeHistoryTag => '历史记录标签';

  @override
  String get backupTypeOperationRecord => '操作记录';

  @override
  String get backupTypeOperationSync => '同步记录';

  @override
  String get selectBackupItems => '选择备份恢复项';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get enterSoftware => '进入软件';

  @override
  String get segmentWords => '分词';

  @override
  String get downloadFromGithub => '从Github下载';

  @override
  String notFoundJiebaFiles(String dirPath) {
    return '未发现分词文件\n请下载分词文件后将其复制到 \n $dirPath \n文件夹下\n提示：仅需 dict.txt 和 prob_emit.txt 即可';
  }

  @override
  String get installJiebaDictFile => '安装';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get jiebaFileInstallSuccess => '分词文件安装成功！';

  @override
  String get encryptKey => '密钥';

  @override
  String get encryptKeyErrorTip => '长度不能小于8，且不能包含空白字符';

  @override
  String get confirmClearEncryptKey => '确认清除密钥吗？';

  @override
  String get authFailed => '验证失败';

  @override
  String get dhKeySettingName => '对加密参数进行加密';

  @override
  String get dhKeySettingDesc => '启用后，所有连接的设备都必须启用且密码相同，否则无法连接';

  @override
  String get dhKeySettingTips =>
      '对设备连接过程中使用的 Diffie–Hellman 密钥加密算法的参数进行加密。\n启用后，所有连接的设备都必须启用且密码相同，否则无法连接。\n\n当然，其实这个不使用也没什么问题。';

  @override
  String get syncOutDateSettingTitle => '同步数据范围';

  @override
  String get syncOutDateSettingDesc => '仅同步指定时间内的数据而不是全部同步';

  @override
  String get pleaseWait => '请稍等...';

  @override
  String get generateTodayAndroidLog => '生成 Android 原生日志（当天）';

  @override
  String get noDiscoveryIfsSettingTitle => '设备发现排除网卡';

  @override
  String get noDiscoveryIfsSettingDesc => '在设备发现流程中的子网扫描时跳过指定网卡';

  @override
  String get onlyManualDiscoverySubNetSettingTitle => '仅手动子网扫描发现设备';

  @override
  String get onlyManualDiscoverySubNetSettingDesc =>
      '在网络切换/屏幕亮起后不进行子网扫描，仅在设备页面手动点击发现时才进行子网扫描';

  @override
  String get stopListeningOnScreenClosedSettingTitle => '息屏后停止监听（实验性）';

  @override
  String get stopListeningOnScreenClosedSettingDesc =>
      '息屏一分钟后停止监听剪贴板，在某些设备上可能能节省电量';

  @override
  String get keepConnectionsOnNetworkSwitchTitle => '切网时保持连接';

  @override
  String get keepConnectionsOnNetworkSwitchDesc =>
      '开启后，仅在 WiFi 与移动网络互切或无网络与有网络切换时主动断开重连，其余网络变化保持现有连接';

  @override
  String get notNow => '本次忽略';

  @override
  String get faq => '常见问题';

  @override
  String get sendBroadcastOnAddData => '新增数据时发送广播';

  @override
  String get sendBroadcastOnAddDataDesc =>
      '当剪贴板改变/同步新数据时发送一个系统广播以通知其他app如Tasker进行额外处理';

  @override
  String get explain => '说明';

  @override
  String sendBroadcastOnAddDataTips(String kOnHistoryChangedBroadcastAction) {
    return '广播Action为：$kOnHistoryChangedBroadcastAction\n\n当前广播中含有以下变量：\n1.type: 内容类型，有效值为：text, image, sms, file, notification\n2.content: 内容，当为图片和文件时是本机路径，当为通知时是json\n3.from_dev_id：来源设备id\n4.from_dev_name: 来源设备名称';
  }

  @override
  String get recopyOnScreenUnlockedTitle => '解锁后重新复制最新数据';

  @override
  String get recopyOnScreenUnlockedTitleDesc =>
      '部分系统在锁屏状态下无法自动复制，启用该功能后会在屏幕解锁后再去重试复制最新同步的数据';

  @override
  String get rulesManagement => '规则管理';

  @override
  String get excludePrivateFormat => '不记录排除格式';

  @override
  String get excludePrivateFormatDesc => '不记录带有排除标记的剪贴板内容';

  @override
  String get excludePrivateFormatTips =>
      '当检测到剪贴板内容含有 ExcludeClipboardContentFromMonitorProcessing 标记时，将不会记录该内容。';

  @override
  String get moreActions => '更多操作';

  @override
  String get retainDays => '保留最近';

  @override
  String get onlyLocal => '仅本地';

  @override
  String get enablePIP => '开启画中画悬浮窗';

  @override
  String get enablePIPTip => '开启后接收到的视频文件可直接使用画中画打开，也可增强剪贴板获取';

  @override
  String get permissionSettingsClipboardTitle => '剪贴板权限';

  @override
  String get permissionSettingsClipboardDesc =>
      'Android 上部分系统默认设置为使用时允许，此时应用无法在后台操作剪贴板，请求该权限可解决';

  @override
  String get local => '本地';

  @override
  String get directConnect => '直连';

  @override
  String get selectBackupSource => '备份文件存储位置';

  @override
  String get notConfigured => '未配置';

  @override
  String get storagePathTips =>
      '注意：备份文件和中转文件存储于同一目录下的不同文件夹中\n如若存储路径选择为 /ClipShare\n则中转文件则存储于 /ClipShare/history 中\n备份文件存储于 /ClipShare/backup 中';

  @override
  String get uploading => '上传中';

  @override
  String get useTrayFlashingForConnectionTitle => '设备连接或断开后使用托盘闪烁';

  @override
  String get useTrayFlashingForConnectionDesc => '若启用则表示使用托盘闪烁的方式否则为默认的系统通知';

  @override
  String trayDevAliveTooltip(
    String first,
    String pairedCnt,
    String unpairedCnt,
  ) {
    return '$first\n已连接 $pairedCnt 个配对设备\n已连接 $unpairedCnt 个未配对设备';
  }

  @override
  String get displayExtractedContent => '显示提取内容';

  @override
  String get displayOriginContent => '显示原始内容';

  @override
  String get codePromptParamsContentIsSyncDisabled => '是否阻止同步';

  @override
  String get codePromptParamsContentTags => '标签';

  @override
  String get codePromptParamsContentExtracted => '提取的内容';

  @override
  String get codePromptParamsContentDetail => '内容';

  @override
  String get codePromptParamsContentNotificationTitle => '通知标题，仅在类型为通知时可用';

  @override
  String get codePromptParamsContentSource => '内容来源，可能是本机路径或者是App包名';

  @override
  String get codePromptParamsContentType => '内容类型';

  @override
  String get codePromptNotificationType => '通知';

  @override
  String get codePromptImageType => '图片';

  @override
  String get codePromptTextType => '文本';

  @override
  String get codePromptSmsType => '短信';

  @override
  String get codePromptJsonDecode => 'Json解码';

  @override
  String get codePromptLogError => '输出错误级别的日志信息';

  @override
  String get codePromptLogWarn => '输出警告级别的日志信息';

  @override
  String get codePromptLogDebug => '输出调试级别的日志信息';

  @override
  String get codePromptLogInfo => '输出信息级别的日志信息';

  @override
  String get codePromptContentType => '内容类型';

  @override
  String get codePromptJson => 'Json库';

  @override
  String get codePromptLog => '日志库';

  @override
  String get codePromptPrint => '打印输出，等同于 logger.debug() ';

  @override
  String get codePromptMath => '数学库';

  @override
  String get codePromptString => '字符串库';

  @override
  String get codePromptTable => '表操作库';

  @override
  String get codePromptUtf8 => 'UTF8 编码库';

  @override
  String get codePromptOs => '系统库（安全子集）';

  @override
  String get codePromptType => '获取变量类型';

  @override
  String get codePromptToString => '转换为字符串';

  @override
  String get codePromptToNumber => '转换为数字';

  @override
  String get codePromptPairs => '遍历 table（键值对）';

  @override
  String get codePromptIpairs => '遍历数组';

  @override
  String get codePromptNext => '获取下一个元素';

  @override
  String get codePromptPcall => '安全调用函数';

  @override
  String get codePromptXpcall => '带错误处理的调用';

  @override
  String get codePromptSelect => '获取可变参数';

  @override
  String get codePromptAssert => '断言检查';

  @override
  String get codePromptError => '抛出错误';

  @override
  String get codePromptMathAbs => '绝对值';

  @override
  String get codePromptMathAcos => '反余弦';

  @override
  String get codePromptMathAsin => '反正弦';

  @override
  String get codePromptMathAtan => '反正切';

  @override
  String get codePromptMathCeil => '向上取整';

  @override
  String get codePromptMathCos => '余弦';

  @override
  String get codePromptMathDeg => '弧度转角度';

  @override
  String get codePromptMathExp => '指数运算';

  @override
  String get codePromptMathFloor => '向下取整';

  @override
  String get codePromptMathFmod => '取模余数';

  @override
  String get codePromptMathHuge => '最大浮点值';

  @override
  String get codePromptMathLog => '对数';

  @override
  String get codePromptMathMax => '最大值';

  @override
  String get codePromptMathMaxInteger => '最大整数';

  @override
  String get codePromptMathMin => '最小值';

  @override
  String get codePromptMathMinInteger => '最小整数';

  @override
  String get codePromptMathModf => '拆分整数和小数部分';

  @override
  String get codePromptMathPi => '圆周率常量';

  @override
  String get codePromptMathRad => '角度转弧度';

  @override
  String get codePromptMathRandom => '随机数';

  @override
  String get codePromptMathRandomSeed => '设置随机种子';

  @override
  String get codePromptMathSin => '正弦';

  @override
  String get codePromptMathSqrt => '平方根';

  @override
  String get codePromptMathTan => '正切';

  @override
  String get codePromptMathToInteger => '转换为整数';

  @override
  String get codePromptMathType => '数字子类型';

  @override
  String get codePromptMathUlt => '无符号整数比较';

  @override
  String get codePromptStringByte => '获取字符编码';

  @override
  String get codePromptStringChar => '根据字符编码生成字符串';

  @override
  String get codePromptStringDump => '导出函数字节码';

  @override
  String get codePromptStringLen => '字符串长度';

  @override
  String get codePromptStringSub => '截取字符串';

  @override
  String get codePromptStringFind => '查找子串';

  @override
  String get codePromptStringFormat => '格式化字符串';

  @override
  String get codePromptStringGMatch => '迭代匹配结果';

  @override
  String get codePromptStringGSub => '替换匹配内容';

  @override
  String get codePromptStringLower => '转小写';

  @override
  String get codePromptStringMatch => '模式匹配';

  @override
  String get codePromptStringPack => '打包为二进制字符串';

  @override
  String get codePromptStringPackSize => '获取打包后的大小';

  @override
  String get codePromptStringRep => '重复字符串';

  @override
  String get codePromptStringReverse => '反转字符串';

  @override
  String get codePromptStringUnpack => '解包二进制字符串';

  @override
  String get codePromptStringUpper => '转大写';

  @override
  String get codePromptTableInsert => '插入元素';

  @override
  String get codePromptTableMove => '在表之间移动元素';

  @override
  String get codePromptTableRemove => '删除元素';

  @override
  String get codePromptTableSort => '排序';

  @override
  String get codePromptTableConcat => '拼接字符串';

  @override
  String get codePromptUtf8Len => 'UTF8 字符串长度';

  @override
  String get codePromptUtf8Char => '生成 UTF8 字符';

  @override
  String get codePromptUtf8CharPattern => 'UTF8 字符匹配模式';

  @override
  String get codePromptUtf8Codes => '迭代 UTF8 码点';

  @override
  String get codePromptUtf8CodePoint => '获取 UTF8 码点';

  @override
  String get codePromptUtf8Offset => '获取 UTF8 偏移位置';

  @override
  String get codePromptOsClock => 'CPU 时间';

  @override
  String get codePromptOsDate => '获取日期';

  @override
  String get codePromptOsTime => '获取时间戳';

  @override
  String get codePromptOsDiffTime => '时间差';

  @override
  String get codePromptLuaVersion => '当前 Lua 版本';

  @override
  String get codePromptTablePack => '打包参数为表';

  @override
  String get codePromptTableUnpack => '展开表为多个返回值';

  @override
  String get codePromptScriptParams => '脚本参数，包含内容，类型，来源等信息';

  @override
  String get codePromptIfSnippet => 'if 条件判断代码片段';

  @override
  String get codePromptElseSnippet => 'else 分支代码片段';

  @override
  String get codePromptElseIfSnippet => 'elseif 分支代码片段';

  @override
  String get codePromptWhileSnippet => 'while 循环代码片段';

  @override
  String get codePromptRepeatSnippet => 'repeat 循环代码片段';

  @override
  String get codePromptForSnippet => 'for 数值循环代码片段';

  @override
  String get codePromptForStepSnippet => 'for 步长循环代码片段';

  @override
  String get codePromptIPairsSnippet => 'ipairs 数组遍历代码片段';

  @override
  String get codePromptPairsSnippet => 'pairs 表遍历代码片段';

  @override
  String get codePromptFunctionSnippet => '函数定义代码片段';

  @override
  String get codePromptLocalFunctionSnippet => '本地函数定义代码片段';

  @override
  String get codePromptPlatformAndroid => 'Android 平台';

  @override
  String get codePromptNotify => '通知';

  @override
  String get codePromptAndroidToast => 'Android Toast 提示';

  @override
  String get codePromptAndroidSendHistoryChangedBroadcast => 'Android 发送历史变更广播';

  @override
  String get codePromptPlatform => '平台';

  @override
  String get codePromptPlatformIsAndroid => '判断是否为 Android 平台';

  @override
  String get codePromptPlatformIsIOS => '判断是否为 iOS 平台';

  @override
  String get codePromptPlatformIsWindows => '判断是否为 Windows 平台';

  @override
  String get codePromptPlatformIsMacOS => '判断是否为 macOS 平台';

  @override
  String get codePromptPlatformIsLinux => '判断是否为 Linux 平台';

  @override
  String get codePromptApp => 'App';

  @override
  String get codePromptAppVersionName => 'App 版本名称';

  @override
  String get codePromptAppVersionNumber => 'App 版本号';

  @override
  String get codePromptDeviceSelf => '当前设备';

  @override
  String get codePromptDeviceSelfName => '当前设备名称';

  @override
  String get codePromptDeviceSelfId => '当前设备 ID';

  @override
  String get codePromptCrypto => '加密校验';

  @override
  String get codePromptCryptoMD5 => '计算 MD5 哈希';

  @override
  String get codePromptCryptoSHA256 => '计算 SHA-256 哈希';

  @override
  String get codePromptCryptoSHA1 => '计算 SHA-1 哈希';

  @override
  String get codePromptBase64 => 'Base64 计算';

  @override
  String get codePromptBase64Encode => '编码为 Base64 ';

  @override
  String get codePromptBase64Decode => '解码 Base64';

  @override
  String get codePromptRegex => '正则表达式';

  @override
  String get codePromptRegexMatch => '匹配所有完整结果并返回列表';

  @override
  String get codePromptRegexMatchGroups => '匹配所有捕获组并返回嵌套列表';

  @override
  String get codePromptHttp => 'Http请求库';

  @override
  String get codePromptTask => '异步任务库';

  @override
  String get codePromptAsync => '将某个方法包装为异步方法，使其内部可使用 await';

  @override
  String get codePromptAwait => '等待一个 awaiter 完成并返回其结果；只能在被 async 包装的函数内使用';

  @override
  String get codePromptHttpGet => 'Get请求方法(异步)';

  @override
  String get codePromptHttpPost => 'Post请求方法(异步)';

  @override
  String get codePromptPut => 'Put请求方法(异步)';

  @override
  String get codePromptDelete => 'Delete请求方法(异步)';

  @override
  String get codePromptTaskCreate => '创建一个任务(awaiter)';

  @override
  String get rulesPageUnsavedChangesConfirm => '尚有未保存的修改，确认继续操作？';

  @override
  String get ruleItemContentRequired => '规则内容不可为空';

  @override
  String get ruleItemExtractRuleRequired => '内容提取规则不可为空';

  @override
  String get ruleItemScriptContentRequired => '脚本内容不可为空';

  @override
  String get ruleItemUnsupportedOperation => '不支持的操作';

  @override
  String get ruleTriggerOnCopyText => '复制后';

  @override
  String get ruleTriggerOnNotificationText => '新通知';

  @override
  String get ruleTriggerOnSmsText => '新短信';

  @override
  String get ruleDetailRegexHint => '请输入正则表达式';

  @override
  String get ruleDetailNameLabel => '规则名称: ';

  @override
  String get ruleDetailNameHint => '请输入规则名称';

  @override
  String get ruleDetailPlatformLabel => '平台';

  @override
  String get ruleDetailTriggerLabel => '触发时机';

  @override
  String get ruleDetailRuleLabel => '规则';

  @override
  String get ruleDetailRegexTab => '正则表达式';

  @override
  String get ruleDetailScriptTab => '脚本';

  @override
  String get ruleDetailAutoWrapTooltip => '自动换行';

  @override
  String get ruleDetailFullScreenTooltip => '进入全屏编辑模式';

  @override
  String get ruleDetailModeDefault => '默认';

  @override
  String get ruleDetailModeBlacklist => '黑名单';

  @override
  String get ruleDetailModeWhitelist => '白名单';

  @override
  String get ruleDetailRegexLabel => '识别规则：';

  @override
  String get ruleDetailRegexTip => '正则默认忽略大小写，提取规则只提取匹配到的第一个内容';

  @override
  String get ruleDetailExtractContent => '提取规则：';

  @override
  String get ruleDetailModeLabel => '规则模式';

  @override
  String get ruleDetailActionLabel => '动作';

  @override
  String get ruleDetailAddTagLabel => '添加标签：';

  @override
  String get ruleDetailAddTagDialogTitle => '添加标签';

  @override
  String get ruleDetailFinalRule => '终止后续规则';

  @override
  String get ruleDetailRunTestTooltip => '运行测试';

  @override
  String get ruleDetailPageTitle => '规则详情';

  @override
  String get ruleModulesDetailSyntaxError => '包含语法错误，请修正';

  @override
  String get scriptModulesDetailDisplayNameRequired => '显示名称不能为空';

  @override
  String get scriptModulesDetailModuleNameRequired => '模块名称不能为空';

  @override
  String get scriptModulesDetailModuleNameDuplicated => '模块名称不能重复';

  @override
  String get scriptModuleDetailContentRequired => '内容不能为空';

  @override
  String get scriptModuleDetailDisplayNameLabel => '显示名称: ';

  @override
  String get scriptModuleDetailDisplayNameHint => '请输入显示名称';

  @override
  String get scriptModuleDetailModuleNameLabel => '模块名';

  @override
  String get scriptModuleDetailModuleNameImmutableTooltip => '保存后将不再支持修改模块名';

  @override
  String get scriptModuleDetailModuleNameHint => '模块名';

  @override
  String get scriptModuleDetailNameInvalid => '只能使用字母、数字、下划线，且不能以数字开头';

  @override
  String get scriptModuleDetailPageTitle => '模块详情';

  @override
  String get ruleListDeleteModuleConfirm => '是否删除？若有其他脚本在使用，脚本将会失效！';

  @override
  String get ruleListExitSelectionModeTooltip => '退出选择模式';

  @override
  String get ruleCardDragDisabledTooltip => '保存数据或清空搜索输入后可拖拽排序';

  @override
  String get ruleCardDragTooltip => '拖拽排序';

  @override
  String get scriptEditTestViewPanelTooltip => '运行面板';

  @override
  String get scriptEditTestViewRunTooltip => '运行';

  @override
  String get scriptEditTestViewExitFullScreenTooltip => '退出全屏编辑模式';

  @override
  String get scriptTestPanelParamsTab => '参数';

  @override
  String get scriptTestPanelCompileInfoTab => '编译信息';

  @override
  String get scriptTestPanelOutputTab => '输出';

  @override
  String get scriptTestPanelRunResultTab => '运行结果';

  @override
  String get scriptTestPanelCollapseTooltip => '折叠';

  @override
  String get ruleCompileCodeNotFound => '未找到代码';

  @override
  String get ruleCompileCodeEmpty => '代码为空';

  @override
  String get ruleCompileSuccess => '编译成功。';

  @override
  String ruleCompileFailedPrefix(String message) {
    return '编译失败：\n$message';
  }

  @override
  String get scriptModuleCompileReturnTableRequired => '模块的返回值必须是 table。';

  @override
  String get success => '成功';

  @override
  String get error => '错误';

  @override
  String get extracted => '提取内容';

  @override
  String get tags => '标签';

  @override
  String get flags => '标记';

  @override
  String get finalRule => '最终规则';

  @override
  String get dropped => '丢弃';

  @override
  String get syncDisabled => '阻止同步';

  @override
  String get rules => '规则';

  @override
  String get scriptModules => '脚本模块';

  @override
  String get modules => '模块';

  @override
  String get unknown => '未知';

  @override
  String get triggerOnCopy => '触发模式：复制';

  @override
  String get triggerOnNotification => '触发模式：通知';

  @override
  String get triggerOnSms => '触发模式：短信';

  @override
  String get modulesTip =>
      '可导入纯 lua 库，或者 封装一些经常使用到的方法以供脚本调用，返回值必须是 table。\n沙箱环境与脚本中一致';

  @override
  String get recordMaxLength => '最大内容长度';

  @override
  String get recordMaxLengthTips => '在部分设备中如果内容大小超过2MB，将会导致查询异常（但可入库）';

  @override
  String get length => '长度';

  @override
  String get mustGreaterThanZero => '必须 >= 0';

  @override
  String get settingsSectionLanguageSubtitle => '显示语言';

  @override
  String get settingsSectionPreferenceSubtitle => '界面与交互';

  @override
  String get settingsSectionNotificationSubtitle => '通知提醒';

  @override
  String get settingsSectionClipboardSubtitle => '剪贴板记录与采集';

  @override
  String get settingsSectionPermissionSubtitle => '悬浮窗、通知等权限授权';

  @override
  String get settingsSectionFloatWindowSubtitle => '悬浮与保活';

  @override
  String get settingsSectionDiscoverySubtitle => '设备与连接';

  @override
  String get settingsSectionForwardSubtitle => '中转与存储';

  @override
  String get settingsSectionSecuritySubtitle => '验证与加密';

  @override
  String get settingsSectionHotKeySubtitle => '自定义弹窗、窗体快捷键';

  @override
  String get settingsSectionSyncSubtitle => '同步与保存';

  @override
  String get settingsSectionCleanDataSubtitle => '清理历史数据与记录';

  @override
  String get settingsSectionRulesSubtitle => '规则与脚本';

  @override
  String get settingsSectionBackupSubtitle => '数据备份';

  @override
  String get settingsSectionAboutLogSubtitle => '应用信息';

  @override
  String get settingsSectionStatisticsSubtitle => '数据统计';

  @override
  String get settingsOverviewPermissionNormal => '权限正常';

  @override
  String settingsOverviewPermissionIssueCount(String count) {
    return '$count 项待处理';
  }

  @override
  String get settingsOverviewForwardClosed => '未启用';

  @override
  String get storageWsVersionIncompatibleTitle => '通知服务版本不兼容';

  @override
  String storageWsVersionIncompatibleDialogContent(
    String version,
    String minVersion,
  ) {
    return '当前通知服务版本为 $version，最低需要 $minVersion，请升级通知服务后再使用存储同步。';
  }

  @override
  String get noTargetWindow => '粘贴失败，没有找到可接收此次粘贴操作的目标窗口';

  @override
  String get openTargetProcessFailed => '粘贴失败，无法打开目标进程以进行检查';

  @override
  String get inspectTargetFailed => '粘贴失败，无法读取目标进程的完整性级别，可能需要提升权限';

  @override
  String get inspectSelfFailed => '粘贴失败，无法读取当前进程的完整性级别';

  @override
  String get targetIntegrityHigher => '粘贴失败，可能需要提升权限';
}
