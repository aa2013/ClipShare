// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get unitWord => 'words';

  @override
  String get dialogCancelText => 'Cancel';

  @override
  String get dialogAuthorizationButtonText => 'Grant Access';

  @override
  String get floatPermRequestDialogTitle =>
      'Request Floating Window Permission';

  @override
  String get floatPermRequestDialogContent =>
      'Because Android 10+ blocks background clipboard access, the app reads clipboard changes indirectly through system logs and floating window access.\n\nTap OK to open the floating window permission page.';

  @override
  String get requiredPermDialogTitle => 'Required Permission Missing';

  @override
  String get floatPermMissingDialogContent =>
      'Grant floating window access, or the clipboard cannot be read in the background.';

  @override
  String get shizukuPermRequestDialogTitle => 'Shizuku Permission Request';

  @override
  String get shizukuPermRequestDialogContent =>
      'Due to restrictions on Android 10 and above, Shizuku is required to read the clipboard in the background. Otherwise, the app can only passively receive clipboard data and cannot automatically sync.';

  @override
  String get dontShowAgain => 'Don\'t Show Again';

  @override
  String get dontShowAgainConfirm => 'Confirm Don\'t Show Again?';

  @override
  String get notificationPermRequestDialogTitle =>
      'Request Notification Permission';

  @override
  String get notificationPermRequestDialogContent =>
      'Used to send system notifications.';

  @override
  String get batteryOptimization => 'Battery Optimization';

  @override
  String get batteryOptimizationPermRequestDialogContent =>
      'Turn off battery optimization to improve background keep-alive.\nIf tapping [Grant Access] does not respond, open the setting manually in your phone settings.';

  @override
  String get selectWorkMode => 'Select Work Mode';

  @override
  String get completed => 'Completed';

  @override
  String get completedGuideDesc => 'Setup complete.';

  @override
  String get floatPermGuideTitle => 'Floating Window Permission';

  @override
  String floatPermGuideDesc(String appName) {
    return 'On newer Android versions, $appName needs floating window access to read the clipboard in the background. After enabling it, you can open clipboard history from the screen edge and drag to select items.';
  }

  @override
  String get notificationPermGuideTitle => 'Notification Permission';

  @override
  String get notificationPermGuideDesc =>
      'Enable notifications to start the foreground service.';

  @override
  String get storagePermGuideTitle => 'Storage Permission';

  @override
  String get storagePermGuideDesc =>
      'Storage permission is required to sync images and files, otherwise files cannot be saved.';

  @override
  String get batteryOptimizationPermGuideDesc =>
      'To improve background keep-alive, exclude the app from battery optimization.\nAlso lock it in recent tasks and allow auto-start in your phone manager.\nIf tapping [Grant Access] does not respond, open the setting manually in your phone settings.';

  @override
  String get aboutPageInstructionsItemName => 'Guide';

  @override
  String get aboutPageJoinQQGroupItemName => 'Join QQ Group';

  @override
  String get aboutPageWebsiteItemName => 'Official Website';

  @override
  String get aboutPageLogsItemName => 'Changelog';

  @override
  String get aboutPageVersionItemName => 'App Version';

  @override
  String get authenticationPageTitle => 'Authentication';

  @override
  String get authenticationPageBackendTimeoutVerificationTitle =>
      'Timeout Verification';

  @override
  String get authenticationPageUsePassword => 'Use Password';

  @override
  String get authenticationPageStartVerification => 'Start Verification';

  @override
  String get authenticationPageRequireAuthentication =>
      'Authentication Required';

  @override
  String get deviceAdditionFailedDialogText => 'Device Addition Failed';

  @override
  String get rename => 'Rename';

  @override
  String get devicePageDisconnect => 'Disconnect';

  @override
  String get devicePageReconnect => 'Reconnect';

  @override
  String get devicePageUnpairedDialogContent => 'Do you want to unpair?';

  @override
  String get devicePageUnpairedButtonText => 'Unpair';

  @override
  String get devicePagePairingDialogTitle => 'Enter Pairing Code';

  @override
  String get devicePagePairingTimeoutText => 'Pairing timed out!';

  @override
  String get devicePagePairingErrorText => 'Wrong pairing code!';

  @override
  String get devicePagePairingDialogConfirmText => 'Pair';

  @override
  String devicePageMyDevicesText(String length) {
    return 'My Devices ($length)';
  }

  @override
  String get devicePageForwardServerText => 'Forward Connection';

  @override
  String devicePageDiscoverDevicesText(String length) {
    return 'Discover Devices ($length)';
  }

  @override
  String get devicePageRediscoverTooltip => 'Rediscover';

  @override
  String get devicePageManuallyTooltip => 'Add Device Manually';

  @override
  String get devicePageStopDiscoveringTooltip => 'Stop Discovering';

  @override
  String get sms => 'SMS';

  @override
  String get homeAppBarSyncingProgressText => 'Syncing';

  @override
  String get search => 'Search';

  @override
  String get logPageAppBarTitle => 'Log Records';

  @override
  String get all => 'All';

  @override
  String get text => 'Text';

  @override
  String get image => 'Image';

  @override
  String get file => 'File';

  @override
  String get moreFilter => 'More Filters';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get filterByDate => 'Filter by Date';

  @override
  String get filterByContentType => 'Filter by Type';

  @override
  String get filterBySource => 'Filter by Source';

  @override
  String get saveTopData => 'Keep Pinned Data';

  @override
  String get removeLocalFiles => 'Remove local files';

  @override
  String get saveFilterConfig => 'Save Filter Preset';

  @override
  String get saveAutoCleanConfig => 'Save Auto-clean Settings';

  @override
  String get noDataFromFilter => 'No data matched the filter';

  @override
  String filterCleaningConfirmation(String cnt) {
    return '$cnt items found. This cannot be undone.\nContinue?';
  }

  @override
  String get syncRecordsCleaningConfirmation =>
      'Clearing device sync records will resync data after the next connection.';

  @override
  String get onlyNotSync => 'Only Unsynced';

  @override
  String get syncRecordsCleanBtn => 'Clear Selected Sync Records';

  @override
  String get optionRecordsCleaningConfirmation =>
      'Clearing device operation records will stop unsynced data from auto-syncing again.';

  @override
  String get optionRecordsCleanBtn => 'Clear Selected Operation Records';

  @override
  String get autoCleanFrequency => 'Frequency';

  @override
  String get execTime => 'Run time';

  @override
  String get nextExecTime => 'Next cleaning time: ';

  @override
  String get errorCronTips => 'Enter a valid Unix cron expression';

  @override
  String get filterTips =>
      'If a filter is left empty, all options are included.\nThe date range is not saved in filter presets.';

  @override
  String get autoCleanConfigTitle => 'Auto-clean';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get selectWeekDay => 'Select Weekday';

  @override
  String get deleteItemsUnit => 'items';

  @override
  String get pleaseSelectDevices => 'Select devices first';

  @override
  String get saveSuccess => 'Saved!';

  @override
  String get pleaseSaveFilterConfig => 'Save a filter preset first';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get updateSuccess => 'Updated!';

  @override
  String get updateFailed => 'Update failed!';

  @override
  String get confirm => 'Confirm';

  @override
  String get toToday => 'Go to Today';

  @override
  String get clear => 'Clear';

  @override
  String get settingsSearchHint => 'Search settings...';

  @override
  String get filterByDevice => 'Filter by Device';

  @override
  String get filterByTag => 'Filter by Tag';

  @override
  String get envStatusLoadingText => 'Loading environment status...';

  @override
  String get shizukuModeStatusTitle => 'Shizuku Mode';

  @override
  String shizukuModeRunningDesc(String version) {
    return 'Service is running, API $version';
  }

  @override
  String get rootModeStatusTitle => 'Root Mode';

  @override
  String get rootModeRunningDesc => 'Authorized. Service is running.';

  @override
  String get serverNotRunningDesc =>
      'Service is not running. Some features are unavailable.';

  @override
  String get envPermissionIgnored => 'Permission Ignored';

  @override
  String get envPermissionIgnoredDesc => 'Some features may be unavailable';

  @override
  String get noSpecialPermissionRequired => 'No Special Permission Required';

  @override
  String get switchWorkingMode => 'Switch Working Mode';

  @override
  String get commonSettingsRunAtStartup => 'Run at Startup';

  @override
  String get commonSettingsRunMinimize => 'Start Minimized';

  @override
  String get floatWindow => 'Floating Window';

  @override
  String get commonSettingsShowHistoriesFloatWindow => 'Show History Panel';

  @override
  String get commonSettingsShowHistoriesFloatWindowTips =>
      'Double-tap or drag the handle left to open the history panel.';

  @override
  String get historyFloatTitle => 'Clipboard History';

  @override
  String get historyFloatCountTemplate => '{count} records';

  @override
  String get historyFloatImageUnavailable => 'Image unavailable';

  @override
  String commonSettingsHistoriesFloatWindowHandleWidthValue(String width) {
    return 'Handle Width: $width';
  }

  @override
  String get commonSettingsHistoriesFloatWindowHandleColor => 'Handle Color';

  @override
  String get commonSettingsHistoriesFloatWindowHandleColorTips =>
      'Pick a floating window color. Changes sync in real time.';

  @override
  String get commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle =>
      'Apply alpha to whole handle';

  @override
  String get commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips =>
      'When enabled, the handle border, grip, and inner overlay follow the selected color alpha together.';

  @override
  String get commonSettingsEnhanceBackgroundKeepAliveTitle =>
      'Boost Background Keep-alive';

  @override
  String get commonSettingsEnhanceBackgroundKeepAliveDesc =>
      'Show a 1 px floating window to improve background keep-alive on some devices.';

  @override
  String get commonSettingsLockHistoriesFloatWindowPosition =>
      'Lock Floating Window Position';

  @override
  String get preferenceSettingsRememberWindowSize =>
      'Remember Last Window Size';

  @override
  String get preferenceSettingsWindowSizeRecordValue => 'Recorded Value';

  @override
  String get preferenceSettingsWindowSizeDefaultValue => 'Default Value';

  @override
  String get commonSettingsTheme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get themeAuto => 'Follow System';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get permissionSettingsGroupName => 'Permissions';

  @override
  String get permissionSettingsNotificationTitle => 'Notification Permission';

  @override
  String get permissionSettingsNotificationDesc =>
      'Required to start the foreground service.';

  @override
  String get permissionSettingsFloatTitle => 'Floating Window Permission';

  @override
  String get permissionSettingsFloatDesc =>
      'Used on newer Android versions to read the clipboard through a floating window.';

  @override
  String get permissionSettingsBatteryOptimiseTitle => 'Battery Optimization';

  @override
  String get permissionSettingsBatteryOptimiseDesc =>
      'Exclude the app from battery optimization to reduce background kills.';

  @override
  String get permissionSettingsSmsTitle => 'SMS Access';

  @override
  String get permissionSettingsSmsDesc =>
      'SMS sync is enabled. Please grant SMS access.';

  @override
  String get discoveringSettingsGroupName => 'Discovery';

  @override
  String get discoveringSettingsLocalDeviceName => 'Device Name';

  @override
  String get discoveringSettingsDeviceNameCopyTip => 'Device ID copied';

  @override
  String get copyDeviceId => 'Copy Device ID';

  @override
  String get modifyDeviceName => 'Rename Device';

  @override
  String get deviceName => 'Device Name';

  @override
  String get modifyDeviceNameCompletedTooltip => 'Restart to apply changes';

  @override
  String get port => 'Port';

  @override
  String discoveringSettingsPortDesc(String port) {
    return 'Default: $port. Changing it may break auto-discovery.';
  }

  @override
  String get modifyPort => 'Change Port';

  @override
  String get modifyPortErrorText => 'Port number range 0-65535';

  @override
  String get discoveringSettingsModifyPortCompletedTooltip =>
      'Restart to apply changes';

  @override
  String get allowDiscovering => 'Discoverable';

  @override
  String get discoveringSettingsAllowDiscoveringDesc =>
      'Can be automatically discovered by other devices';

  @override
  String get discoveringSettingsOnlyForwardDiscoveringTitle =>
      'Forward-only Discovery (Debug)';

  @override
  String get discoveringSettingsOnlyForwardDiscoveringDesc =>
      'Visible only in development builds';

  @override
  String get discoveringSettingsHeartbeatIntervalTitle => 'Heartbeat Interval';

  @override
  String get discoveringSettingsHeartbeatIntervalDesc =>
      'Device online check. Default: 30s; 0 disables it.';

  @override
  String get discoveringSettingsHeartbeatIntervalTooltip => 'Info';

  @override
  String get enable => 'Enable';

  @override
  String get dontDetect => 'Don\'t Detect';

  @override
  String get discoveringSettingsHeartbeatIntervalDialogContent =>
      'When a device switches networks, its offline status cannot be detected automatically.\nEnable heartbeat checks to verify device availability at intervals.';

  @override
  String get discoveringSettingsModifyHeartbeatDialogTitle =>
      'Heartbeat Interval';

  @override
  String get discoveringSettingsModifyHeartbeatDialogInputLabel =>
      'Heartbeat IntervalSeconds. 0 disables it.';

  @override
  String get forwardSettingsGroupName => 'Forward';

  @override
  String get forwardSettingsForwardTitle => 'Use Forward Service';

  @override
  String get forwardSettingsForwardDownloadTooltip =>
      'Download Forward Service';

  @override
  String get forwardSettingsForwardDesc =>
      'Sync over the internet through a forward server.';

  @override
  String get forwardSettingsForwardEnableRequiredText =>
      'Set the forward server address first.';

  @override
  String get forwardSettingsForwardAddressTitle => 'Forward Server Address';

  @override
  String get forwardSettingsForwardAddressDesc =>
      'Use a trusted server or host your own.';

  @override
  String get configure => 'Configure';

  @override
  String get change => 'Change';

  @override
  String get securitySettingsGroupName => 'Security';

  @override
  String get securitySettingsEnableSecurityTitle => 'Enable Authentication';

  @override
  String get securitySettingsEnableSecurityDesc =>
      'Use password or biometrics.Please create an app password first';

  @override
  String get securitySettingsEnableSecurityAppPwdModifyTitle =>
      'Change Password';

  @override
  String get createAppPwd => 'Create App Password';

  @override
  String get changeAppPwd => 'Change App Password';

  @override
  String get create => 'Create';

  @override
  String get securitySettingsReverificationTitle => 'Password Recheck';

  @override
  String get securitySettingsReverificationDesc =>
      'Ask for the password again after the app stays in the background for a while.';

  @override
  String securitySettingsReverificationValue(String value) {
    return '$value minutes';
  }

  @override
  String get hotKeySettingsGroupName => 'Hotkeys';

  @override
  String get hotKeySettingsHistoryTitle => 'History Popup';

  @override
  String get hotKeySettingsHistoryDesc =>
      'Open the history popup from anywhere on screen';

  @override
  String get hotKeySettingsHistoryTakeOverWinVTooltip => 'Win+V is taken over';

  @override
  String get hotKeySettingsCombinationInvalidText =>
      'A hotkey must include one modifier and one non-modifier key.';

  @override
  String hotKeySettingsSaveKeysDialogText(String keys) {
    return 'Save hotkey \"$keys\"?';
  }

  @override
  String hotKeySettingsSaveKeysFailedText(String err) {
    return 'Failed to save: $err';
  }

  @override
  String get sendFile => 'Send File';

  @override
  String get hotKeySettingsFileDesc =>
      'Send selected files to other devices; desktop selection is unsupported';

  @override
  String get syncSettingsGroupName => 'Sync';

  @override
  String get syncSettingsSmsPermissionRequired => 'Grant SMS access first.';

  @override
  String get syncSettingsStoreImg2PicturesTitle => 'Save Images to Pictures';

  @override
  String syncSettingsStoreImg2PicturesDesc(String appName) {
    return 'Saved to Pictures/$appName';
  }

  @override
  String get syncSettingsStoreImg2PicturesNoPermText =>
      'Storage access required.';

  @override
  String get syncSettingsStoreImg2PicturesCancelPerm =>
      'Permission request canceled.';

  @override
  String get syncSettingsStoreImagePathTitle => 'Image Storage Path';

  @override
  String get syncSettingsStoreFilePathTitle => 'File Storage Path';

  @override
  String get selection => 'Select';

  @override
  String get syncSettingsAutoCopyImgTitle => 'Copy Images Automatically';

  @override
  String get syncSettingsAutoCopyImgDesc =>
      'When enabled, images copied on other devices are also copied locally.';

  @override
  String get logSettingsGroupName => 'Logs';

  @override
  String get logSettingsEnableTitle => 'Enable Logging';

  @override
  String logSettingsEnableDesc(String size) {
    return 'Uses extra storage. Current logs: $size';
  }

  @override
  String get openFolder => 'Open Folder';

  @override
  String get openFilePos => 'Open File Location';

  @override
  String get tips => 'Tips';

  @override
  String get logSettingsDeleteLogFilesDialogContent => 'Delete log files?';

  @override
  String get statisticsSettingsGroupName => 'Statistics';

  @override
  String get about => 'About';

  @override
  String get errorDialogTitle => 'Error';

  @override
  String get selfDeviceName => 'Self';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get saveFileNotSupportDialogText => 'Unsupported Type';

  @override
  String get pieDataStatisticsLocalItemLabel => 'Local';

  @override
  String get pieDataStatisticsSyncItemLabel => 'Sync';

  @override
  String get statisticsPageAppBarText => 'Statistics';

  @override
  String get statisticsPageFilterRangeText => 'Range';

  @override
  String get refresh => 'Refresh';

  @override
  String get statisticsPageHistoryTypeCntTitle => 'Record Count by Type';

  @override
  String get statisticsPageSyncRatePie => 'Sync Ratio';

  @override
  String get statisticsPageHistoryCntForDevice => 'Record Count by Device';

  @override
  String get statisticsPageHistoryTagCnt => 'Record Count by Tag';

  @override
  String get syncingFilePageHistoryTabText => 'History';

  @override
  String get syncingFilePageReceiveTabText => 'Receiving';

  @override
  String get syncingFilePageSendTabText => 'Sending';

  @override
  String get dragFileToSend => 'Drag files here to send';

  @override
  String get deleting => 'Deleting...';

  @override
  String get deletingSuccess => 'Deleted Successfully';

  @override
  String get partialDeletionFailed => 'Partial Deletion Failed';

  @override
  String get deletionFailed => 'Delete Failed';

  @override
  String get deselect => 'Deselect';

  @override
  String get delete => 'Delete';

  @override
  String get deleteWithFiles => 'Delete with Files';

  @override
  String syncingFilePageDeleteSelectedDialogContent(String length) {
    return 'Delete $length selected items?\nFiles from sent records will be kept.';
  }

  @override
  String get onlyDeleteRecordsText => 'Records Only';

  @override
  String get failedToReadUpdateLog => 'Failed to Read Update Log!';

  @override
  String get skipGuide => 'Skip';

  @override
  String get previousGuide => 'Previous';

  @override
  String get nextGuide => 'Next';

  @override
  String get finishGuide => 'Finish';

  @override
  String get previewPageNoSuchFile =>
      'Image does not exist or has been deleted';

  @override
  String get copyPathSuccess => 'Path copied';

  @override
  String get tagEditPageAppBarTitle => 'Edit Tag';

  @override
  String get tagEditPageSearchOrCreateTag => 'Search or Create Tag';

  @override
  String tagEditPageCrateTagItem(String tag) {
    return 'Create \"$tag\" Tag';
  }

  @override
  String get updateLogPageAppBarTitle => 'Changelog';

  @override
  String get failedToReadFile => 'Failed to Read File';

  @override
  String welcome(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get welcomeContent =>
      'Before you start, we need a few permissions and some basic setup.';

  @override
  String get startNow => 'Start Now';

  @override
  String get name_ => 'Name';

  @override
  String get ruleContent => 'Rule';

  @override
  String get deleteSuccess => 'Deleted Successfully';

  @override
  String get revoke => 'Revoke';

  @override
  String get importRules => 'Import Rules';

  @override
  String importRulesSuccess(String length) {
    return 'Imported $length rules';
  }

  @override
  String get importFromNet => 'Import from Network';

  @override
  String get importFromLocal => 'Import from Local';

  @override
  String get urlFormatErrorText => 'Please enter a valid URL';

  @override
  String get fetch => 'Fetch';

  @override
  String get fetchingData => 'Fetching Data...';

  @override
  String get failedToLoad => 'Failed to Load';

  @override
  String get noSuchFile => 'The selected file path does not exist!';

  @override
  String get addRule => 'Add Rule';

  @override
  String get importRule => 'Import Rule';

  @override
  String get import => 'Import';

  @override
  String get add => 'Add';

  @override
  String get modify => 'Modify';

  @override
  String get output => 'Export';

  @override
  String get outputRule => 'Export Rule';

  @override
  String get outputSuccess => 'Exported Successfully!';

  @override
  String get outputFailed => 'Export Failed';

  @override
  String get exitSelectionMode => 'Exit Selection Mode';

  @override
  String get selectAll => 'Select All';

  @override
  String get cancelSelectAll => 'Cancel Select All';

  @override
  String get multipleChoiceOperationAppBarTitle => 'Bulk Actions';

  @override
  String get forwardServerNotAllowedSendFile =>
      'This forward server does not allow file sync.';

  @override
  String get sendFailed => 'Send Failed';

  @override
  String get forwardServerUnknownResult => 'Unknown Result';

  @override
  String get forwardServerConnectFailed => 'Forward Server Connection Failed';

  @override
  String get devicePairingRequestNotificationContent => 'New Pairing Request';

  @override
  String get devicePairingRequestDialogTitle => 'Pairing Request';

  @override
  String pairingCodeDialogContent(String devName) {
    return 'Pairing request from $devName\nCode:';
  }

  @override
  String get cancelCurrentPairing => 'Cancel This Pairing';

  @override
  String get deviceDiscoveryStatusViaBroadcast => 'Broadcast Discovery';

  @override
  String get deviceDiscoveryStatusViaScan => 'Network Scan';

  @override
  String get deviceDiscoveryStatusViaForward => 'Forward Discovery';

  @override
  String get newVersionDialogTitle => 'New Version';

  @override
  String get newVersionDialogSkipText => 'Skip';

  @override
  String get newVersionDialogOkText => 'Download';

  @override
  String get defaultLinkTagName => 'Link';

  @override
  String get unknownHistoryContentType => 'Unknown';

  @override
  String get allHistoryContentType => 'All';

  @override
  String get textHistoryContentType => 'Text';

  @override
  String get imageHistoryContentType => 'Image';

  @override
  String get richTextHistoryContentType => 'Rich Text';

  @override
  String get smsHistoryContentType => 'SMS';

  @override
  String get fileHistoryContentType => 'File';

  @override
  String get dialogConfirmText => 'Confirm';

  @override
  String get dialogNeutralText => 'Neutral';

  @override
  String get dialogRestoreDefaultText => 'Restore Default';

  @override
  String get open => 'Open';

  @override
  String get openLink => 'Open Link';

  @override
  String get moment => 'Just Now';

  @override
  String get minutesAgo => 'minutes ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get connectFailed => 'Connection Failed';

  @override
  String get connectSuccess => 'Connection Successful';

  @override
  String get connect => 'Connect';

  @override
  String get addDeviceDialogTitle => 'Add Device';

  @override
  String get errorFormatIp => 'Please enter a valid IPv4/v6 address';

  @override
  String get inputPassword => 'Enter Password';

  @override
  String get inputAgain => 'Enter Again';

  @override
  String get inputErrorAndAgain => 'Incorrect input. Try again.';

  @override
  String get immediately => 'Immediately';

  @override
  String get minute => 'Minute';

  @override
  String get alreadyNewestAppVersion => 'Already up to date';

  @override
  String get checkUpdate => 'Check';

  @override
  String get topUp => 'Pin to Top';

  @override
  String get cancelTopUp => 'Unpin from Top';

  @override
  String get copyContent => 'Copy Content';

  @override
  String get copyMergedContent => 'Copy Merged Content';

  @override
  String get syncRecord => 'Sync Record';

  @override
  String get resyncRecord => 'Sync Again';

  @override
  String get openFile => 'Open File';

  @override
  String get openFileFolder => 'Open File Folder';

  @override
  String get tagsManagement => 'Tags';

  @override
  String get copySuccess => 'Copied Successfully';

  @override
  String get copyFailed => 'Copied Failed';

  @override
  String get clipboardContent => 'Clipboard Details';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String multiDeleteAsk(String length) {
    return 'Delete selected $length items?';
  }

  @override
  String get deleteCompleted => 'Delete Completed';

  @override
  String get shareFile => 'Share File';

  @override
  String get deleteTips => 'Delete Tips';

  @override
  String get clipListDeleteRecordDialogContent => 'Delete this record?';

  @override
  String get backToTop => 'Back to Top';

  @override
  String get fold => 'Collapse';

  @override
  String get unfold => 'Expand';

  @override
  String get clipboard => 'Clipboard';

  @override
  String get close => 'Close';

  @override
  String get tag => 'Tag';

  @override
  String get pleaseInput => 'Please Enter';

  @override
  String get forward => 'Forward';

  @override
  String get notCompatible => 'Version Incompatible';

  @override
  String notCompatibleDialogText(
    String minName,
    String minCode,
    String selfName,
    String selfCode,
  ) {
    return 'Incompatible with the device\'s software version, device connection and data sync may not work properly.\nMinimum version required is $minName($minCode)\nCurrent software version is $selfName($selfCode)';
  }

  @override
  String get emptyData => 'No Data';

  @override
  String get shizukuMode => 'Shizuku Mode';

  @override
  String get shizukuModeDesc =>
      'No Root needed. Requires Shizuku and must be reactivated after a restart.';

  @override
  String get shizukuModeBatteryOptimiseTips =>
      'To keep Shizuku authorized, exclude it from battery optimization and allow it to run in the background.';

  @override
  String get shizukuRequestFailedDialogText =>
      'Shizuku request failed. Make sure Shizuku is running and try again.';

  @override
  String get requestFailed => 'Request Failed';

  @override
  String get selectInstallerType => 'Select Installer Type';

  @override
  String get openPathAfterDownload => 'Open after download';

  @override
  String get updateFromZipTips =>
      'The portable ZIP also supports auto-updating upon download completion.';

  @override
  String get requestSuccess => 'Request Success';

  @override
  String get clipboardPermissionRequestFailed =>
      'Requesting clipboard permission requires Shizuku or Root';

  @override
  String get rootMode => 'Root Mode';

  @override
  String get rootModeDesc =>
      'Runs with Root. No reactivation needed after a restart.';

  @override
  String get waitingRequestResult => 'Waiting for Request Result';

  @override
  String get applyingSettings => 'Applying settings...';

  @override
  String get rootRequestFailedDialogText =>
      'Root access was not found. You can use Shizuku mode instead.';

  @override
  String get ignoreMode => 'Ignore';

  @override
  String get ignoreModeDesc =>
      'Clipboard cannot be monitored in the background, only passive sync is available';

  @override
  String multiChoiceModeSelectedText(String text) {
    return '$text items selected';
  }

  @override
  String get goAuthorize => 'Grant Access';

  @override
  String get cannotEmpty => 'Cannot be empty';

  @override
  String get ruleCannotEmpty => 'Rule cannot be empty';

  @override
  String get ruleAddDialogLabel => 'Rule';

  @override
  String get ruleAddDialogHint => 'Please enter a regular expression';

  @override
  String get validationTesting => 'Validation Testing';

  @override
  String get validationFailed => 'Validation Failed';

  @override
  String get verify => 'Verify';

  @override
  String get stop => 'Stop';

  @override
  String get failed => 'Failed';

  @override
  String get pleaseInputKey => 'Please Enter Key';

  @override
  String get forwardServerUnlimitedDevices =>
      'No restrictions for whitelist devices';

  @override
  String get publicForwardServer => 'Public Forward Server';

  @override
  String get forwardServerSyncFileRateLimit => 'File Sync Rate Limit';

  @override
  String get forwardServerCannotSyncFile =>
      'This forward server does not support file sync.';

  @override
  String get forwardServerNoLimits => 'No Restrictions';

  @override
  String get noLimits => 'No Limit';

  @override
  String get deviceUnit => 'Device';

  @override
  String get day => 'Day';

  @override
  String get hour => 'Hour';

  @override
  String get second => 'Second';

  @override
  String get forwardServerKeyNotStarted => 'Not Started';

  @override
  String get exhausted => 'Exhausted';

  @override
  String get forwardServerDeviceConnectionLimit => 'Device Connection Limit';

  @override
  String get forwardServerLifeSpan => 'Validity Period';

  @override
  String get forwardServerRemainingTime => 'Remaining Time';

  @override
  String get forwardServerRateLimit => 'Rate Limit';

  @override
  String get forwardServerRemark => 'Remark';

  @override
  String get configureForwardServerDialogTitle => 'Configure Forward Server';

  @override
  String get domainAndIp => 'Domain / IP';

  @override
  String get host => 'Host';

  @override
  String get useKey => 'Use Key';

  @override
  String get accessKey => 'Access Key';

  @override
  String get pleaseInputAccessKey => 'Please Enter Access Key';

  @override
  String get checkConnection => 'Test';

  @override
  String get pleaseInputValidPort => 'Please Enter a Valid Port';

  @override
  String get pleaseInputValidDomainOrIpv4_6 =>
      'Please Enter a Valid Domain or IPv4/v6 Address';

  @override
  String get historyRecord => 'Records';

  @override
  String get myDevice => 'Devices';

  @override
  String get fileTransfer => 'Transfer';

  @override
  String get appSettings => 'Settings';

  @override
  String get syncFile => 'Sync Files';

  @override
  String get preference => 'Preference';

  @override
  String get preferenceSettingsRecordsDialogLocation =>
      'History Popup Position';

  @override
  String get preferenceSettingsRecordsDialogSize => 'Records Dialog Size';

  @override
  String get preferenceSettingsAutoClosePopupOnBlurTitle =>
      'Auto-dismiss popups';

  @override
  String get preferenceSettingsAutoClosePopupOnBlurDesc =>
      'Dismisses popups when they lose focus.';

  @override
  String get current => 'Current';

  @override
  String get followMousePos => 'Follow Cursor';

  @override
  String get rememberLastPos => 'Remember last position';

  @override
  String get showOnRecentTasks => 'Show in Recent Tasks';

  @override
  String get showOnRecentTasksDesc =>
      'When off, hide the app from recent tasks.';

  @override
  String get showLocalIpAddress => 'Show Local IP Address';

  @override
  String get localIpAddress => 'Local IP Address';

  @override
  String get syncAutoCloseSettingTitle => 'Screen-off Auto Disconnect';

  @override
  String get syncAutoCloseSettingDesc =>
      'Disconnect sync after the screen stays off for 2-10 minutes. Leave this off to keep background connections.';

  @override
  String get scan => 'Scan QRCode';

  @override
  String get noCameraPermission => 'Please grant camera permission';

  @override
  String get noPhotoPermission => 'Please grant photo permission';

  @override
  String get noNotificationPermission => 'Please grant notification permission';

  @override
  String get permissionSettingsIOSPhotosTitle => 'Photo Permission';

  @override
  String get permissionSettingsIOSPhotosDesc =>
      'Without this permission, images cannot be saved to Photos.';

  @override
  String get qrCodeScannerPageTitle => 'Scan to Connect';

  @override
  String get qrCodeScanError =>
      'This does not look like a ClipShare connection QR code. Please check.';

  @override
  String get attemptingToConnect => 'Attempting to connect';

  @override
  String get forwardServerStatus => 'Forward Status';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get initializing => 'Initializing';

  @override
  String get connecting => 'Connecting';

  @override
  String get forwardMode => 'Forward Mode';

  @override
  String get deviceId => 'Device ID';

  @override
  String get forwardServerNotConnected => 'Not connected to the forward server';

  @override
  String get cleanData => 'Clean Data';

  @override
  String get syncSettingsAutoCopyScreenShotTitle => 'Auto-copy Screenshots';

  @override
  String get syncSettingsAutoCopyScreenShotDesc =>
      'Background copy may be delayed on some systems.';

  @override
  String get showMoreItemsInRow => 'More per Row';

  @override
  String get showMoreItemsInRowDesc =>
      'Use available width to fit more history & device items per row.';

  @override
  String get filter => 'Filter';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get defaultClipboardServerNotificationCfgErrorTitle => 'Error';

  @override
  String get defaultClipboardServerNotificationCfgErrorTextPrefix => 'Warning';

  @override
  String get defaultClipboardServerNotificationCfgRunningTitle =>
      'Service is runningShizuku mode is active';

  @override
  String get defaultClipboardServerNotificationCfgRootRunningText =>
      'Root mode is activeError';

  @override
  String get startSendFileToast =>
      'File transfer started. Check the send progress.';

  @override
  String get folder => 'Folder';

  @override
  String get removeFromPendingList => 'Remove from pending list';

  @override
  String get onlineDevices => 'Online devices';

  @override
  String get noOnlineDevices => 'No online devices';

  @override
  String get pendingFiles => 'Pending files';

  @override
  String get clearPendingFiles => 'Clear pending list';

  @override
  String pendingFileLen(String len) {
    return '$len files total';
  }

  @override
  String get addFilesFromSystem => 'Add Files';

  @override
  String get viewPendingFiles => 'View Pending Files';

  @override
  String get sendFiles => 'Send Files';

  @override
  String get unWriteablePathTips =>
      'The selected location is not writable. Choose another one.';

  @override
  String get clipboardListeningWay => 'Clipboard Detection Mode';

  @override
  String get clipboardListeningWayTips => 'Info';

  @override
  String get clipboardListeningWithSystemHiddenApi => 'Hidden API';

  @override
  String get clipboardListeningWithSystemLogs => 'System Logs';

  @override
  String get clipboardListeningWayTipsDetail =>
      'Two detection modes are available, but your device may not support both. The default uses system logs, which may not work on some devices.\n\nFor example, system log detection does not work on OriginOS. Choose the mode that fits your device.';

  @override
  String clipboardListeningWayToggleConfirmContent(String way) {
    return 'Switch detection mode?\n\nNew mode: $way';
  }

  @override
  String get closeOnSameHotKeyTitle => 'Hotkey Toggles Popup';

  @override
  String get closeOnSameHotKeyDesc =>
      'Use the popup hotkey to both open and close it.';

  @override
  String get saveToAlbum => 'Save to album';

  @override
  String get openWithOtherApplications => 'Open with Other Apps';

  @override
  String get enableAutoSyncOnScreenOpenedTitle => 'Discover Devices on Wake';

  @override
  String get enableAutoSyncOnScreenOpenedDesc =>
      'Scan for devices when the screen turns on. If screen-off auto-disconnect is on, network switches while off may not reconnect.';

  @override
  String get deviceDiscoveryStatusViaPaired => 'Connecting paired devices';

  @override
  String get export2Excel => 'Export to Excel';

  @override
  String get export2ExcelFileName => 'HistoryRecordsExport.xlsx';

  @override
  String get historyOutputTips =>
      'Export using the current filters?\nFile sync records will not be exported.';

  @override
  String get exporting => 'Exporting...';

  @override
  String get modifyContent => 'Modify Content';

  @override
  String get confirmModifyContent => 'Confirm the update content?';

  @override
  String get modifyContentConfirmExitAndNoSave => 'Don\'t save';

  @override
  String get unsavedTips => 'You have unsaved changes. Leave this page?';

  @override
  String get done => 'Done';

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading';

  @override
  String devDisconnectNotifyContent(String devName) {
    return 'Device $devName disconnected';
  }

  @override
  String devConnectedNotifyContent(String devName) {
    return 'Device $devName connected';
  }

  @override
  String get clipboardSettingsGroupName => 'Clipboard';

  @override
  String get clipboardSettingsTakeOverWinVTitle => 'Take Over Win+V';

  @override
  String get clipboardSettingsTakeOverWinVDesc =>
      'Use Win+V to open the history popup.';

  @override
  String get clipboardSettingsTakeOverWinVDialogContent =>
      'Taking over Win+V changes the current user\'s system hotkey setting and restarts Explorer so it takes effect immediately. Continue?';

  @override
  String get clipboardSettingsRestoreWinVOnExitTitle => 'Restore on App Exit';

  @override
  String get clipboardSettingsRestoreWinVOnExitDesc =>
      'Automatically restore Win+V when the app exits or is uninstalled.';

  @override
  String get clipboardSettingsSourceRecordTitle => 'Record Clipboard Source';

  @override
  String get clipboardSettingsSourceRecordAndroidDesc =>
      'Requires Accessibility to help identify the source.';

  @override
  String get permissionSettingsAccessibilityTitle => 'Accessibility';

  @override
  String get permissionSettingsAccessibilityDesc =>
      'Enable this to help detect clipboard sources.';

  @override
  String get noAccessibilityPermTips =>
      'Accessibility is off, so manual copy sources cannot be detected. Grant Accessibility access now?';

  @override
  String appIconLoadError(String appName) {
    return 'Failed to load app icon ($appName)';
  }

  @override
  String get clipboardSettingsSourceRecordTitleTooltip => 'Info';

  @override
  String get clipboardSettingsSourceRecordDialogContent =>
      'Source detection has two cases: foreground copies and background copies from other apps. Foreground copies rely on Accessibility. Background copies can be identified through dumpsys, with a delay of a few hundred milliseconds.\n\nSource detection is not always exact. It mainly depends on Accessibility and may occasionally tag the wrong app.';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysTitle =>
      'Background Source via dumpsys';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysTitleTooltip => 'Info';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysDialogContent =>
      'Background copies may be misidentified. Use dumpsys to check which app wrote to the clipboard and correct the source.';

  @override
  String get clipboardSettingsSourceRecordViaDumpsysAndroidDesc =>
      'Requires Root or Shizuku and adds a delay of a few hundred milliseconds.';

  @override
  String get source => 'Source';

  @override
  String get clearSourceConfirmText => 'Clear the source info for this record?';

  @override
  String get clearSuccess => 'Cleared successfully';

  @override
  String get clearFailed => 'Failed to clear';

  @override
  String get selectApplication => 'Select App';

  @override
  String get preferenceSettingsDevDisconnNotification =>
      'Notify when a device disconnects';

  @override
  String get preferenceSettingsDevConnNotification =>
      'Notify when a device connects';

  @override
  String get preferenceSettingsNotifyOnReceivedFile =>
      'Notify after receiving files';

  @override
  String get preferenceSettingsNotifyOnReceivedFileDesc =>
      'Click notification to open file';

  @override
  String get notification => 'Notification';

  @override
  String get aboutPageDatabaseVersionItemName => 'Database Version';

  @override
  String get newVersionAvailable => 'New version available';

  @override
  String get showMainWindow => 'Show Main Window';

  @override
  String get exitApp => 'Exit';

  @override
  String exitAppViaHotKey(String appName) {
    return 'Exiting $appName via hotkey';
  }

  @override
  String get clearHotKeyConfirm =>
      'Are you sure you want to clear this shortcut key?';

  @override
  String get pleaseEnterHotKey => 'Press a hotkey';

  @override
  String get userApp => 'User';

  @override
  String get systemApp => 'System';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get openingFile => 'Opening File';

  @override
  String get syncData => 'Sync Data';

  @override
  String get syncSettingsAutoSyncMissingDataTitle => 'Auto-sync Missing Data';

  @override
  String get syncSettingsAutoSyncMissingDataDesc =>
      'After a device reconnects, sync data missed while it was offline.';

  @override
  String get syncingData => 'Syncing data';

  @override
  String get content => 'Content';

  @override
  String get title => 'Title';

  @override
  String get preferenceSettingsShowMobileNotificationTitle =>
      'Mobile Device Notifications';

  @override
  String get preferenceSettingsShowMobileNotificationDesc =>
      'Show connected mobile notifications here. Enable source-device history first.';

  @override
  String get permissionSettingsNotificationRecordTitle =>
      'Notification History Access';

  @override
  String get permissionSettingsNotificationRecordDesc =>
      'Records notification history. On some devices it may keep the app from fully stopping; revoke it before stopping the app.';

  @override
  String get noNotificationRecordPermTips =>
      'Notification History access is missing, so notification history cannot be recorded.';

  @override
  String get recordNotification => 'Record Notification History';

  @override
  String get logSettingsAutoUploadCrashLogTitle => 'Auto-upload Crash Logs';

  @override
  String get logSettingsAutoUploadCrashLogDesc =>
      'Upload crash logs after an app crash to help developers analyze issues.';

  @override
  String get logSettingsAutoUploadCrashLogTips =>
      'Uses ACRA to upload only the data needed for analysis, including the crash stack trace. Logs may be uploaded the next time the app starts.';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get backupSettingDesc =>
      'Export a backup file for restoring the database later.';

  @override
  String get restoreSettingDesc => 'Restore data from a backup file.';

  @override
  String get startUp => 'Start';

  @override
  String get userCancelled => 'User cancelled';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get exportFailedAndViewLogs => 'Export failed, see logs for details';

  @override
  String get exportSuccess => 'Export succeeded';

  @override
  String get importing => 'Importing';

  @override
  String get importFailed => 'Import failed';

  @override
  String get importSuccess => 'Import succeeded';

  @override
  String get restoreRestartPrompt =>
      'Please restart the app manually to load the latest data and configuration';

  @override
  String get loading => 'Loading';

  @override
  String get segmenting => 'Segmenting';

  @override
  String get auto => 'Auto';

  @override
  String get doubleClick2OpenPath => 'Double-click to open path';

  @override
  String get editDb => 'Edit Database';

  @override
  String get enterSQLHere => 'Enter SQL here...';

  @override
  String get optionalTables => 'Optional table names:';

  @override
  String get execSQL => 'Execute SQL';

  @override
  String get execSQLNoLimitTips =>
      'This appears to be a SELECT statement without LIMIT clause. Large result sets may cause performance issues. Continue anyway?';

  @override
  String get toggleSQLLimitCheck => 'Toggle query LIMIT detection';

  @override
  String get result => 'Result';

  @override
  String get execFailed => 'Execution failed';

  @override
  String get notificationServerStatus => 'Notification Status';

  @override
  String get notificationServerTips =>
      'When storage is used as the forward method, devices cannot automatically tell when data needs to be synced.\nA notification service is used to notify devices about changes.\nYou can use either a self-hosted service or a public service.\nNotification messages do not contain sensitive data.';

  @override
  String get forwardSettingsWebDAVTitle => 'WebDAV Settings';

  @override
  String get forwardSettingsS3Title => 'S3 Settings';

  @override
  String get configureWebDAVServer => 'Configure WebDAV';

  @override
  String get webdavServerUrlRequired => 'Please enter WebDAV server URL';

  @override
  String get webdavUrlMustStartWithHttp =>
      'URL must start with http:// or https://';

  @override
  String get usernameRequired => 'Please enter username';

  @override
  String get passwordRequired => 'Please enter password';

  @override
  String get baseDirectoryRequired => 'Please select base directory';

  @override
  String get baseDirectoryMustStartWithSlash =>
      'Base directory must start with /';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get storagePath => 'Storage Path';

  @override
  String get storagePathHint => 'Select Storage Path';

  @override
  String get pleaseInputCorrectURL => 'Please enter the correct URL';

  @override
  String get nameRequired => 'Please enter config name';

  @override
  String get configName => 'Config Name';

  @override
  String get noConfig => 'None';

  @override
  String get s3EndpointRequired => 'S3 endpoint is required';

  @override
  String get accessKeyRequired => 'Access Key is required';

  @override
  String get secretKeyRequired => 'Secret Key is required';

  @override
  String get bucketNameRequired => 'Bucket name is required';

  @override
  String get configureS3Storage => 'Configure S3 Storage';

  @override
  String get endpoint => 'Endpoint';

  @override
  String get s3AccessKey => 'Access Key';

  @override
  String get s3SecretKey => 'Secret Key';

  @override
  String get bucketName => 'Bucket Name';

  @override
  String get region => 'Region';

  @override
  String get optional => 'Optional';

  @override
  String get objectStorageType => 'Storage Type';

  @override
  String get standardS3Protocol => 'Standard S3 protocol';

  @override
  String get aliyunOss => 'Alibaba Cloud OSS';

  @override
  String get pleaseInputCorrectDomain => 'Please enter a valid domain';

  @override
  String get notificationServerConfigure => 'Notification Server Settings';

  @override
  String get notificationServerAddress => 'Notification Server Address';

  @override
  String get regionRequired => 'Region is required';

  @override
  String get pleaseInputCorrectWsURL =>
      'Please enter the correct address (ws:// or wss://)';

  @override
  String get selectStoragePath => 'Select Storage Path';

  @override
  String get readonly => 'Read-only';

  @override
  String get version => 'Version';

  @override
  String get changeForwardWayConfirm =>
      'Switch forward method? Current forward connections will be disconnected.';

  @override
  String get s3 => 'S3';

  @override
  String get none => 'None';

  @override
  String get forwardServer => 'Forward Server';

  @override
  String get forwardSettingsForwardEnableRequiredWebDAVText =>
      'Configure WebDAV first';

  @override
  String get forwardSettingsForwardEnableRequiredS3Text => 'Configure S3 first';

  @override
  String get createFolder => 'Create Folder';

  @override
  String get invalidFolderName =>
      'Invalid name, cannot contain special characters and must be less than 255 characters';

  @override
  String get createFailed => 'Creation failed';

  @override
  String get notAllowRootPath => 'Root path is not allowed';

  @override
  String get rootPathCannotEnableForward =>
      'The storage path cannot be the root path';

  @override
  String get s3TypeTips =>
      'Any object storage service compatible with the standard S3 protocol can be configured directly.\n\nTencent Cloud and Qiniu Cloud have been tested and work well.\n\nAlibaba Cloud OSS requires separate settings.';

  @override
  String get forwardWay => 'Forward Method';

  @override
  String get backupTypeConfig => 'Config';

  @override
  String get backupTypeAppInfo => 'Clipboard Source';

  @override
  String get backupTypeDevice => 'Devices';

  @override
  String get backupTypeHistory => 'History';

  @override
  String get backupTypeHistoryTag => 'Tags';

  @override
  String get backupTypeOperationRecord => 'Operation Record';

  @override
  String get backupTypeOperationSync => 'Sync Record';

  @override
  String get selectBackupItems => 'Select Backup Items';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get enterSoftware => 'Enter App';

  @override
  String get segmentWords => 'Segment Words';

  @override
  String get downloadFromGithub => 'Download from Github';

  @override
  String notFoundJiebaFiles(String dirPath) {
    return 'Jieba files not found.\nDownload them and copy them to:\n$dirPath\nOnly dict.txt and prob_emit.txt are required.';
  }

  @override
  String get installJiebaDictFile => 'Install';

  @override
  String get downloadFailed => 'Download failed!';

  @override
  String get jiebaFileInstallSuccess => 'Jieba files installed';

  @override
  String get encryptKey => 'Encryption Key';

  @override
  String get encryptKeyErrorTip =>
      'Length must be at least 8 characters and cannot contain whitespace';

  @override
  String get confirmClearEncryptKey => 'Confirm clear encryption key?';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get dhKeySettingName => 'Encrypt Key Exchange';

  @override
  String get dhKeySettingDesc =>
      'All devices need this and the same password, or connection fails.';

  @override
  String get dhKeySettingTips =>
      'Encrypts the Diffie-Hellman key exchange parameters used during device connection.\nWhen enabled, all connected devices must enable this and use the same password, or they cannot connect.\n\nLeaving it off is also acceptable.';

  @override
  String get syncOutDateSettingTitle => 'Sync Date Range';

  @override
  String get syncOutDateSettingDesc =>
      'Sync only data in the selected time range.';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get generateTodayAndroidLog => 'Generate Android native logs (today)';

  @override
  String get noDiscoveryIfsSettingTitle => 'Exclude Discovery NICs';

  @override
  String get noDiscoveryIfsSettingDesc =>
      'Skip selected NICs during subnet scans.';

  @override
  String get onlyManualDiscoverySubNetSettingTitle => 'Manual Subnet Scan Only';

  @override
  String get onlyManualDiscoverySubNetSettingDesc =>
      'No auto scans after network changes or screen wake; scan from Devices.';

  @override
  String get stopListeningOnScreenClosedSettingTitle =>
      'Stop on Screen-off (Experimental)';

  @override
  String get stopListeningOnScreenClosedSettingDesc =>
      'Stops clipboard listening 1 minute after screen-off to save battery on some devices.';

  @override
  String get keepConnectionsOnNetworkSwitchTitle => 'Keep Existing Connections';

  @override
  String get keepConnectionsOnNetworkSwitchDesc =>
      'Reconnect only on Wi-Fi/mobile or online/offline changes; otherwise keep existing connections.';

  @override
  String get notNow => 'Not now';

  @override
  String get faq => 'FAQ';

  @override
  String get sendBroadcastOnAddData => 'Send broadcast when adding data';

  @override
  String get sendBroadcastOnAddDataDesc =>
      'Send a system broadcast on clipboard changes or synced data so apps like Tasker can process it.';

  @override
  String get explain => 'Explanation';

  @override
  String sendBroadcastOnAddDataTips(String kOnHistoryChangedBroadcastAction) {
    return 'The broadcast Action is: $kOnHistoryChangedBroadcastAction\n\nThe current broadcast contains the following variables:\n1.type: Content type, valid values are: text, image, sms, file, notification\n2. content: Content, when it is an image or file, it is a local path; when it is a notification, it is JSON\n3. from_dev_id: Source device ID\n4. from_dev_name: Source device name';
  }

  @override
  String get recopyOnScreenUnlockedTitle => 'Retry Latest Copy After Unlock';

  @override
  String get recopyOnScreenUnlockedTitleDesc =>
      'On some systems, auto-copy fails while locked. Retry copying the latest synced data after unlock.';

  @override
  String get rulesManagement => 'Rules';

  @override
  String get excludePrivateFormat => 'Skip Excluded Formats';

  @override
  String get excludePrivateFormatDesc =>
      'Do not record clipboard entries marked for exclusion.';

  @override
  String get excludePrivateFormatTips =>
      'When clipboard content contains the ExcludeClipboardContentFromMonitorProcessing marker, it will not be recorded.';

  @override
  String get moreActions => 'More Actions';

  @override
  String get retainDays => 'Keep Last';

  @override
  String get onlyLocal => 'Only Local';

  @override
  String get enablePIP => 'Enable Picture-in-Picture';

  @override
  String get enablePIPTip =>
      'Open received videos in Picture-in-Picture and improve clipboard detection.';

  @override
  String get permissionSettingsClipboardTitle => 'Clipboard Permission';

  @override
  String get permissionSettingsClipboardDesc =>
      'Some Android systems allow clipboard access only while in use. Grant this to enable background clipboard access.';

  @override
  String get local => 'Local';

  @override
  String get directConnect => 'Direct';

  @override
  String get selectBackupSource => 'Backup Location';

  @override
  String get notConfigured => 'Not Configured';

  @override
  String get storagePathTips =>
      'Backup files and transfer files are stored in different folders within the same directory.\nIf the storage path is set to /ClipShare\nthen the temporary transfer files are stored in /ClipShare/history, \nthe backup files are stored in /ClipShare/backup.';

  @override
  String get uploading => 'Uploading';

  @override
  String get useTrayFlashingForConnectionTitle =>
      'Flash Tray on Connect/Disconnect';

  @override
  String get useTrayFlashingForConnectionDesc =>
      'Flash the tray instead of showing system notifications.';

  @override
  String trayDevAliveTooltip(
    String first,
    String pairedCnt,
    String unpairedCnt,
  ) {
    return '$first\nConnected to $pairedCnt paired devices\nConnected to $unpairedCnt unpaired devices';
  }

  @override
  String get displayExtractedContent => 'Display Extracted Content';

  @override
  String get displayOriginContent => 'Display Original Content';

  @override
  String get codePromptParamsContentIsSyncDisabled => 'Whether to prevent sync';

  @override
  String get codePromptParamsContentTags => 'Tags';

  @override
  String get codePromptParamsContentExtracted => 'Extracted content';

  @override
  String get codePromptParamsContentDetail => 'Content';

  @override
  String get codePromptParamsContentNotificationTitle =>
      'Notification title (notification type only)';

  @override
  String get codePromptParamsContentSource =>
      'Source, such as a local path or app package name';

  @override
  String get codePromptParamsContentType => 'Content type';

  @override
  String get codePromptNotificationType => 'Notification';

  @override
  String get codePromptImageType => 'Image';

  @override
  String get codePromptTextType => 'Text';

  @override
  String get codePromptSmsType => 'SMS';

  @override
  String get codePromptJsonDecode => 'JSON decode';

  @override
  String get codePromptLogError => 'Log an error-level message';

  @override
  String get codePromptLogWarn => 'Log a warning-level message';

  @override
  String get codePromptLogDebug => 'Log a debug-level message';

  @override
  String get codePromptLogInfo => 'Log an info-level message';

  @override
  String get codePromptContentType => 'Content type';

  @override
  String get codePromptJson => 'JSON Module';

  @override
  String get codePromptLog => 'Log Module';

  @override
  String get codePromptPrint => 'Print output, equivalent to logger.debug()';

  @override
  String get codePromptMath => 'Math Module';

  @override
  String get codePromptString => 'String Module';

  @override
  String get codePromptTable => 'Table manipulation Module';

  @override
  String get codePromptUtf8 => 'UTF-8 Module';

  @override
  String get codePromptOs => 'OS Module (safe subset)';

  @override
  String get codePromptType => 'Get value type';

  @override
  String get codePromptToString => 'Convert to string';

  @override
  String get codePromptToNumber => 'Convert to number';

  @override
  String get codePromptPairs => 'Iterate table (key-value pairs)';

  @override
  String get codePromptIpairs => 'Iterate array (numeric index)';

  @override
  String get codePromptNext => 'Get next element';

  @override
  String get codePromptPcall => 'Protected function call';

  @override
  String get codePromptXpcall => 'Protected call with error handler';

  @override
  String get codePromptSelect => 'Access variadic arguments';

  @override
  String get codePromptAssert => 'Assertion check';

  @override
  String get codePromptError => 'Raise an error';

  @override
  String get codePromptMathAbs => 'Absolute value';

  @override
  String get codePromptMathAcos => 'Arc cosine';

  @override
  String get codePromptMathAsin => 'Arc sine';

  @override
  String get codePromptMathAtan => 'Arc tangent';

  @override
  String get codePromptMathCeil => 'Round up';

  @override
  String get codePromptMathCos => 'Cosine';

  @override
  String get codePromptMathDeg => 'Radians to degrees';

  @override
  String get codePromptMathExp => 'Exponential';

  @override
  String get codePromptMathFloor => 'Round down';

  @override
  String get codePromptMathFmod => 'Remainder';

  @override
  String get codePromptMathHuge => 'Largest float value';

  @override
  String get codePromptMathLog => 'Logarithm';

  @override
  String get codePromptMathMax => 'Maximum value';

  @override
  String get codePromptMathMaxInteger => 'Maximum integer';

  @override
  String get codePromptMathMin => 'Minimum value';

  @override
  String get codePromptMathMinInteger => 'Minimum integer';

  @override
  String get codePromptMathModf => 'Integer and fractional parts';

  @override
  String get codePromptMathPi => 'Pi constant';

  @override
  String get codePromptMathRad => 'Degrees to radians';

  @override
  String get codePromptMathRandom => 'Random number';

  @override
  String get codePromptMathRandomSeed => 'Set random seed';

  @override
  String get codePromptMathSin => 'Sine';

  @override
  String get codePromptMathSqrt => 'Square root';

  @override
  String get codePromptMathTan => 'Tangent';

  @override
  String get codePromptMathToInteger => 'Convert to integer';

  @override
  String get codePromptMathType => 'Number subtype';

  @override
  String get codePromptMathUlt => 'Unsigned integer comparison';

  @override
  String get codePromptStringByte => 'Character code';

  @override
  String get codePromptStringChar => 'Create string from character codes';

  @override
  String get codePromptStringDump => 'Dump function bytecode';

  @override
  String get codePromptStringLen => 'String length';

  @override
  String get codePromptStringSub => 'Substring';

  @override
  String get codePromptStringFind => 'Find substring';

  @override
  String get codePromptStringFormat => 'Format string';

  @override
  String get codePromptStringGMatch => 'Iterate matches';

  @override
  String get codePromptStringGSub => 'Replace matches';

  @override
  String get codePromptStringLower => 'Convert to lowercase';

  @override
  String get codePromptStringMatch => 'Match pattern';

  @override
  String get codePromptStringPack => 'Pack values into binary string';

  @override
  String get codePromptStringPackSize => 'Packed size';

  @override
  String get codePromptStringRep => 'Repeat string';

  @override
  String get codePromptStringReverse => 'Reverse string';

  @override
  String get codePromptStringUnpack => 'Unpack binary string';

  @override
  String get codePromptStringUpper => 'Convert to uppercase';

  @override
  String get codePromptTableInsert => 'Insert element';

  @override
  String get codePromptTableMove => 'Move elements between tables';

  @override
  String get codePromptTableRemove => 'Remove element';

  @override
  String get codePromptTableSort => 'Sort table';

  @override
  String get codePromptTableConcat => 'Concatenate strings';

  @override
  String get codePromptUtf8Len => 'UTF-8 string length';

  @override
  String get codePromptUtf8Char => 'Create UTF-8 character';

  @override
  String get codePromptUtf8CharPattern => 'UTF-8 character pattern';

  @override
  String get codePromptUtf8Codes => 'Iterate UTF-8 code points';

  @override
  String get codePromptUtf8CodePoint => 'Get UTF-8 code points';

  @override
  String get codePromptUtf8Offset => 'Get UTF-8 offset';

  @override
  String get codePromptOsClock => 'CPU time used';

  @override
  String get codePromptOsDate => 'Get current date';

  @override
  String get codePromptOsTime => 'Get timestamp';

  @override
  String get codePromptOsDiffTime => 'Time difference';

  @override
  String get codePromptLuaVersion => 'Current Lua version';

  @override
  String get codePromptTablePack => 'Pack arguments into a table';

  @override
  String get codePromptTableUnpack =>
      'Unpack a table into multiple return values';

  @override
  String get codePromptScriptParams =>
      'Script parameters, including content, type, source, and other information';

  @override
  String get codePromptIfSnippet => 'If condition snippet';

  @override
  String get codePromptElseSnippet => 'Else snippet';

  @override
  String get codePromptElseIfSnippet => 'Else-if snippet';

  @override
  String get codePromptWhileSnippet => 'While loop snippet';

  @override
  String get codePromptRepeatSnippet => 'Repeat-until loop snippet';

  @override
  String get codePromptForSnippet => 'For numeric loop snippet';

  @override
  String get codePromptForStepSnippet => 'For loop with step snippet';

  @override
  String get codePromptIPairsSnippet => 'Ipairs iteration snippet';

  @override
  String get codePromptPairsSnippet => 'Pairs table iteration snippet';

  @override
  String get codePromptFunctionSnippet => 'Function definition snippet';

  @override
  String get codePromptLocalFunctionSnippet =>
      'Local function definition snippet';

  @override
  String get codePromptPlatformAndroid => 'Android platform';

  @override
  String get codePromptNotify => 'Notification';

  @override
  String get codePromptAndroidToast => 'Android toast message';

  @override
  String get codePromptAndroidSendHistoryChangedBroadcast =>
      'Android send history changed broadcast';

  @override
  String get codePromptPlatform => 'Platform';

  @override
  String get codePromptPlatformIsAndroid => 'Check if platform is Android';

  @override
  String get codePromptPlatformIsIOS => 'Check if platform is iOS';

  @override
  String get codePromptPlatformIsWindows => 'Check if platform is Windows';

  @override
  String get codePromptPlatformIsMacOS => 'Check if platform is macOS';

  @override
  String get codePromptPlatformIsLinux => 'Check if platform is Linux';

  @override
  String get codePromptApp => 'App';

  @override
  String get codePromptAppVersionName => 'App version name';

  @override
  String get codePromptAppVersionNumber => 'App version number';

  @override
  String get codePromptDeviceSelf => 'Current device';

  @override
  String get codePromptDeviceSelfName => 'Current device name';

  @override
  String get codePromptDeviceSelfId => 'Current device ID';

  @override
  String get codePromptCrypto => 'Cryptography';

  @override
  String get codePromptCryptoMD5 => 'Compute MD5 hash';

  @override
  String get codePromptCryptoSHA256 => 'Compute SHA-256 hash';

  @override
  String get codePromptCryptoSHA1 => 'Compute SHA-1 hash';

  @override
  String get codePromptBase64 => 'Base64';

  @override
  String get codePromptBase64Encode => 'Encode Base64';

  @override
  String get codePromptBase64Decode => 'Decode Base64';

  @override
  String get codePromptRegex => 'Regular expression';

  @override
  String get codePromptRegexMatch =>
      'Match all full matches and return as a list';

  @override
  String get codePromptRegexMatchGroups =>
      'Match all capture groups and return as a nested list';

  @override
  String get codePromptHttp => 'HTTP request Module';

  @override
  String get codePromptTask => 'Async task Module';

  @override
  String get codePromptAsync =>
      'Wraps a function as async, allowing await inside';

  @override
  String get codePromptAwait =>
      'Waits for an awaiter to complete and returns its result; can only be used inside an async function';

  @override
  String get codePromptHttpGet => 'GET request method (async)';

  @override
  String get codePromptHttpPost => 'POST request method (async)';

  @override
  String get codePromptPut => 'PUT request method (async)';

  @override
  String get codePromptDelete => 'DELETE request method (async)';

  @override
  String get codePromptTaskCreate => 'Creates a task (awaiter)';

  @override
  String get rulesPageUnsavedChangesConfirm =>
      'There are unsaved changes. Continue anyway?';

  @override
  String get ruleItemContentRequired => 'Rule content cannot be empty';

  @override
  String get ruleItemExtractRuleRequired => 'Extraction rule cannot be empty';

  @override
  String get ruleItemScriptContentRequired => 'Script content cannot be empty';

  @override
  String get ruleItemUnsupportedOperation => 'Unsupported operation';

  @override
  String get ruleTriggerOnCopyText => 'After copy';

  @override
  String get ruleTriggerOnNotificationText => 'New notification';

  @override
  String get ruleTriggerOnSmsText => 'New SMS';

  @override
  String get ruleDetailRegexHint => 'Enter a regular expression';

  @override
  String get ruleDetailNameLabel => 'Rule name: ';

  @override
  String get ruleDetailNameHint => 'Enter rule name';

  @override
  String get ruleDetailPlatformLabel => 'Platform';

  @override
  String get ruleDetailTriggerLabel => 'Trigger';

  @override
  String get ruleDetailRuleLabel => 'Rule';

  @override
  String get ruleDetailRegexTab => 'Regex';

  @override
  String get ruleDetailScriptTab => 'Script';

  @override
  String get ruleDetailAutoWrapTooltip => 'Auto wrap';

  @override
  String get ruleDetailFullScreenTooltip => 'Enter full-screen editor';

  @override
  String get ruleDetailModeDefault => 'Default';

  @override
  String get ruleDetailModeBlacklist => 'Blacklist';

  @override
  String get ruleDetailModeWhitelist => 'Whitelist';

  @override
  String get ruleDetailRegexLabel => 'Match rule:';

  @override
  String get ruleDetailRegexTip =>
      'Regex is case-insensitive by default; the extraction rule only extracts the first match.';

  @override
  String get ruleDetailExtractContent => 'Extract rule:';

  @override
  String get ruleDetailModeLabel => 'Rule mode';

  @override
  String get ruleDetailActionLabel => 'Actions';

  @override
  String get ruleDetailAddTagLabel => 'Add tags:';

  @override
  String get ruleDetailAddTagDialogTitle => 'Add tag';

  @override
  String get ruleDetailFinalRule => 'Stop following rules';

  @override
  String get ruleDetailRunTestTooltip => 'Run test';

  @override
  String get ruleDetailPageTitle => 'Rule details';

  @override
  String get ruleModulesDetailSyntaxError =>
      'Contains syntax errors. Please fix them';

  @override
  String get scriptModulesDetailDisplayNameRequired =>
      'Display name cannot be empty';

  @override
  String get scriptModulesDetailModuleNameRequired =>
      'Module name cannot be empty';

  @override
  String get scriptModulesDetailModuleNameDuplicated =>
      'Module name must be unique';

  @override
  String get scriptModuleDetailContentRequired => 'Content cannot be empty';

  @override
  String get scriptModuleDetailDisplayNameLabel => 'Display name: ';

  @override
  String get scriptModuleDetailDisplayNameHint => 'Enter display name';

  @override
  String get scriptModuleDetailModuleNameLabel => 'Module name';

  @override
  String get scriptModuleDetailModuleNameImmutableTooltip =>
      'Module name cannot be changed after saving';

  @override
  String get scriptModuleDetailModuleNameHint => 'Module name';

  @override
  String get scriptModuleDetailNameInvalid =>
      'Only letters, numbers, and underscores are allowed, and it cannot start with a number';

  @override
  String get scriptModuleDetailPageTitle => 'Module details';

  @override
  String get ruleListDeleteModuleConfirm =>
      'Delete it? If other scripts use it, they will stop working.';

  @override
  String get ruleListExitSelectionModeTooltip => 'Exit selection mode';

  @override
  String get ruleCardDragDisabledTooltip =>
      'Save data or clear the search input before reordering';

  @override
  String get ruleCardDragTooltip => 'Reorder';

  @override
  String get scriptEditTestViewPanelTooltip => 'Run panel';

  @override
  String get scriptEditTestViewRunTooltip => 'Run';

  @override
  String get scriptEditTestViewExitFullScreenTooltip =>
      'Exit full-screen editor';

  @override
  String get scriptTestPanelParamsTab => 'Params';

  @override
  String get scriptTestPanelCompileInfoTab => 'Compile info';

  @override
  String get scriptTestPanelOutputTab => 'Output';

  @override
  String get scriptTestPanelRunResultTab => 'Run result';

  @override
  String get scriptTestPanelCollapseTooltip => 'Collapse';

  @override
  String get ruleCompileCodeNotFound => 'Code not found';

  @override
  String get ruleCompileCodeEmpty => 'Code is empty';

  @override
  String get ruleCompileSuccess => 'Compile succeeded.';

  @override
  String ruleCompileFailedPrefix(String message) {
    return 'Compile failed:\n$message';
  }

  @override
  String get scriptModuleCompileReturnTableRequired =>
      'The Module return value must be a table.';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get extracted => 'Extracted';

  @override
  String get tags => 'Tags';

  @override
  String get flags => 'Flags';

  @override
  String get finalRule => 'Final';

  @override
  String get dropped => 'Dropped';

  @override
  String get syncDisabled => 'Prevent Sync';

  @override
  String get rules => 'Rules';

  @override
  String get scriptModules => 'Script Modules';

  @override
  String get modules => 'Modules';

  @override
  String get unknown => 'Unknown';

  @override
  String get triggerOnCopy => 'Trigger: Copy';

  @override
  String get triggerOnNotification => 'Trigger: Notification';

  @override
  String get triggerOnSms => 'Trigger: SMS';

  @override
  String get modulesTip =>
      'You can import pure Lua libraries, or encapsulate some frequently used methods for scripts to call. The return value must be a table.\nThe sandbox environment is the same as in the script.';

  @override
  String get recordMaxLength => 'Max content length';

  @override
  String get recordMaxLengthTips =>
      'Can save 2 MB+ content, but search may fail.';

  @override
  String get length => 'Length';

  @override
  String get mustGreaterThanZero => 'Must >= 0';

  @override
  String get settingsSectionLanguageSubtitle => 'Display language';

  @override
  String get settingsSectionPreferenceSubtitle => 'UI & interaction';

  @override
  String get settingsSectionNotificationSubtitle => 'Alerts & reminders';

  @override
  String get settingsSectionClipboardSubtitle => 'Capture & history';

  @override
  String get settingsSectionPermissionSubtitle => 'App permissions';

  @override
  String get settingsSectionFloatWindowSubtitle =>
      'Floating window and keep-alive';

  @override
  String get settingsSectionDiscoverySubtitle => 'Devices & connections';

  @override
  String get settingsSectionForwardSubtitle => 'Relay & storage';

  @override
  String get settingsSectionSecuritySubtitle => 'Auth & encryption';

  @override
  String get settingsSectionHotKeySubtitle => 'Popup & window shortcuts';

  @override
  String get settingsSectionSyncSubtitle => 'History saving';

  @override
  String get settingsSectionCleanDataSubtitle => 'Clean history and records';

  @override
  String get settingsSectionRulesSubtitle => 'Rules & scripts';

  @override
  String get settingsSectionBackupSubtitle => 'Import & export';

  @override
  String get settingsSectionAboutLogSubtitle => 'App info';

  @override
  String get settingsSectionStatisticsSubtitle => 'Usage insights';

  @override
  String get settingsOverviewPermissionNormal => 'All granted';

  @override
  String settingsOverviewPermissionIssueCount(String count) {
    return '$count pending';
  }

  @override
  String get settingsOverviewForwardClosed => 'Off';

  @override
  String get storageWsVersionIncompatibleTitle => 'Incompatible version';

  @override
  String storageWsVersionIncompatibleDialogContent(
    String version,
    String minVersion,
  ) {
    return 'Current notification service version: $version. Minimum required: $minVersion. Please upgrade it before using storage sync.';
  }

  @override
  String get noTargetWindow =>
      'Paste failed: no target window was found that can receive the paste action.';

  @override
  String get openTargetProcessFailed =>
      'Paste failed: the target process could not be opened for inspection.';

  @override
  String get inspectTargetFailed =>
      'Paste failed: the target process integrity level could not be read. Elevated privileges may be required.';

  @override
  String get inspectSelfFailed =>
      'Paste failed: the current process integrity level could not be read.';

  @override
  String get targetIntegrityHigher =>
      'Paste failed: elevated privileges may be required.';
}
