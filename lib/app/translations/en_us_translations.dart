import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/translations/app_translations.dart';
import 'package:clipshare/app/utils/constants.dart';

class EnUSTranslation extends AbstractTranslations {
  @override
  String translate(TranslationKey key) {
    switch (key) {
      case TranslationKey.unitWord:
        return "words";
      case TranslationKey.dialogCancelText:
        return "Cancel";
      case TranslationKey.dialogAuthorizationButtonText:
        return "Grant Access";
      case TranslationKey.floatPermRequestDialogTitle:
        return "Request Floating Window Permission";
      case TranslationKey.floatPermRequestDialogContent:
        return 'Because Android 10+ blocks background clipboard access, the app reads clipboard changes indirectly through system logs and floating window access.'
            '\n\nTap OK to open the floating window permission page.';
      case TranslationKey.requiredPermDialogTitle:
        return "Required Permission Missing";
      case TranslationKey.floatPermMissingDialogContent:
        return 'Grant floating window access, or the clipboard cannot be read in the background.';
      case TranslationKey.shizukuPermRequestDialogTitle:
        return "Shizuku Permission Request";
      case TranslationKey.shizukuPermRequestDialogContent:
        return "Due to restrictions on Android 10 and above, Shizuku is required to read the clipboard in the background. Otherwise, the app can only passively receive clipboard data and cannot automatically sync.";
      case TranslationKey.dontShowAgain:
        return "Don't Show Again";
      case TranslationKey.dontShowAgainConfirm:
        return "Confirm Don't Show Again?";
      case TranslationKey.notificationPermRequestDialogTitle:
        return "Request Notification Permission";
      case TranslationKey.notificationPermRequestDialogContent:
        return "Used to send system notifications.";
      case TranslationKey.batteryOptimization:
        return "Battery Optimization";
      case TranslationKey.batteryOptimizationPermRequestDialogContent:
        return 'Turn off battery optimization to improve background keep-alive.\n'
            'If tapping [Grant Access] does not respond, open the setting manually in your phone settings.';
      case TranslationKey.selectWorkMode:
        return "Select Work Mode";
      case TranslationKey.completed:
        return "Completed";
      case TranslationKey.completedGuideDesc:
        return "Setup complete.";
      case TranslationKey.floatPermGuideTitle:
        return "Floating Window Permission";
      case TranslationKey.floatPermGuideDesc:
        return "On newer Android versions, ${Constants.appName} needs floating window access to read the clipboard in the background. After enabling it, you can open clipboard history from the screen edge and drag to select items.";
      case TranslationKey.notificationPermGuideTitle:
        return "Notification Permission";
      case TranslationKey.notificationPermGuideDesc:
        return "Enable notifications to start the foreground service.";
      case TranslationKey.storagePermGuideTitle:
        return "Storage Permission";
      case TranslationKey.storagePermGuideDesc:
        return "Storage permission is required to sync images and files, otherwise files cannot be saved.";
      case TranslationKey.batteryOptimizationPermGuideDesc:
        return "To improve background keep-alive, exclude the app from battery optimization.\n"
            "Also lock it in recent tasks and allow auto-start in your phone manager.\n"
            "If tapping [Grant Access] does not respond, open the setting manually in your phone settings.";
      case TranslationKey.aboutPageInstructionsItemName:
        return "Guide";
      case TranslationKey.aboutPageJoinQQGroupItemName:
        return "Join QQ Group";
      case TranslationKey.aboutPageWebsiteItemName:
        return "Official Website";
      case TranslationKey.aboutPageLogsItemName:
        return "Changelog";
      case TranslationKey.aboutPageVersionItemName:
        return "App Version";
      case TranslationKey.authenticationPageTitle:
        return "Authentication";
      case TranslationKey.authenticationPageBackendTimeoutVerificationTitle:
        return "Timeout Verification";
      case TranslationKey.authenticationPageUsePassword:
        return "Use Password";
      case TranslationKey.authenticationPageStartVerification:
        return "Start Verification";
      case TranslationKey.authenticationPageRequireAuthentication:
        return "Authentication Required";
      case TranslationKey.deviceAdditionFailedDialogText:
        return "Device Addition Failed";
      case TranslationKey.rename:
        return "Rename";
      case TranslationKey.devicePageDisconnect:
        return "Disconnect";
      case TranslationKey.devicePageReconnect:
        return "Reconnect";
      case TranslationKey.devicePageUnpairedDialogContent:
        return "Do you want to unpair?";
      case TranslationKey.devicePageUnpairedButtonText:
        return "Unpair";
      case TranslationKey.devicePagePairingDialogTitle:
        return "Enter Pairing Code";
      case TranslationKey.devicePagePairingTimeoutText:
        return "Pairing timed out!";
      case TranslationKey.devicePagePairingErrorText:
        return "Wrong pairing code!";
      case TranslationKey.devicePagePairingDialogConfirmText:
        return "Pair";
      case TranslationKey.devicePageMyDevicesText:
        return "My Devices (@length)";
      case TranslationKey.devicePageForwardServerText:
        return "Forward Connection";
      case TranslationKey.devicePageDiscoverDevicesText:
        return "Discover Devices (@length)";
      case TranslationKey.devicePageRediscoverTooltip:
        return "Rediscover";
      case TranslationKey.devicePageManuallyTooltip:
        return "Add Device Manually";
      case TranslationKey.devicePageStopDiscoveringTooltip:
        return "Stop Discovering";
      case TranslationKey.sms:
        return "SMS";
      case TranslationKey.homeAppBarSyncingProgressText:
        return "Syncing";
      case TranslationKey.search:
        return "Search";
      case TranslationKey.logPageAppBarTitle:
        return "Log Records";
      case TranslationKey.all:
        return "All";
      case TranslationKey.text:
        return "Text";
      case TranslationKey.image:
        return "Image";
      case TranslationKey.file:
        return "File";
      case TranslationKey.moreFilter:
        return "More Filters";
      case TranslationKey.startDate:
        return "Start Date";
      case TranslationKey.endDate:
        return "End Date";
      case TranslationKey.filterByDate:
        return "Filter by Date";
      case TranslationKey.filterByContentType:
        return "Filter by Type";
      case TranslationKey.filterBySource:
        return "Filter by Source";
      case TranslationKey.saveTopData:
        return "Keep Pinned Data";
      case TranslationKey.removeLocalFiles:
        return "Remove local files";
      case TranslationKey.saveFilterConfig:
        return "Save Filter Preset";
      case TranslationKey.saveAutoCleanConfig:
        return "Save Auto-clean Settings";
      case TranslationKey.noDataFromFilter:
        return "No data matched the filter";
      case TranslationKey.filterCleaningConfirmation:
        return "@cnt items found. This cannot be undone.\nContinue?";
      case TranslationKey.syncRecordsCleaningConfirmation:
        return "Clearing device sync records will resync data after the next connection.";
      case TranslationKey.onlyNotSync:
        return "Only Unsynced";
      case TranslationKey.syncRecordsCleanBtn:
        return "Clear Selected Sync Records";
      case TranslationKey.optionRecordsCleaningConfirmation:
        return "Clearing device operation records will stop unsynced data from auto-syncing again.";
      case TranslationKey.optionRecordsCleanBtn:
        return "Clear Selected Operation Records";
      case TranslationKey.autoCleanFrequency:
        return "Frequency";
      case TranslationKey.execTime:
        return "Run time";
      case TranslationKey.nextExecTime:
        return "Next cleaning time: ";
      case TranslationKey.errorCronTips:
        return "Enter a valid Unix cron expression";
      case TranslationKey.filterTips:
        return "If a filter is left empty, all options are included.\nThe date range is not saved in filter presets.";
      case TranslationKey.autoCleanConfigTitle:
        return "Auto-clean";
      case TranslationKey.daily:
        return "Daily";
      case TranslationKey.weekly:
        return "Weekly";
      case TranslationKey.selectWeekDay:
        return "Select Weekday";
      case TranslationKey.deleteItemsUnit:
        return "items";
      case TranslationKey.pleaseSelectDevices:
        return "Select devices first";
      case TranslationKey.saveSuccess:
        return "Saved!";
      case TranslationKey.pleaseSaveFilterConfig:
        return "Save a filter preset first";
      case TranslationKey.saveFailed:
        return "Save failed";
      case TranslationKey.updateSuccess:
        return "Updated!";
      case TranslationKey.updateFailed:
        return "Update failed!";
      case TranslationKey.confirm:
        return "Confirm";
      case TranslationKey.toToday:
        return "Go to Today";
      case TranslationKey.clear:
        return "Clear";
      case TranslationKey.settingsSearchHint:
        return "Search settings...";
      case TranslationKey.filterByDevice:
        return "Filter by Device";
      case TranslationKey.filterByTag:
        return "Filter by Tag";
      case TranslationKey.envStatusLoadingText:
        return "Loading environment status...";
      case TranslationKey.shizukuModeStatusTitle:
        return "Shizuku Mode";
      case TranslationKey.shizukuModeRunningDesc:
        return "Service is running, API @version";
      case TranslationKey.rootModeStatusTitle:
        return "Root Mode";
      case TranslationKey.rootModeRunningDesc:
        return "Authorized. Service is running.";
      case TranslationKey.serverNotRunningDesc:
        return "Service is not running. Some features are unavailable.";
      case TranslationKey.envPermissionIgnored:
        return "Permission Ignored";
      case TranslationKey.envPermissionIgnoredDesc:
        return "Some features may be unavailable";
      case TranslationKey.noSpecialPermissionRequired:
        return "No Special Permission Required";
      case TranslationKey.switchWorkingMode:
        return "Switch Working Mode";
      case TranslationKey.commonSettingsRunAtStartup:
        return "Run at Startup";
      case TranslationKey.commonSettingsRunMinimize:
        return "Start Minimized";
      case TranslationKey.floatWindow:
        return "Floating Window";
      case TranslationKey.commonSettingsShowHistoriesFloatWindow:
        return "Show History Panel";
      case TranslationKey.commonSettingsShowHistoriesFloatWindowTips:
        return "Double-tap or drag the handle left to open the history panel.";
      case TranslationKey.historyFloatTitle:
        return "Clipboard History";
      case TranslationKey.historyFloatCountTemplate:
        return "{count} records";
      case TranslationKey.historyFloatImageUnavailable:
        return "Image unavailable";
      case TranslationKey.commonSettingsHistoriesFloatWindowHandleWidthValue:
        return "Handle Width: @width";
      case TranslationKey.commonSettingsHistoriesFloatWindowHandleColor:
        return "Handle Color";
      case TranslationKey.commonSettingsHistoriesFloatWindowHandleColorTips:
        return "Pick a floating window color. Changes sync in real time.";
      case TranslationKey.commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle:
        return "Apply alpha to whole handle";
      case TranslationKey.commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips:
        return "When enabled, the handle border, grip, and inner overlay follow the selected color alpha together.";
      case TranslationKey.commonSettingsEnhanceBackgroundKeepAliveTitle:
        return "Boost Background Keep-alive";
      case TranslationKey.commonSettingsEnhanceBackgroundKeepAliveDesc:
        return "Show a 1 px floating window to improve background keep-alive on some devices.";
      case TranslationKey.commonSettingsLockHistoriesFloatWindowPosition:
        return "Lock Floating Window Position";
      case TranslationKey.preferenceSettingsRememberWindowSize:
        return "Remember Last Window Size";
      case TranslationKey.preferenceSettingsWindowSizeRecordValue:
        return "Recorded Value";
      case TranslationKey.preferenceSettingsWindowSizeDefaultValue:
        return "Default Value";
      case TranslationKey.commonSettingsTheme:
        return "Theme";
      case TranslationKey.language:
        return "Language";
      case TranslationKey.selectLanguage:
        return "Select Language";
      case TranslationKey.themeAuto:
        return "Follow System";
      case TranslationKey.themeLight:
        return "Light Mode";
      case TranslationKey.themeDark:
        return "Dark Mode";
      case TranslationKey.permissionSettingsGroupName:
        return "Permissions";
      case TranslationKey.permissionSettingsNotificationTitle:
        return "Notification Permission";
      case TranslationKey.permissionSettingsNotificationDesc:
        return "Required to start the foreground service.";
      case TranslationKey.permissionSettingsFloatTitle:
        return "Floating Window Permission";
      case TranslationKey.permissionSettingsFloatDesc:
        return "Used on newer Android versions to read the clipboard through a floating window.";
      case TranslationKey.permissionSettingsBatteryOptimiseTitle:
        return "Battery Optimization";
      case TranslationKey.permissionSettingsBatteryOptimiseDesc:
        return "Exclude the app from battery optimization to reduce background kills.";
      case TranslationKey.permissionSettingsSmsTitle:
        return "SMS Access";
      case TranslationKey.permissionSettingsSmsDesc:
        return "SMS sync is enabled. Please grant SMS access.";
      case TranslationKey.discoveringSettingsGroupName:
        return "Discovery";
      case TranslationKey.discoveringSettingsLocalDeviceName:
        return "Device Name";
      case TranslationKey.discoveringSettingsDeviceNameCopyTip:
        return "Device ID copied";
      case TranslationKey.copyDeviceId:
        return "Copy Device ID";
      case TranslationKey.modifyDeviceName:
        return "Rename Device";
      case TranslationKey.deviceName:
        return "Device Name";
      case TranslationKey.modifyDeviceNameCompletedTooltip:
        return "Restart to apply changes";
      case TranslationKey.port:
        return "Port";
      case TranslationKey.discoveringSettingsPortDesc:
        return "Default: ${Constants.port}. Changing it may break auto-discovery.";
      case TranslationKey.modifyPort:
        return "Change Port";
      case TranslationKey.modifyPortErrorText:
        return "Port number range 0-65535";
      case TranslationKey.discoveringSettingsModifyPortCompletedTooltip:
        return "Restart to apply changes";
      case TranslationKey.allowDiscovering:
        return "Discoverable";
      case TranslationKey.discoveringSettingsAllowDiscoveringDesc:
        return "Can be automatically discovered by other devices";
      case TranslationKey.discoveringSettingsOnlyForwardDiscoveringTitle:
        return "Forward-only Discovery (Debug)";
      case TranslationKey.discoveringSettingsOnlyForwardDiscoveringDesc:
        return "Visible only in development builds";
      case TranslationKey.discoveringSettingsHeartbeatIntervalTitle:
        return "Heartbeat Interval";
      case TranslationKey.discoveringSettingsHeartbeatIntervalDesc:
        return "Device online check. Default: 30s; 0 disables it.";
      case TranslationKey.discoveringSettingsHeartbeatIntervalTooltip:
        return "Info";
      case TranslationKey.enable:
        return "Enable";
      case TranslationKey.dontDetect:
        return "Don't Detect";
      case TranslationKey.discoveringSettingsHeartbeatIntervalDialogContent:
        return "When a device switches networks, its offline status cannot be detected automatically.\n"
            "Enable heartbeat checks to verify device availability at intervals.";
      case TranslationKey.discoveringSettingsModifyHeartbeatDialogTitle:
        return "Heartbeat Interval";
      case TranslationKey.discoveringSettingsModifyHeartbeatDialogInputLabel:
        return "Heartbeat Interval";
      case TranslationKey
          .discoveringSettingsModifyHeartbeatDialogInputErrorText:
        return "Seconds. 0 disables it.";
      case TranslationKey.forwardSettingsGroupName:
        return "Forward";
      case TranslationKey.forwardSettingsForwardTitle:
        return "Use Forward Service";
      case TranslationKey.forwardSettingsForwardDownloadTooltip:
        return "Download Forward Service";
      case TranslationKey.forwardSettingsForwardDesc:
        return "Sync over the internet through a forward server.";
      case TranslationKey.forwardSettingsForwardEnableRequiredText:
        return "Set the forward server address first.";
      case TranslationKey.forwardSettingsForwardAddressTitle:
        return "Forward Server Address";
      case TranslationKey.forwardSettingsForwardAddressDesc:
        return "Use a trusted server or host your own.";
      case TranslationKey.configure:
        return "Configure";
      case TranslationKey.change:
        return "Change";
      case TranslationKey.securitySettingsGroupName:
        return "Security";
      case TranslationKey.securitySettingsEnableSecurityTitle:
        return "Enable Authentication";
      case TranslationKey.securitySettingsEnableSecurityDesc:
        return "Use password or biometrics.";
      case TranslationKey
          .securitySettingsEnableSecurityAppPwdRequiredDialogContent:
        return "Please create an app password first";
      case TranslationKey
          .securitySettingsEnableSecurityAppPwdRequiredDialogOkText:
        return "Create Now";
      case TranslationKey.securitySettingsEnableSecurityAppPwdModifyTitle:
        return "Change Password";
      case TranslationKey.createAppPwd:
        return "Create App Password";
      case TranslationKey.changeAppPwd:
        return "Change App Password";
      case TranslationKey.create:
        return 'Create';
      case TranslationKey.securitySettingsReverificationTitle:
        return "Password Recheck";
      case TranslationKey.securitySettingsReverificationDesc:
        return "Ask for the password again after the app stays in the background for a while.";
      case TranslationKey.securitySettingsReverificationValue:
        return "@value minutes";
      case TranslationKey.hotKeySettingsGroupName:
        return "Hotkeys";
      case TranslationKey.hotKeySettingsHistoryTitle:
        return "History Popup";
      case TranslationKey.hotKeySettingsHistoryDesc:
        return "Open the history popup from anywhere on screen";
      case TranslationKey.hotKeySettingsHistoryTakeOverWinVTooltip:
        return "Win+V is taken over";
      case TranslationKey.hotKeySettingsCombinationInvalidText:
        return "A hotkey must include one modifier and one non-modifier key.";
      case TranslationKey.hotKeySettingsSaveKeysDialogText:
        return "Save hotkey \"@keys\"?";
      case TranslationKey.hotKeySettingsSaveKeysFailedText:
        return "Failed to save: @err";
      case TranslationKey.sendFile:
        return "Send File";
      case TranslationKey.hotKeySettingsFileDesc:
        return "Send selected files to other devices; desktop selection is unsupported";
      case TranslationKey.syncSettingsGroupName:
        return "Sync";
      case TranslationKey.syncSettingsSmsPermissionRequired:
        return "Grant SMS access first.";
      case TranslationKey.syncSettingsStoreImg2PicturesTitle:
        return "Save Images to Pictures";
      case TranslationKey.syncSettingsStoreImg2PicturesDesc:
        return "Saved to Pictures/${Constants.appName}";
      case TranslationKey.syncSettingsStoreImg2PicturesNoPermText:
        return "Storage access required.";
      case TranslationKey.syncSettingsStoreImg2PicturesCancelPerm:
        return "Permission request canceled.";
      case TranslationKey.syncSettingsStoreImagePathTitle:
        return "Image Storage Path";
      case TranslationKey.syncSettingsStoreFilePathTitle:
        return "File Storage Path";
      case TranslationKey.selection:
        return "Select";
      case TranslationKey.syncSettingsAutoCopyImgTitle:
        return "Copy Images Automatically";
      case TranslationKey.syncSettingsAutoCopyImgDesc:
        return "When enabled, images copied on other devices are also copied locally.";
      case TranslationKey.logSettingsGroupName:
        return "Logs";
      case TranslationKey.logSettingsEnableTitle:
        return "Enable Logging";
      case TranslationKey.logSettingsEnableDesc:
        return "Uses extra storage. Current logs: @size";
      case TranslationKey.openFolder:
        return "Open Folder";
      case TranslationKey.openFilePos:
        return "Open File Location";
      case TranslationKey.tips:
        return "Tips";
      case TranslationKey.logSettingsDeleteLogFilesDialogContent:
        return "Delete log files?";
      case TranslationKey.statisticsSettingsGroupName:
        return "Statistics";
      case TranslationKey.about:
        return "About";
      case TranslationKey.errorDialogTitle:
        return "Error";
      case TranslationKey.selfDeviceName:
        return "Self";
      case TranslationKey.save:
        return "Save";
      case TranslationKey.saved:
        return "Saved";
      case TranslationKey.saveFileNotSupportDialogText:
        return "Unsupported Type";
      case TranslationKey.pieDataStatisticsLocalItemLabel:
        return "Local";
      case TranslationKey.pieDataStatisticsSyncItemLabel:
        return "Sync";
      case TranslationKey.statisticsPageAppBarText:
        return "Statistics";
      case TranslationKey.statisticsPageFilterRangeText:
        return "Range";
      case TranslationKey.refresh:
        return "Refresh";
      case TranslationKey.statisticsPageHistoryTypeCntTitle:
        return 'Record Count by Type';
      case TranslationKey.statisticsPageSyncRatePie:
        return 'Sync Ratio';
      case TranslationKey.statisticsPageHistoryCntForDevice:
        return 'Record Count by Device';
      case TranslationKey.statisticsPageHistoryTagCnt:
        return 'Record Count by Tag';
      case TranslationKey.syncingFilePageHistoryTabText:
        return "History";
      case TranslationKey.syncingFilePageReceiveTabText:
        return "Receiving";
      case TranslationKey.syncingFilePageSendTabText:
        return "Sending";
      case TranslationKey.dragFileToSend:
        return "Drag files here to send";
      case TranslationKey.deleting:
        return "Deleting...";
      case TranslationKey.deletingSuccess:
        return "Deleted Successfully";
      case TranslationKey.partialDeletionFailed:
        return "Partial Deletion Failed";
      case TranslationKey.deletionFailed:
        return "Delete Failed";
      case TranslationKey.deselect:
        return "Deselect";
      case TranslationKey.delete:
        return "Delete";
      case TranslationKey.deleteWithFiles:
        return "Delete with Files";
      case TranslationKey.syncingFilePageDeleteSelectedDialogContent:
        return "Delete @length selected items?\nFiles from sent records will be kept.";
      case TranslationKey.onlyDeleteRecordsText:
        return "Records Only";
      case TranslationKey.failedToReadUpdateLog:
        return "Failed to Read Update Log!";
      case TranslationKey.skipGuide:
        return "Skip";
      case TranslationKey.previousGuide:
        return "Previous";
      case TranslationKey.nextGuide:
        return "Next";
      case TranslationKey.finishGuide:
        return "Finish";
      case TranslationKey.previewPageNoSuchFile:
        return "Image does not exist or has been deleted";
      case TranslationKey.copyPathSuccess:
        return "Path copied";
      case TranslationKey.tagEditPageAppBarTitle:
        return "Edit Tag";
      case TranslationKey.tagEditPageSearchOrCreateTag:
        return "Search or Create Tag";
      case TranslationKey.tagEditPageCrateTagItem:
        return 'Create "@tag" Tag';
      case TranslationKey.updateLogPageAppBarTitle:
        return 'Changelog';
      case TranslationKey.failedToReadFile:
        return "Failed to Read File";
      case TranslationKey.welcome:
        return "Welcome to ${Constants.appName}";
      case TranslationKey.welcomeContent:
        return "Before you start, we need a few permissions and some basic setup.";
      case TranslationKey.startNow:
        return "Start Now";
      case TranslationKey.name_:
        return "Name";
      case TranslationKey.ruleContent:
        return "Rule";
      case TranslationKey.deleteSuccess:
        return "Deleted Successfully";
      case TranslationKey.revoke:
        return "Revoke";
      case TranslationKey.importRules:
        return "Import Rules";
      case TranslationKey.importRulesSuccess:
        return "Imported @length rules";
      case TranslationKey.importFromNet:
        return "Import from Network";
      case TranslationKey.importFromLocal:
        return "Import from Local";
      case TranslationKey.urlFormatErrorText:
        return "Please enter a valid URL";
      case TranslationKey.fetch:
        return "Fetch";
      case TranslationKey.fetchingData:
        return "Fetching Data...";
      case TranslationKey.failedToLoad:
        return "Failed to Load";
      case TranslationKey.noSuchFile:
        return "The selected file path does not exist!";
      case TranslationKey.addRule:
        return "Add Rule";
      case TranslationKey.importRule:
        return "Import Rule";
      case TranslationKey.import:
        return "Import";
      case TranslationKey.add:
        return "Add";
      case TranslationKey.modify:
        return "Modify";
      case TranslationKey.output:
        return "Export";
      case TranslationKey.outputRule:
        return "Export Rule";
      case TranslationKey.outputSuccess:
        return "Exported Successfully!";
      case TranslationKey.outputFailed:
        return "Export Failed";
      case TranslationKey.exitSelectionMode:
        return "Exit Selection Mode";
      case TranslationKey.selectAll:
        return "Select All";
      case TranslationKey.cancelSelectAll:
        return "Cancel Select All";
      case TranslationKey.multipleChoiceOperationAppBarTitle:
        return "Bulk Actions";
      case TranslationKey.forwardServerNotAllowedSendFile:
        return "This forward server does not allow file sync.";
      case TranslationKey.sendFailed:
        return "Send Failed";
      case TranslationKey.forwardServerUnknownResult:
        return "Unknown Result";
      case TranslationKey.forwardServerConnectFailed:
        return "Forward Server Connection Failed";
      case TranslationKey.devicePairingRequestNotificationContent:
        return "New Pairing Request";
      case TranslationKey.devicePairingRequestDialogTitle:
        return "Pairing Request";
      case TranslationKey.pairingCodeDialogContent:
        return "Pairing request from @devName\nCode:";
      case TranslationKey.cancelCurrentPairing:
        return 'Cancel This Pairing';
      case TranslationKey.deviceDiscoveryStatusViaBroadcast:
        return "Broadcast Discovery";
      case TranslationKey.deviceDiscoveryStatusViaScan:
        return "Network Scan";
      case TranslationKey.deviceDiscoveryStatusViaForward:
        return "Forward Discovery";
      case TranslationKey.newVersionDialogTitle:
        return "New Version";
      case TranslationKey.newVersionDialogSkipText:
        return "Skip";
      case TranslationKey.newVersionDialogOkText:
        return "Download";
      case TranslationKey.defaultLinkTagName:
        return "Link";
      case TranslationKey.unknownHistoryContentType:
        return "Unknown";
      case TranslationKey.allHistoryContentType:
        return "All";
      case TranslationKey.textHistoryContentType:
        return "Text";
      case TranslationKey.imageHistoryContentType:
        return "Image";
      case TranslationKey.richTextHistoryContentType:
        return "Rich Text";
      case TranslationKey.smsHistoryContentType:
        return "SMS";
      case TranslationKey.fileHistoryContentType:
        return "File";
      case TranslationKey.dialogConfirmText:
        return "Confirm";
      case TranslationKey.dialogNeutralText:
        return "Neutral";
      case TranslationKey.dialogRestoreDefaultText:
        return "Restore Default";
      case TranslationKey.open:
        return "Open";
      case TranslationKey.openLink:
        return "Open Link";
      case TranslationKey.moment:
        return "Just Now";
      case TranslationKey.minutesAgo:
        return "minutes ago";
      case TranslationKey.hoursAgo:
        return "hours ago";
      case TranslationKey.connectFailed:
        return "Connection Failed";
      case TranslationKey.connectSuccess:
        return "Connection Successful";
      case TranslationKey.connect:
        return "Connect";
      case TranslationKey.addDeviceDialogTitle:
        return 'Add Device';
      case TranslationKey.errorFormatIp:
        return "Please enter a valid IPv4/v6 address";
      case TranslationKey.inputPassword:
        return "Enter Password";
      case TranslationKey.inputAgain:
        return "Enter Again";
      case TranslationKey.inputErrorAndAgain:
        return "Incorrect input. Try again.";
      case TranslationKey.immediately:
        return "Immediately";
      case TranslationKey.minute:
        return 'Minute';
      case TranslationKey.alreadyNewestAppVersion:
        return "Already up to date";
      case TranslationKey.checkUpdate:
        return "Check";
      case TranslationKey.topUp:
        return "Pin to Top";
      case TranslationKey.cancelTopUp:
        return "Unpin from Top";
      case TranslationKey.copyContent:
        return "Copy Content";
      case TranslationKey.copyMergedContent:
        return "Copy Merged Content";
      case TranslationKey.syncRecord:
        return "Sync Record";
      case TranslationKey.resyncRecord:
        return "Sync Again";
      case TranslationKey.openFile:
        return "Open File";
      case TranslationKey.openFileFolder:
        return "Open File Folder";
      case TranslationKey.tagsManagement:
        return "Tags";
      case TranslationKey.copySuccess:
        return "Copied Successfully";
      case TranslationKey.copyFailed:
        return "Copied Failed";
      case TranslationKey.clipboardContent:
        return "Clipboard Details";
      case TranslationKey.deleteRecord:
        return "Delete Record";
      case TranslationKey.multiDeleteAsk:
        return "Delete selected @length items?";
      case TranslationKey.deleteCompleted:
        return "Delete Completed";
      case TranslationKey.shareFile:
        return 'Share File';
      case TranslationKey.deleteTips:
        return "Delete Tips";
      case TranslationKey.clipListDeleteRecordDialogContent:
        return "Delete this record?";
      case TranslationKey.backToTop:
        return "Back to Top";
      case TranslationKey.fold:
        return "Collapse";
      case TranslationKey.unfold:
        return "Expand";
      case TranslationKey.clipboard:
        return "Clipboard";
      case TranslationKey.close:
        return "Close";
      case TranslationKey.tag:
        return "Tag";
      case TranslationKey.pleaseInput:
        return "Please Enter";
      case TranslationKey.forward:
        return "Forward";
      case TranslationKey.notCompatible:
        return "Version Incompatible";
      case TranslationKey.notCompatibleDialogText:
        return "Incompatible with the device's software version, data sync is disabled.\n"
            "Minimum version required is @minName(@minCode})\n"
            "Current software version is @selfName(@selfCode)";
      case TranslationKey.emptyData:
        return "No Data";
      case TranslationKey.shizukuMode:
        return "Shizuku Mode";
      case TranslationKey.shizukuModeDesc:
        return "No Root needed. Requires Shizuku and must be reactivated after a restart.";
      case TranslationKey.shizukuModeBatteryOptimiseTips:
        return "To keep Shizuku authorized, exclude it from battery optimization and allow it to run in the background.";
      case TranslationKey.shizukuRequestFailedDialogText:
        return "Shizuku request failed. Make sure Shizuku is running and try again.";
      case TranslationKey.requestFailed:
        return 'Request Failed';
      case TranslationKey.selectInstallerType:
        return 'Select Installer Type';
      case TranslationKey.openPathAfterDownload:
        return 'Open after download';
      case TranslationKey.updateFromZipTips:
        return 'The portable ZIP also supports auto-updating upon download completion.';
      case TranslationKey.requestSuccess:
        return 'Request Success';
      case TranslationKey.clipboardPermissionRequestFailed:
        return 'Requesting clipboard permission requires Shizuku or Root';
      case TranslationKey.rootMode:
        return "Root Mode";
      case TranslationKey.rootModeDesc:
        return "Runs with Root. No reactivation needed after a restart.";
      case TranslationKey.waitingRequestResult:
        return 'Waiting for Request Result';
      case TranslationKey.applyingSettings:
        return 'Applying settings...';
      case TranslationKey.rootRequestFailedDialogText:
        return "Root access was not found. You can use Shizuku mode instead.";
      case TranslationKey.ignoreMode:
        return "Ignore";
      case TranslationKey.ignoreModeDesc:
        return "Clipboard cannot be monitored in the background, only passive sync is available";
      case TranslationKey.multiChoiceModeSelectedText:
        return "@text items selected";
      case TranslationKey.goAuthorize:
        return "Grant Access";
      case TranslationKey.cannotEmpty:
        return "Cannot be empty";
      case TranslationKey.ruleCannotEmpty:
        return "Rule cannot be empty";
      case TranslationKey.ruleAddDialogLabel:
        return "Rule";
      case TranslationKey.ruleAddDialogHint:
        return "Please enter a regular expression";
      case TranslationKey.validationTesting:
        return "Validation Testing";
      case TranslationKey.validationFailed:
        return "Validation Failed";
      case TranslationKey.verify:
        return "Verify";
      case TranslationKey.stop:
        return "Stop";
      case TranslationKey.failed:
        return "Failed";
      case TranslationKey.pleaseInputKey:
        return "Please Enter Key";
      case TranslationKey.forwardServerUnlimitedDevices:
        return "No restrictions for whitelist devices";
      case TranslationKey.publicForwardServer:
        return "Public Forward Server";
      case TranslationKey.forwardServerSyncFileRateLimit:
        return "File Sync Rate Limit";
      case TranslationKey.forwardServerCannotSyncFile:
        return "This forward server does not support file sync.";
      case TranslationKey.forwardServerNoLimits:
        return "No Restrictions";
      case TranslationKey.noLimits:
        return "No Limit";
      case TranslationKey.deviceUnit:
        return "Device";
      case TranslationKey.day:
        return "Day";
      case TranslationKey.hour:
        return "Hour";
      case TranslationKey.second:
        return "Second";
      case TranslationKey.forwardServerKeyNotStarted:
        return "Not Started";
      case TranslationKey.exhausted:
        return "Exhausted";
      case TranslationKey.forwardServerDeviceConnectionLimit:
        return "Device Connection Limit";
      case TranslationKey.forwardServerLifeSpan:
        return "Validity Period";
      case TranslationKey.forwardServerRemainingTime:
        return "Remaining Time";
      case TranslationKey.forwardServerRateLimit:
        return "Rate Limit";
      case TranslationKey.forwardServerRemark:
        return "Remark";
      case TranslationKey.configureForwardServerDialogTitle:
        return "Configure Forward Server";
      case TranslationKey.domainAndIp:
        return "Domain / IP";
      case TranslationKey.host:
        return "Host";
      case TranslationKey.useKey:
        return "Use Key";
      case TranslationKey.accessKey:
        return "Access Key";
      case TranslationKey.pleaseInputAccessKey:
        return "Please Enter Access Key";
      case TranslationKey.checkConnection:
        return "Test";
      case TranslationKey.pleaseInputValidPort:
        return 'Please Enter a Valid Port';
      case TranslationKey.pleaseInputValidDomainOrIpv4_6:
        return 'Please Enter a Valid Domain or IPv4/v6 Address';
      case TranslationKey.historyRecord:
        return 'Records';
      case TranslationKey.myDevice:
        return 'Devices';
      case TranslationKey.fileTransfer:
        return 'Transfer';
      case TranslationKey.appSettings:
        return 'Settings';
      case TranslationKey.syncFile:
        return 'Sync Files';
      case TranslationKey.preference:
        return "Preference";
      case TranslationKey.preferenceSettingsRecordsDialogLocation:
        return "History Popup Position";
      case TranslationKey.preferenceSettingsRecordsDialogSize:
        return "Records Dialog Size";
      case TranslationKey.preferenceSettingsAutoClosePopupOnBlurTitle:
        return "Automatically close popups when focus is lost";
      case TranslationKey.preferenceSettingsAutoClosePopupOnBlurDesc:
        return "Applies to both the history popup and file transfer popup";
      case TranslationKey.current:
        return "Current";
      case TranslationKey.followMousePos:
        return "Follow Cursor";
      case TranslationKey.rememberLastPos:
        return "Remember last position";
      case TranslationKey.showOnRecentTasks:
        return "Show in Recent Tasks";
      case TranslationKey.showOnRecentTasksDesc:
        return "When off, hide the app from recent tasks.";
      case TranslationKey.showLocalIpAddress:
        return "Show Local IP Address";
      case TranslationKey.localIpAddress:
        return "Local IP Address";
      case TranslationKey.syncAutoCloseSettingTitle:
        return "Screen-off Auto Disconnect";
      case TranslationKey.syncAutoCloseSettingDesc:
        return "Disconnect sync after the screen stays off for 2-10 minutes. Leave this off to keep background connections.";
      case TranslationKey.scan:
        return "Scan QRCode";
      case TranslationKey.noCameraPermission:
        return "Please grant camera permission";
      case TranslationKey.noPhotoPermission:
        return "Please grant photo permission";
      case TranslationKey.noNotificationPermission:
        return "Please grant notification permission";
      case TranslationKey.permissionSettingsIOSPhotosTitle:
        return "Photo Permission";
      case TranslationKey.permissionSettingsIOSPhotosDesc:
        return "Without this permission, images cannot be saved to Photos.";
      case TranslationKey.qrCodeScannerPageTitle:
        return "Scan to Connect";
      case TranslationKey.qrCodeScanError:
        return "This does not look like a ClipShare connection QR code. Please check.";
      case TranslationKey.attemptingToConnect:
        return "Attempting to connect";
      case TranslationKey.forwardServerStatus:
        return "Forward Status";
      case TranslationKey.connected:
        return "Connected";
      case TranslationKey.disconnected:
        return "Disconnected";
      case TranslationKey.initializing:
        return "Initializing";
      case TranslationKey.connecting:
        return "Connecting";
      case TranslationKey.forwardMode:
        return "Forward Mode";
      case TranslationKey.deviceId:
        return "Device ID";
      case TranslationKey.forwardServerNotConnected:
        return "Not connected to the forward server";
      case TranslationKey.cleanData:
        return "Clean Data";
      case TranslationKey.syncSettingsAutoCopyScreenShotTitle:
        return "Auto-copy Screenshots";
      case TranslationKey.syncSettingsAutoCopyScreenShotDesc:
        return "Background copy may be delayed on some systems.";
      case TranslationKey.showMoreItemsInRow:
        return "More per Row";
      case TranslationKey.showMoreItemsInRowDesc:
        return "Use available width to fit more history & device items per row.";
      case TranslationKey.filter:
        return "Filter";
      case TranslationKey.monday:
        return "Monday";
      case TranslationKey.tuesday:
        return "Tuesday";
      case TranslationKey.wednesday:
        return "Wednesday";
      case TranslationKey.thursday:
        return "Thursday";
      case TranslationKey.friday:
        return "Friday";
      case TranslationKey.saturday:
        return "Saturday";
      case TranslationKey.sunday:
        return "Sunday";
      case TranslationKey.defaultClipboardServerNotificationCfgErrorTitle:
        return "Error";
      case TranslationKey.defaultClipboardServerNotificationCfgErrorTextPrefix:
        return "";
      case TranslationKey
          .defaultClipboardServerNotificationCfgStopListeningTitle:
        return "Warning";
      case TranslationKey
          .defaultClipboardServerNotificationCfgStopListeningText:
        return "Clipboard listening stopped";
      case TranslationKey.defaultClipboardServerNotificationCfgRunningTitle:
        return "Service is running";
      case TranslationKey
          .defaultClipboardServerNotificationCfgShizukuRunningText:
        return "Shizuku mode is active";
      case TranslationKey.defaultClipboardServerNotificationCfgRootRunningText:
        return "Root mode is active";
      case TranslationKey
          .defaultClipboardServerNotificationCfgShizukuDisconnectedTitle:
        return "Error";
      case TranslationKey
          .defaultClipboardServerNotificationCfgShizukuDisconnectedText:
        return "Shizuku disconnected. Check its status.";
      case TranslationKey
          .defaultClipboardServerNotificationCfgWaitingRunningTitle:
        return "Waiting for Service";
      case TranslationKey
          .defaultClipboardServerNotificationCfgWaitingRunningText:
        return "Waiting for service to start";
      case TranslationKey.startSendFileToast:
        return "File transfer started. Check the send progress.";
      case TranslationKey.folder:
        return "Folder";
      case TranslationKey.removeFromPendingList:
        return "Remove from pending list";
      case TranslationKey.onlineDevices:
        return "Online devices";
      case TranslationKey.noOnlineDevices:
        return "No online devices";
      case TranslationKey.pendingFiles:
        return "Pending files";
      case TranslationKey.clearPendingFiles:
        return "Clear pending list";
      case TranslationKey.pendingFileLen:
        return "@len files total";
      case TranslationKey.addFilesFromSystem:
        return "Add Files";
      case TranslationKey.viewPendingFiles:
        return "View Pending Files";
      case TranslationKey.sendFiles:
        return "Send Files";
      case TranslationKey.unWriteablePathTips:
        return "The selected location is not writable. Choose another one.";
      case TranslationKey.clipboardListeningWay:
        return "Clipboard Detection Mode";
      case TranslationKey.clipboardListeningWayTips:
        return "Info";
      case TranslationKey.clipboardListeningWithSystemHiddenApi:
        return "Hidden API";
      case TranslationKey.clipboardListeningWithSystemLogs:
        return "System Logs";
      case TranslationKey.clipboardListeningWayTipsDetail:
        return "Two detection modes are available, but your device may not support both. The default uses system logs, which may not work on some devices.\n\nFor example, system log detection does not work on OriginOS. Choose the mode that fits your device.";
      case TranslationKey.clipboardListeningWayToggleConfirmContent:
        return "Switch detection mode?\n\nNew mode: @way";
      case TranslationKey.closeOnSameHotKeyTitle:
        return "Hotkey Toggles Popup";
      case TranslationKey.closeOnSameHotKeyDesc:
        return "Use the popup hotkey to both open and close it.";
      case TranslationKey.saveToAlbum:
        return "Save to album";
      case TranslationKey.openWithOtherApplications:
        return "Open with Other Apps";
      case TranslationKey.enableAutoSyncOnScreenOpenedTitle:
        return "Discover Devices on Wake";
      case TranslationKey.enableAutoSyncOnScreenOpenedDesc:
        return "Scan for devices when the screen turns on. If screen-off auto-disconnect is on, network switches while off may not reconnect.";
      case TranslationKey.deviceDiscoveryStatusViaPaired:
        return "Connecting paired devices";
      case TranslationKey.export2Excel:
        return "Export to Excel";
      case TranslationKey.export2ExcelFileName:
        return "HistoryRecordsExport.xlsx";
      case TranslationKey.historyOutputTips:
        return "Export using the current filters?\nFile sync records will not be exported.";
      case TranslationKey.exporting:
        return "Exporting...";
      case TranslationKey.modifyContent:
        return "Modify Content";
      case TranslationKey.confirmModifyContent:
        return "Confirm the update content?";
      case TranslationKey.modifyContentConfirmExitAndNoSave:
        return "Don't save";
      case TranslationKey.unsavedTips:
        return "You have unsaved changes. Leave this page?";
      case TranslationKey.done:
        return "Done";
      case TranslationKey.download:
        return "Download";
      case TranslationKey.downloading:
        return "Downloading";
      case TranslationKey.devDisconnectNotifyContent:
        return "Device @devName disconnected";
      case TranslationKey.devConnectedNotifyContent:
        return "Device @devName connected";
      case TranslationKey.clipboardSettingsGroupName:
        return "Clipboard";
      case TranslationKey.clipboardSettingsTakeOverWinVTitle:
        return "Take Over Win+V";
      case TranslationKey.clipboardSettingsTakeOverWinVDesc:
        return "Use Win+V to open the history popup.";
      case TranslationKey.clipboardSettingsTakeOverWinVDialogContent:
        return "Taking over Win+V changes the current user's system hotkey setting and restarts Explorer so it takes effect immediately. Continue?";
      case TranslationKey.clipboardSettingsRestoreWinVOnExitTitle:
        return "Restore on App Exit";
      case TranslationKey.clipboardSettingsRestoreWinVOnExitDesc:
        return "Automatically restore Win+V when the app exits or is uninstalled.";
      case TranslationKey.clipboardSettingsSourceRecordTitle:
        return "Record Clipboard Source";
      case TranslationKey.clipboardSettingsSourceRecordAndroidDesc:
        return "Requires Accessibility to help identify the source.";
      case TranslationKey.permissionSettingsAccessibilityTitle:
        return "Accessibility";
      case TranslationKey.permissionSettingsAccessibilityDesc:
        return "Enable this to help detect clipboard sources.";
      case TranslationKey.noAccessibilityPermTips:
        return "Accessibility is off, so manual copy sources cannot be detected. Grant Accessibility access now?";
      case TranslationKey.appIconLoadError:
        return "Failed to load app icon (@appName)";
      case TranslationKey.clipboardSettingsSourceRecordTitleTooltip:
        return "Info";
      case TranslationKey.clipboardSettingsSourceRecordDialogContent:
        return "Source detection has two cases: foreground copies and background copies from other apps. Foreground copies rely on Accessibility. Background copies can be identified through dumpsys, with a delay of a few hundred milliseconds.\n\nSource detection is not always exact. It mainly depends on Accessibility and may occasionally tag the wrong app.";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitle:
        return "Background Source via dumpsys";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltip:
        return "Info";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysDialogContent:
        return "Background copies may be misidentified. Use dumpsys to check which app wrote to the clipboard and correct the source.";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysAndroidDesc:
        return "Requires Root or Shizuku and adds a delay of a few hundred milliseconds.";
      case TranslationKey.source:
        return "Source";
      case TranslationKey.clearSourceConfirmText:
        return "Clear the source info for this record?";
      case TranslationKey.clearSuccess:
        return "Cleared successfully";
      case TranslationKey.clearFailed:
        return "Failed to clear";
      case TranslationKey.selectApplication:
        return "Select App";
      case TranslationKey.preferenceSettingsDevDisconnNotification:
        return "Notify when a device disconnects";
      case TranslationKey.preferenceSettingsDevConnNotification:
        return "Notify when a device connects";
      case TranslationKey.preferenceSettingsNotifyOnReceivedFile:
        return "Notify after receiving files";
      case TranslationKey.preferenceSettingsNotifyOnReceivedFileDesc:
        return "Click notification to open file";
      case TranslationKey.notification:
        return "Notification";
      case TranslationKey.aboutPageDatabaseVersionItemName:
        return "Database Version";
      case TranslationKey.newVersionAvailable:
        return "New version available";
      case TranslationKey.showMainWindow:
        return "Show Main Window";
      case TranslationKey.exitApp:
        return "Exit";
      case TranslationKey.exitAppViaHotKey:
        return "Exiting ${Constants.appName} via hotkey";
      case TranslationKey.clearHotKeyConfirm:
        return "Are you sure you want to clear this shortcut key?";
      case TranslationKey.pleaseEnterHotKey:
        return "Press a hotkey";
      case TranslationKey.userApp:
        return 'User';
      case TranslationKey.systemApp:
        return 'System';
      case TranslationKey.fileNotFound:
        return 'File not found';
      case TranslationKey.openingFile:
        return 'Opening File';
      case TranslationKey.syncData:
        return "Sync Data";
      case TranslationKey.syncSettingsAutoSyncMissingDataTitle:
        return "Auto-sync Missing Data";
      case TranslationKey.syncSettingsAutoSyncMissingDataDesc:
        return "After a device reconnects, sync data missed while it was offline.";
      case TranslationKey.syncingData:
        return "Syncing data";
      case TranslationKey.content:
        return "Content";
      case TranslationKey.title:
        return "Title";
      case TranslationKey.preferenceSettingsShowMobileNotificationTitle:
        return "Mobile Device Notifications";
      case TranslationKey.preferenceSettingsShowMobileNotificationDesc:
        return "Show connected mobile notifications here. Enable source-device history first.";
      case TranslationKey.permissionSettingsNotificationRecordTitle:
        return "Notification History Access";
      case TranslationKey.permissionSettingsNotificationRecordDesc:
        return "Records notification history. On some devices it may keep the app from fully stopping; revoke it before stopping the app.";
      case TranslationKey.noNotificationRecordPermTips:
        return "Notification History access is missing, so notification history cannot be recorded.";
      case TranslationKey.recordNotification:
        return "Record Notification History";
      case TranslationKey.logSettingsAutoUploadCrashLogTitle:
        return "Auto-upload Crash Logs";
      case TranslationKey.logSettingsAutoUploadCrashLogDesc:
        return "Upload crash logs after an app crash to help developers analyze issues.";
      case TranslationKey.logSettingsAutoUploadCrashLogTips:
        return "Uses ACRA to upload only the data needed for analysis, including the crash stack trace. Logs may be uploaded the next time the app starts.";
      case TranslationKey.backupRestore:
        return "Backup & Restore";
      case TranslationKey.backup:
        return "Backup";
      case TranslationKey.restore:
        return "Restore";
      case TranslationKey.backupSettingDesc:
        return "Export a backup file for restoring the database later.";
      case TranslationKey.restoreSettingDesc:
        return "Restore data from a backup file.";
      case TranslationKey.startUp:
        return "Start";
      case TranslationKey.userCancelled:
        return "User cancelled";
      case TranslationKey.cancelled:
        return "Cancelled";
      case TranslationKey.exportFailedAndViewLogs:
        return "Export failed, see logs for details";
      case TranslationKey.exportSuccess:
        return "Export succeeded";
      case TranslationKey.importing:
        return "Importing";
      case TranslationKey.importFailed:
        return "Import failed";
      case TranslationKey.importSuccess:
        return "Import succeeded";
      case TranslationKey.restoreRestartPrompt:
        return "Please restart the app manually to load the latest data and configuration";
      case TranslationKey.loading:
        return "Loading";
      case TranslationKey.segmenting:
        return "Segmenting";
      case TranslationKey.auto:
        return "Auto";
      case TranslationKey.doubleClick2OpenPath:
        return 'Double-click to open path';
      case TranslationKey.editDb:
        return 'Edit Database';
      case TranslationKey.enterSQLHere:
        return 'Enter SQL here...';
      case TranslationKey.optionalTables:
        return 'Optional table names:';
      case TranslationKey.execSQL:
        return 'Execute SQL';
      case TranslationKey.execSQLNoLimitTips:
        return 'This appears to be a SELECT statement without LIMIT clause. Large result sets may cause performance issues. Continue anyway?';
      case TranslationKey.toggleSQLLimitCheck:
        return 'Toggle query LIMIT detection';
      case TranslationKey.result:
        return 'Result';
      case TranslationKey.execFailed:
        return 'Execution failed';
      case TranslationKey.notificationServerStatus:
        return 'Notification Status';
      case TranslationKey.notificationServerTips:
        return "When storage is used as the forward method, devices cannot automatically tell when data needs to be synced.\n"
            "A notification service is used to notify devices about changes.\n"
            "You can use either a self-hosted service or a public service.\n"
            "Notification messages do not contain sensitive data.";

      case TranslationKey.forwardSettingsWebDAVTitle:
        return "WebDAV Settings";
      case TranslationKey.forwardSettingsS3Title:
        return "S3 Settings";

      case TranslationKey.configureWebDAVServer:
        return "Configure WebDAV";
      case TranslationKey.webdavServerUrlRequired:
        return "Please enter WebDAV server URL";
      case TranslationKey.webdavUrlMustStartWithHttp:
        return "URL must start with http:// or https://";
      case TranslationKey.usernameRequired:
        return "Please enter username";
      case TranslationKey.passwordRequired:
        return "Please enter password";
      case TranslationKey.baseDirectoryRequired:
        return "Please select base directory";
      case TranslationKey.baseDirectoryMustStartWithSlash:
        return "Base directory must start with /";
      case TranslationKey.serverUrl:
        return "Server URL";
      case TranslationKey.username:
        return "Username";
      case TranslationKey.password:
        return "Password";
      case TranslationKey.storagePath:
        return "Storage Path";
      case TranslationKey.storagePathHint:
        return "Select Storage Path";
      case TranslationKey.pleaseInputCorrectURL:
        return "Please enter the correct URL";
      case TranslationKey.nameRequired:
        return "Please enter config name";
      case TranslationKey.configName:
        return "Config Name";
      case TranslationKey.noConfig:
        return "None";
      case TranslationKey.s3EndpointRequired:
        return 'S3 endpoint is required';
      case TranslationKey.accessKeyRequired:
        return 'Access Key is required';
      case TranslationKey.secretKeyRequired:
        return 'Secret Key is required';
      case TranslationKey.bucketNameRequired:
        return 'Bucket name is required';
      case TranslationKey.configureS3Storage:
        return 'Configure S3 Storage';
      case TranslationKey.endpoint:
        return 'Endpoint';
      case TranslationKey.s3AccessKey:
        return 'Access Key';
      case TranslationKey.s3SecretKey:
        return 'Secret Key';
      case TranslationKey.bucketName:
        return 'Bucket Name';
      case TranslationKey.region:
        return 'Region';
      case TranslationKey.optional:
        return 'Optional';
      case TranslationKey.objectStorageType:
        return 'Storage Type';
      case TranslationKey.standardS3Protocol:
        return "Standard S3 protocol";
      case TranslationKey.aliyunOss:
        return "Alibaba Cloud OSS";
      case TranslationKey.pleaseInputCorrectDomain:
        return "Please enter a valid domain";
      case TranslationKey.notificationServerConfigure:
        return "Notification Server Settings";
      case TranslationKey.notificationServerAddress:
        return "Notification Server Address";
      case TranslationKey.regionRequired:
        return "Region is required";
      case TranslationKey.pleaseInputCorrectWsURL:
        return "Please enter the correct address (ws:// or wss://)";
      case TranslationKey.selectStoragePath:
        return "Select Storage Path";
      case TranslationKey.readonly:
        return "Read-only";
      case TranslationKey.version:
        return "Version";
      case TranslationKey.changeForwardWayConfirm:
        return 'Switch forward method? Current forward connections will be disconnected.';
      case TranslationKey.s3:
        return 'S3';
      case TranslationKey.none:
        return 'None';
      case TranslationKey.forwardServer:
        return 'Forward Server';
      case TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText:
        return "Configure WebDAV first";
      case TranslationKey.forwardSettingsForwardEnableRequiredS3Text:
        return "Configure S3 first";
      case TranslationKey.createFolder:
        return 'Create Folder';
      case TranslationKey.invalidFolderName:
        return 'Invalid name, cannot contain special characters and must be less than 255 characters';
      case TranslationKey.createFailed:
        return 'Creation failed';
      case TranslationKey.notAllowRootPath:
        return 'Root path is not allowed';
      case TranslationKey.s3TypeTips:
        return "Any object storage service compatible with the standard S3 protocol can be configured directly.\n\nTencent Cloud and Qiniu Cloud have been tested and work well.\n\nAlibaba Cloud OSS requires separate settings.";
      case TranslationKey.forwardWay:
        return "Forward Method";
      case TranslationKey.backupTypeConfig:
        return "Config";
      case TranslationKey.backupTypeAppInfo:
        return "Clipboard Source";
      case TranslationKey.backupTypeDevice:
        return "Devices";
      case TranslationKey.backupTypeHistory:
        return "History";
      case TranslationKey.backupTypeHistoryTag:
        return "Tags";
      case TranslationKey.backupTypeOperationRecord:
        return "Operation Record";
      case TranslationKey.backupTypeOperationSync:
        return "Sync Record";
      case TranslationKey.selectBackupItems:
        return "Select Backup Items";
      case TranslationKey.online:
        return "Online";
      case TranslationKey.offline:
        return "Offline";
      case TranslationKey.enterSoftware:
        return "Enter App";
      case TranslationKey.segmentWords:
        return "Segment Words";
      case TranslationKey.downloadFromGithub:
        return 'Download from Github';
      case TranslationKey.notFoundJiebaFiles:
        return "Jieba files not found.\nDownload them and copy them to:\n@dirPath\nOnly dict.txt and prob_emit.txt are required.";
      case TranslationKey.installJiebaDictFile:
        return "Install";
      case TranslationKey.downloadFailed:
        return "Download failed!";
      case TranslationKey.jiebaFileInstallSuccess:
        return "Jieba files installed";
      case TranslationKey.encryptKey:
        return "Encryption Key";
      case TranslationKey.encryptKeyErrorTip:
        return 'Length must be at least 8 characters and cannot contain whitespace';
      case TranslationKey.confirmClearEncryptKey:
        return 'Confirm clear encryption key?';
      case TranslationKey.authFailed:
        return 'Authentication failed';
      case TranslationKey.dhKeySettingName:
        return 'Encrypt Key Exchange';
      case TranslationKey.dhKeySettingDesc:
        return 'All devices need this and the same password, or connection fails.';
      case TranslationKey.dhKeySettingTips:
        return 'Encrypts the Diffie-Hellman key exchange parameters used during device connection.\nWhen enabled, all connected devices must enable this and use the same password, or they cannot connect.\n\nLeaving it off is also acceptable.';
      case TranslationKey.syncOutDateSettingTitle:
        return 'Sync Date Range';
      case TranslationKey.syncOutDateSettingDesc:
        return 'Sync only data in the selected time range.';
      case TranslationKey.pleaseWait:
        return "Please wait...";
      case TranslationKey.generateTodayAndroidLog:
        return "Generate Android native logs (today)";
      case TranslationKey.noDiscoveryIfsSettingTitle:
        return 'Exclude Discovery NICs';
      case TranslationKey.noDiscoveryIfsSettingDesc:
        return 'Skip selected NICs during subnet scans.';
      case TranslationKey.onlyManualDiscoverySubNetSettingTitle:
        return 'Manual Subnet Scan Only';
      case TranslationKey.onlyManualDiscoverySubNetSettingDesc:
        return 'No auto scans after network changes or screen wake; scan from Devices.';
      case TranslationKey.stopListeningOnScreenClosedSettingTitle:
        return 'Stop on Screen-off (Experimental)';
      case TranslationKey.stopListeningOnScreenClosedSettingDesc:
        return 'Stops clipboard listening 1 minute after screen-off to save battery on some devices.';
      case TranslationKey.keepConnectionsOnNetworkSwitchTitle:
        return 'Keep Existing Connections';
      case TranslationKey.keepConnectionsOnNetworkSwitchDesc:
        return 'Reconnect only on Wi-Fi/mobile or online/offline changes; otherwise keep existing connections.';
      case TranslationKey.notNow:
        return 'Not now';
      case TranslationKey.faq:
        return 'FAQ';
      case TranslationKey.sendBroadcastOnAddData:
        return 'Send broadcast when adding data';
      case TranslationKey.sendBroadcastOnAddDataDesc:
        return 'Send a system broadcast on clipboard changes or synced data so apps like Tasker can process it.';
      case TranslationKey.explain:
        return 'Explanation';
      case TranslationKey.sendBroadcastOnAddDataTips:
        return 'The broadcast Action is: ${Constants.kOnHistoryChangedBroadcastAction}\n\nThe current broadcast contains the following variables:\n1.type: Content type, valid values are: text, image, sms, file, notification\n2. content: Content, when it is an image or file, it is a local path; when it is a notification, it is JSON\n3. from_dev_id: Source device ID\n4. from_dev_name: Source device name';
      case TranslationKey.recopyOnScreenUnlockedTitle:
        return "Retry Latest Copy After Unlock";
      case TranslationKey.recopyOnScreenUnlockedTitleDesc:
        return "On some systems, auto-copy fails while locked. Retry copying the latest synced data after unlock.";
      case TranslationKey.rulesManagement:
        return "Rules";
      case TranslationKey.excludePrivateFormat:
        return "Skip Excluded Formats";
      case TranslationKey.excludePrivateFormatDesc:
        return "Do not record clipboard entries marked for exclusion.";
      case TranslationKey.excludePrivateFormatTips:
        return "When clipboard content contains the ExcludeClipboardContentFromMonitorProcessing marker, it will not be recorded.";
      case TranslationKey.moreActions:
        return "More Actions";
      case TranslationKey.retainDays:
        return "Keep Last";
      case TranslationKey.onlyLocal:
        return "Only Local";
      case TranslationKey.enablePIP:
        return "Enable Picture-in-Picture";
      case TranslationKey.enablePIPTip:
        return "Open received videos in Picture-in-Picture and improve clipboard detection.";
      case TranslationKey.permissionSettingsClipboardTitle:
        return "Clipboard Permission";
      case TranslationKey.permissionSettingsClipboardDesc:
        return "Some Android systems allow clipboard access only while in use. Grant this to enable background clipboard access.";
      case TranslationKey.local:
        return "Local";
      case TranslationKey.directConnect:
        return "Direct";
      case TranslationKey.selectBackupSource:
        return "Backup Location";
      case TranslationKey.notConfigured:
        return "Not Configured";
      case TranslationKey.storagePathTips:
        return "Backup files and transfer files are stored in different folders within the same directory.\nIf the storage path is set to /ClipShare\nthen the temporary transfer files are stored in /ClipShare/history, \nthe backup files are stored in /ClipShare/backup.";
      case TranslationKey.uploading:
        return "Uploading";
      case TranslationKey.useTrayFlashingForConnectionTitle:
        return "Flash Tray on Connect/Disconnect";
      case TranslationKey.useTrayFlashingForConnectionDesc:
        return "Flash the tray instead of showing system notifications.";
      case TranslationKey.trayDevAliveTooltip:
        return "@first\n"
            "Connected to @pairedCnt paired devices\n"
            "Connected to @unpairedCnt unpaired devices";
      case TranslationKey.displayExtractedContent:
        return "Display Extracted Content";
      case TranslationKey.displayOriginContent:
        return "Display Original Content";

      //region lua code prompt
      case TranslationKey.codePromptParamsContentIsSyncDisabled:
        return "Whether to prevent sync";
      case TranslationKey.codePromptParamsContentTags:
        return "Tags";
      case TranslationKey.codePromptParamsContentExtracted:
        return "Extracted content";
      case TranslationKey.codePromptParamsContentDetail:
        return "Content";
      case TranslationKey.codePromptParamsContentNotificationTitle:
        return "Notification title (notification type only)";
      case TranslationKey.codePromptParamsContentSource:
        return "Source, such as a local path or app package name";
      case TranslationKey.codePromptParamsContentType:
        return "Content type";
      case TranslationKey.codePromptNotificationType:
        return "Notification";
      case TranslationKey.codePromptImageType:
        return "Image";
      case TranslationKey.codePromptTextType:
        return "Text";
      case TranslationKey.codePromptSmsType:
        return "SMS";
      case TranslationKey.codePromptJsonDecode:
        return "JSON decode";
      case TranslationKey.codePromptLogError:
        return "Log an error-level message";
      case TranslationKey.codePromptLogWarn:
        return "Log a warning-level message";
      case TranslationKey.codePromptLogDebug:
        return "Log a debug-level message";
      case TranslationKey.codePromptLogInfo:
        return "Log an info-level message";
      case TranslationKey.codePromptContentType:
        return "Content type";
      case TranslationKey.codePromptJson:
        return "JSON Module";
      case TranslationKey.codePromptLog:
        return "Log Module";
      case TranslationKey.codePromptPrint:
        return "Print output, equivalent to logger.debug()";
      case TranslationKey.codePromptMath:
        return 'Math Module';
      case TranslationKey.codePromptString:
        return 'String Module';
      case TranslationKey.codePromptTable:
        return 'Table manipulation Module';
      case TranslationKey.codePromptUtf8:
        return 'UTF-8 Module';
      case TranslationKey.codePromptOs:
        return 'OS Module (safe subset)';
      case TranslationKey.codePromptType:
        return 'Get value type';
      case TranslationKey.codePromptToString:
        return 'Convert to string';
      case TranslationKey.codePromptToNumber:
        return 'Convert to number';
      case TranslationKey.codePromptPairs:
        return 'Iterate table (key-value pairs)';
      case TranslationKey.codePromptIpairs:
        return 'Iterate array (numeric index)';
      case TranslationKey.codePromptNext:
        return 'Get next element';
      case TranslationKey.codePromptPcall:
        return 'Protected function call';
      case TranslationKey.codePromptXpcall:
        return 'Protected call with error handler';
      case TranslationKey.codePromptSelect:
        return 'Access variadic arguments';
      case TranslationKey.codePromptAssert:
        return 'Assertion check';
      case TranslationKey.codePromptError:
        return 'Raise an error';
      case TranslationKey.codePromptMathAbs:
        return 'Absolute value';
      case TranslationKey.codePromptMathAcos:
        return 'Arc cosine';
      case TranslationKey.codePromptMathAsin:
        return 'Arc sine';
      case TranslationKey.codePromptMathAtan:
        return 'Arc tangent';
      case TranslationKey.codePromptMathCeil:
        return 'Round up';
      case TranslationKey.codePromptMathCos:
        return 'Cosine';
      case TranslationKey.codePromptMathDeg:
        return 'Radians to degrees';
      case TranslationKey.codePromptMathExp:
        return 'Exponential';
      case TranslationKey.codePromptMathFloor:
        return 'Round down';
      case TranslationKey.codePromptMathFmod:
        return 'Remainder';
      case TranslationKey.codePromptMathHuge:
        return 'Largest float value';
      case TranslationKey.codePromptMathLog:
        return 'Logarithm';
      case TranslationKey.codePromptMathMax:
        return 'Maximum value';
      case TranslationKey.codePromptMathMaxInteger:
        return 'Maximum integer';
      case TranslationKey.codePromptMathMin:
        return 'Minimum value';
      case TranslationKey.codePromptMathMinInteger:
        return 'Minimum integer';
      case TranslationKey.codePromptMathModf:
        return 'Integer and fractional parts';
      case TranslationKey.codePromptMathPi:
        return 'Pi constant';
      case TranslationKey.codePromptMathRad:
        return 'Degrees to radians';
      case TranslationKey.codePromptMathRandom:
        return 'Random number';
      case TranslationKey.codePromptMathRandomSeed:
        return 'Set random seed';
      case TranslationKey.codePromptMathSin:
        return 'Sine';
      case TranslationKey.codePromptMathSqrt:
        return 'Square root';
      case TranslationKey.codePromptMathTan:
        return 'Tangent';
      case TranslationKey.codePromptMathToInteger:
        return 'Convert to integer';
      case TranslationKey.codePromptMathType:
        return 'Number subtype';
      case TranslationKey.codePromptMathUlt:
        return 'Unsigned integer comparison';
      case TranslationKey.codePromptStringByte:
        return 'Character code';
      case TranslationKey.codePromptStringChar:
        return 'Create string from character codes';
      case TranslationKey.codePromptStringDump:
        return 'Dump function bytecode';
      case TranslationKey.codePromptStringLen:
        return 'String length';
      case TranslationKey.codePromptStringSub:
        return 'Substring';
      case TranslationKey.codePromptStringFind:
        return 'Find substring';
      case TranslationKey.codePromptStringFormat:
        return 'Format string';
      case TranslationKey.codePromptStringGMatch:
        return 'Iterate matches';
      case TranslationKey.codePromptStringGSub:
        return 'Replace matches';
      case TranslationKey.codePromptStringLower:
        return 'Convert to lowercase';
      case TranslationKey.codePromptStringMatch:
        return 'Match pattern';
      case TranslationKey.codePromptStringPack:
        return 'Pack values into binary string';
      case TranslationKey.codePromptStringPackSize:
        return 'Packed size';
      case TranslationKey.codePromptStringRep:
        return 'Repeat string';
      case TranslationKey.codePromptStringReverse:
        return 'Reverse string';
      case TranslationKey.codePromptStringUnpack:
        return 'Unpack binary string';
      case TranslationKey.codePromptStringUpper:
        return 'Convert to uppercase';
      case TranslationKey.codePromptTableInsert:
        return 'Insert element';
      case TranslationKey.codePromptTableMove:
        return 'Move elements between tables';
      case TranslationKey.codePromptTableRemove:
        return 'Remove element';
      case TranslationKey.codePromptTableSort:
        return 'Sort table';
      case TranslationKey.codePromptTableConcat:
        return 'Concatenate strings';
      case TranslationKey.codePromptUtf8Len:
        return 'UTF-8 string length';
      case TranslationKey.codePromptUtf8Char:
        return 'Create UTF-8 character';
      case TranslationKey.codePromptUtf8CharPattern:
        return 'UTF-8 character pattern';
      case TranslationKey.codePromptUtf8Codes:
        return 'Iterate UTF-8 code points';
      case TranslationKey.codePromptUtf8CodePoint:
        return 'Get UTF-8 code points';
      case TranslationKey.codePromptUtf8Offset:
        return 'Get UTF-8 offset';
      case TranslationKey.codePromptOsClock:
        return 'CPU time used';
      case TranslationKey.codePromptOsDate:
        return 'Get current date';
      case TranslationKey.codePromptOsTime:
        return 'Get timestamp';
      case TranslationKey.codePromptOsDiffTime:
        return 'Time difference';
      case TranslationKey.codePromptLuaVersion:
        return 'Current Lua version';
      case TranslationKey.codePromptTablePack:
        return 'Pack arguments into a table';
      case TranslationKey.codePromptTableUnpack:
        return 'Unpack a table into multiple return values';
      case TranslationKey.codePromptScriptParams:
        return 'Script parameters, including content, type, source, and other information';
      case TranslationKey.codePromptIfSnippet:
        return 'If condition snippet';
      case TranslationKey.codePromptElseSnippet:
        return 'Else snippet';
      case TranslationKey.codePromptElseIfSnippet:
        return 'Else-if snippet';
      case TranslationKey.codePromptWhileSnippet:
        return 'While loop snippet';
      case TranslationKey.codePromptRepeatSnippet:
        return 'Repeat-until loop snippet';
      case TranslationKey.codePromptForSnippet:
        return 'For numeric loop snippet';
      case TranslationKey.codePromptForStepSnippet:
        return 'For loop with step snippet';
      case TranslationKey.codePromptIPairsSnippet:
        return 'Ipairs iteration snippet';
      case TranslationKey.codePromptPairsSnippet:
        return 'Pairs table iteration snippet';
      case TranslationKey.codePromptFunctionSnippet:
        return 'Function definition snippet';
      case TranslationKey.codePromptLocalFunctionSnippet:
        return 'Local function definition snippet';
      case TranslationKey.codePromptPlatformAndroid:
        return 'Android platform';
      case TranslationKey.codePromptNotify:
        return 'Notification';
      case TranslationKey.codePromptAndroidToast:
        return 'Android toast message';
      case TranslationKey.codePromptAndroidSendHistoryChangedBroadcast:
        return 'Android send history changed broadcast';
      case TranslationKey.codePromptPlatform:
        return 'Platform';
      case TranslationKey.codePromptPlatformIsAndroid:
        return 'Check if platform is Android';
      case TranslationKey.codePromptPlatformIsIOS:
        return 'Check if platform is iOS';
      case TranslationKey.codePromptPlatformIsWindows:
        return 'Check if platform is Windows';
      case TranslationKey.codePromptPlatformIsMacOS:
        return 'Check if platform is macOS';
      case TranslationKey.codePromptPlatformIsLinux:
        return 'Check if platform is Linux';
      case TranslationKey.codePromptApp:
        return 'App';
      case TranslationKey.codePromptAppVersionName:
        return 'App version name';
      case TranslationKey.codePromptAppVersionNumber:
        return 'App version number';
      case TranslationKey.codePromptDeviceSelf:
        return 'Current device';
      case TranslationKey.codePromptDeviceSelfName:
        return 'Current device name';
      case TranslationKey.codePromptDeviceSelfId:
        return 'Current device ID';
      case TranslationKey.codePromptCrypto:
        return 'Cryptography';
      case TranslationKey.codePromptCryptoMD5:
        return 'Compute MD5 hash';
      case TranslationKey.codePromptCryptoSHA256:
        return 'Compute SHA-256 hash';
      case TranslationKey.codePromptCryptoSHA1:
        return 'Compute SHA-1 hash';
      case TranslationKey.codePromptBase64:
        return 'Base64';
      case TranslationKey.codePromptBase64Encode:
        return 'Encode Base64';
      case TranslationKey.codePromptBase64Decode:
        return 'Decode Base64';
      case TranslationKey.codePromptRegex:
        return 'Regular expression';
      case TranslationKey.codePromptRegexMatch:
        return 'Match all full matches and return as a list';
      case TranslationKey.codePromptRegexMatchGroups:
        return 'Match all capture groups and return as a nested list';
      case TranslationKey.codePromptHttp:
        return 'HTTP request Module';
      case TranslationKey.codePromptTask:
        return 'Async task Module';
      case TranslationKey.codePromptAsync:
        return 'Wraps a function as async, allowing await inside';
      case TranslationKey.codePromptAwait:
        return 'Waits for an awaiter to complete and returns its result; can only be used inside an async function';
      case TranslationKey.codePromptHttpGet:
        return 'GET request method (async)';
      case TranslationKey.codePromptHttpPost:
        return 'POST request method (async)';
      case TranslationKey.codePromptPut:
        return 'PUT request method (async)';
      case TranslationKey.codePromptDelete:
        return 'DELETE request method (async)';
      case TranslationKey.codePromptTaskCreate:
        return 'Creates a task (awaiter)';
      //endregion
      case TranslationKey.rulesPageUnsavedChangesConfirm:
        return 'There are unsaved changes. Continue anyway?';
      case TranslationKey.ruleItemContentRequired:
        return 'Rule content cannot be empty';
      case TranslationKey.ruleItemExtractRuleRequired:
        return 'Extraction rule cannot be empty';
      case TranslationKey.ruleItemScriptContentRequired:
        return 'Script content cannot be empty';
      case TranslationKey.ruleItemUnsupportedOperation:
        return 'Unsupported operation';
      case TranslationKey.ruleTriggerOnCopyText:
        return 'After copy';
      case TranslationKey.ruleTriggerOnNotificationText:
        return 'New notification';
      case TranslationKey.ruleTriggerOnSmsText:
        return 'New SMS';
      case TranslationKey.ruleDetailRegexHint:
        return 'Enter a regular expression';
      case TranslationKey.ruleDetailNameLabel:
        return 'Rule name: ';
      case TranslationKey.ruleDetailNameHint:
        return 'Enter rule name';
      case TranslationKey.ruleDetailPlatformLabel:
        return 'Platform';
      case TranslationKey.ruleDetailTriggerLabel:
        return 'Trigger';
      case TranslationKey.ruleDetailRuleLabel:
        return 'Rule';
      case TranslationKey.ruleDetailRegexTab:
        return 'Regex';
      case TranslationKey.ruleDetailScriptTab:
        return 'Script';
      case TranslationKey.ruleDetailAutoWrapTooltip:
        return 'Auto wrap';
      case TranslationKey.ruleDetailFullScreenTooltip:
        return 'Enter full-screen editor';
      case TranslationKey.ruleDetailModeDefault:
        return 'Default';
      case TranslationKey.ruleDetailModeBlacklist:
        return 'Blacklist';
      case TranslationKey.ruleDetailModeWhitelist:
        return 'Whitelist';
      case TranslationKey.ruleDetailRegexLabel:
        return 'Rule:';
      case TranslationKey.ruleDetailExtractContent:
        return 'Extract content';
      case TranslationKey.ruleDetailModeLabel:
        return 'Rule mode';
      case TranslationKey.ruleDetailActionLabel:
        return 'Actions';
      case TranslationKey.ruleDetailAddTagLabel:
        return 'Add tags:';
      case TranslationKey.ruleDetailAddTagDialogTitle:
        return 'Add tag';
      case TranslationKey.ruleDetailFinalRule:
        return 'Stop following rules';
      case TranslationKey.ruleDetailRunTestTooltip:
        return 'Run test';
      case TranslationKey.ruleDetailPageTitle:
        return 'Rule details';
      case TranslationKey.ruleModulesDetailSyntaxError:
        return 'Contains syntax errors. Please fix them';
      case TranslationKey.scriptModulesDetailDisplayNameRequired:
        return 'Display name cannot be empty';
      case TranslationKey.scriptModulesDetailModuleNameRequired:
        return 'Module name cannot be empty';
      case TranslationKey.scriptModulesDetailModuleNameDuplicated:
        return 'Module name must be unique';
      case TranslationKey.scriptModuleDetailContentRequired:
        return 'Content cannot be empty';
      case TranslationKey.scriptModuleDetailDisplayNameLabel:
        return 'Display name: ';
      case TranslationKey.scriptModuleDetailDisplayNameHint:
        return 'Enter display name';
      case TranslationKey.scriptModuleDetailModuleNameLabel:
        return 'Module name';
      case TranslationKey.scriptModuleDetailModuleNameImmutableTooltip:
        return 'Module name cannot be changed after saving';
      case TranslationKey.scriptModuleDetailModuleNameHint:
        return 'Module name';
      case TranslationKey.scriptModuleDetailNameInvalid:
        return 'Only letters, numbers, and underscores are allowed, and it cannot start with a number';
      case TranslationKey.scriptModuleDetailPageTitle:
        return 'Module details';
      case TranslationKey.ruleListDeleteModuleConfirm:
        return 'Delete it? If other scripts use it, they will stop working.';
      case TranslationKey.ruleListExitSelectionModeTooltip:
        return 'Exit selection mode';
      case TranslationKey.ruleCardDragDisabledTooltip:
        return 'Save data or clear the search input before reordering';
      case TranslationKey.ruleCardDragTooltip:
        return 'Reorder';
      case TranslationKey.scriptEditTestViewPanelTooltip:
        return 'Run panel';
      case TranslationKey.scriptEditTestViewRunTooltip:
        return 'Run';
      case TranslationKey.scriptEditTestViewExitFullScreenTooltip:
        return 'Exit full-screen editor';
      case TranslationKey.scriptTestPanelParamsTab:
        return 'Params';
      case TranslationKey.scriptTestPanelCompileInfoTab:
        return 'Compile info';
      case TranslationKey.scriptTestPanelOutputTab:
        return 'Output';
      case TranslationKey.scriptTestPanelRunResultTab:
        return 'Run result';
      case TranslationKey.scriptTestPanelCollapseTooltip:
        return 'Collapse';
      case TranslationKey.ruleCompileCodeNotFound:
        return 'Code not found';
      case TranslationKey.ruleCompileCodeEmpty:
        return 'Code is empty';
      case TranslationKey.ruleCompileSuccess:
        return 'Compile succeeded.';
      case TranslationKey.ruleCompileFailedPrefix:
        return 'Compile failed:\n@message';
      case TranslationKey.scriptModuleCompileReturnTableRequired:
        return 'The Module return value must be a table.';

      case TranslationKey.success:
        return 'Success';
      case TranslationKey.error:
        return 'Error';
      case TranslationKey.extracted:
        return 'Extracted';
      case TranslationKey.tags:
        return 'Tags';
      case TranslationKey.flags:
        return 'Flags';
      case TranslationKey.finalRule:
        return 'Final';
      case TranslationKey.dropped:
        return 'Dropped';
      case TranslationKey.syncDisabled:
        return 'Prevent Sync';
      case TranslationKey.rules:
        return 'Rules';
      case TranslationKey.scriptModules:
        return 'Script Modules';
      case TranslationKey.modules:
        return 'Modules';
      case TranslationKey.unknown:
        return 'Unknown';
      case TranslationKey.triggerOnCopy:
        return 'Trigger: Copy';
      case TranslationKey.triggerOnNotification:
        return 'Trigger: Notification';
      case TranslationKey.triggerOnSms:
        return 'Trigger: SMS';
      case TranslationKey.modulesTip:
        return 'You can import pure Lua libraries, or encapsulate some frequently used methods for scripts to call. The return value must be a table.\n'
            'The sandbox environment is the same as in the script.';
      case TranslationKey.recordMaxLength:
        return 'Max content length';
      case TranslationKey.recordMaxLengthTips:
        return 'Can save 2 MB+ content, but search may fail.';
      case TranslationKey.length:
        return 'Length';
      case TranslationKey.mustGreaterThanZero:
        return 'Must >= 0';
      case TranslationKey.settingsSectionLanguageSubtitle:
        return 'Display language';
      case TranslationKey.settingsSectionPreferenceSubtitle:
        return 'UI & interaction';
      case TranslationKey.settingsSectionNotificationSubtitle:
        return 'Alerts & reminders';
      case TranslationKey.settingsSectionClipboardSubtitle:
        return 'Capture & history';
      case TranslationKey.settingsSectionPermissionSubtitle:
        return 'App permissions';
      case TranslationKey.settingsSectionFloatWindowSubtitle:
        return 'Floating window and keep-alive';
      case TranslationKey.settingsSectionDiscoverySubtitle:
        return 'Devices & connections';
      case TranslationKey.settingsSectionForwardSubtitle:
        return 'Relay & storage';
      case TranslationKey.settingsSectionSecuritySubtitle:
        return 'Auth & encryption';
      case TranslationKey.settingsSectionHotKeySubtitle:
        return 'Popup & window shortcuts';
      case TranslationKey.settingsSectionSyncSubtitle:
        return 'History saving';
      case TranslationKey.settingsSectionRulesSubtitle:
        return 'Rules & scripts';
      case TranslationKey.settingsSectionBackupSubtitle:
        return 'Import & export';
      case TranslationKey.settingsSectionAboutLogSubtitle:
        return 'App info';
      case TranslationKey.settingsSectionStatisticsSubtitle:
        return 'Usage insights';
      case TranslationKey.settingsOverviewPermissionNormal:
        return 'All granted';
      case TranslationKey.settingsOverviewPermissionIssueCount:
        return '@count pending';
      case TranslationKey.settingsOverviewForwardClosed:
        return 'Off';
      case TranslationKey.storageWsVersionIncompatibleTitle:
        return "Incompatible version";
      case TranslationKey.storageWsVersionIncompatibleDialogContent:
        return "Current notification service version: @version. Minimum required: @minVersion. Please upgrade it before using storage sync.";
    }
  }
}
