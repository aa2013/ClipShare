import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/translations/app_translations.dart';
import 'package:clipshare/app/utils/constants.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class EnUSTranslation extends AbstractTranslations {
  @override
  String translate(TranslationKey key) {
    switch (key) {
      case TranslationKey.unitWord:
        return "words";
      case TranslationKey.dialogCancelText:
        return "Cancel";
      case TranslationKey.dialogAuthorizationButtonText:
        return "Go to Authorize";
      case TranslationKey.floatPermRequestDialogTitle:
        return "Request Floating Window Permission";
      case TranslationKey.floatPermRequestDialogContent:
        return 'Due to restrictions on Android 10 and above, the app cannot read the clipboard in the background. When the clipboard changes, the app needs to indirectly read the clipboard by accessing system logs and the floating window permission.'
            '\n\nClick OK to go to the authorization page for the floating window permission.';
      case TranslationKey.requiredPermDialogTitle:
        return "Required Permission Missing";
      case TranslationKey.floatPermMissingDialogContent:
        return 'Please grant the floating window permission, otherwise the clipboard cannot be read in the background.';
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
        return 'Disable battery optimization to improve background retention.\n'
            'If there is no response after clicking [Go to Authorize], please manually find the relevant settings in your phone settings.';
      case TranslationKey.selectWorkMode:
        return "Select Work Mode";
      case TranslationKey.completed:
        return "Completed";
      case TranslationKey.completedGuideTitleDescription:
        return "All settings have been completed.";
      case TranslationKey.floatPermGuideTitle:
        return "Floating Window Permission";
      case TranslationKey.floatPermGuideDescription:
        return "Due to restrictions on higher Android versions, ${Constants.appName} needs to obtain clipboard focus through the floating window. After enabling the floating window, you can also view clipboard history and drag to select from the edge of the screen at any time.";
      case TranslationKey.notificationPermGuideTitle:
        return "Notification Permission";
      case TranslationKey.notificationPermGuideDescription:
        return "Enable notifications to start the foreground service.";
      case TranslationKey.storagePermGuideTitle:
        return "Storage Permission";
      case TranslationKey.storagePermGuideDescription:
        return "Storage permission is required to sync images and files, otherwise files cannot be saved.";
      case TranslationKey.batteryOptimizationPermGuideDescription:
        return "To ensure background survival, it needs to be removed from battery optimization.\n"
            "Additionally, please lock it in the background task card and set it to allow auto-start in the phone manager!\n"
            "If there is no response after clicking [Go to Authorize], please manually find the relevant settings in your phone settings.";
      case TranslationKey.aboutPageInstructionsItemName:
        return "Instructions";
      case TranslationKey.aboutPageJoinQQGroupItemName:
        return "Join QQ Group";
      case TranslationKey.aboutPageWebsiteItemName:
        return "View Official Website";
      case TranslationKey.aboutPageLogsItemName:
        return "Update Logs";
      case TranslationKey.aboutPageVersionItemName:
        return "Software Version";
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
      case TranslationKey.devicePageUnpairedDialogAck:
        return "Do you want to unpair?";
      case TranslationKey.devicePageUnpairedButtonText:
        return "Unpair";
      case TranslationKey.devicePagePairingDialogTitle:
        return "Please Enter Pairing Code";
      case TranslationKey.devicePagePairingTimeoutText:
        return "Pairing Timeout!";
      case TranslationKey.devicePagePairingErrorText:
        return "Pairing Code Error!";
      case TranslationKey.devicePagePairingDialogConfirmText:
        return "Pair!";
      case TranslationKey.devicePageMyDevicesText:
        return "My Devices (@length)";
      case TranslationKey.devicePageForwardServerText:
        return "Forward Connection";
      case TranslationKey.devicePageDiscoverDevicesText:
        return "Discover Devices (@length)";
      case TranslationKey.devicePageRediscoverTooltip:
        return "Rediscover Devices";
      case TranslationKey.devicePageManuallyTooltip:
        return "Manually Add Device";
      case TranslationKey.devicePageStopDiscoveringTooltip:
        return "Stop Discovering";
      case TranslationKey.sms:
        return "SMS";
      case TranslationKey.bottomNavigationSearchHistoryBarItemLabel:
        return "Search";
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
        return "Save top data";
      case TranslationKey.removeLocalFiles:
        return "Remove local files";
      case TranslationKey.saveFilterConfig:
        return "Save filter config";
      case TranslationKey.saveAutoCleanConfig:
        return "Save auto clean config";
      case TranslationKey.noDataFromFilter:
        return "Filter did not find any data";
      case TranslationKey.filterCleaningConfirmation:
        return "Found @cnt items, this operation cannot be recovered. \nDo you want to continue?";
      case TranslationKey.syncRecordsCleaningConfirmation:
        return "Cleaning up device synchronization records will result in data being resynchronized after the next connection";
      case TranslationKey.onlyNotSync:
        return "Only Unsynced";
      case TranslationKey.syncRecordsCleanBtn:
        return "Clean sync records for devices";
      case TranslationKey.optionRecordsCleaningConfirmation:
        return "Cleaning up device operation records will result in unsynchronized data not being automatically synchronized again";
      case TranslationKey.optionRecordsCleanBtn:
        return "Clean operation records for devices";
      case TranslationKey.autoCleanFrequency:
        return "Frequency";
      case TranslationKey.execTime:
        return "Exec time";
      case TranslationKey.nextExecTime:
        return "Next cleaning time: ";
      case TranslationKey.errorCronTips:
        return "Please enter the correct UnixCron expression";
      case TranslationKey.filterTips:
        return "If the corresponding filter is not selected, it means all are selected.\nThe date range will not be saved as a filtering configuration";
      case TranslationKey.autoCleanConfigTitle:
        return "Auto clean";
      case TranslationKey.daily:
        return "Daily";
      case TranslationKey.weekly:
        return "Weekly";
      case TranslationKey.selectWeekDay:
        return "Select WeekDay";
      case TranslationKey.deleteItemsUnit:
        return "items";
      case TranslationKey.pleaseSelectDevices:
        return "Please Select Devices!";
      case TranslationKey.saveSuccess:
        return "Successfully saved!";
      case TranslationKey.pleaseSaveFilterConfig:
        return "Please save filter config";
      case TranslationKey.saveFailed:
        return "Save failed";
      case TranslationKey.updateSuccess:
        return "Successfully update!";
      case TranslationKey.updateFailed:
        return "Update failed！";
      case TranslationKey.searchPageMoreFilterByDateJudgeText:
        return "Date";
      case TranslationKey.confirm:
        return "Confirm";
      case TranslationKey.toToday:
        return "Go to Today";
      case TranslationKey.clear:
        return "Clear";
      case TranslationKey.filterByDevice:
        return "Filter by Device";
      case TranslationKey.filterByTag:
        return "Filter by Tag";
      case TranslationKey.envStatusLoadingText:
        return "Loading Environment Status...";
      case TranslationKey.shizukuModeStatusTitle:
        return "Shizuku Mode";
      case TranslationKey.shizukuModeRunningDescription:
        return "Service is running, API @version";
      case TranslationKey.rootModeStatusTitle:
        return "Root Mode";
      case TranslationKey.rootModeRunningDescription:
        return "Authorized, service is running";
      case TranslationKey.serverNotRunningDescription:
        return "Service is not running, some features are unavailable";
      case TranslationKey.envPermissionIgnored:
        return "Permission Ignored";
      case TranslationKey.envPermissionIgnoredDescription:
        return "Some features may be unavailable";
      case TranslationKey.noSpecialPermissionRequired:
        return "No Special Permission Required";
      case TranslationKey.switchWorkingMode:
        return "Switch Working Mode";
      case TranslationKey.commonSettingsGroupName:
        return "General";
      case TranslationKey.commonSettingsRunAtStartup:
        return "Run at Startup";
      case TranslationKey.commonSettingsRunMinimize:
        return "Minimize Window on Startup";
      case TranslationKey.commonSettingsShowHistoriesFloatWindow:
        return "Show History Floating Window";
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
        return "Used to start the foreground service";
      case TranslationKey.permissionSettingsFloatTitle:
        return "Floating Window Permission";
      case TranslationKey.permissionSettingsFloatDesc:
        return "Obtain clipboard focus through the floating window on higher Android versions";
      case TranslationKey.permissionSettingsBatteryOptimiseTitle:
        return "Battery Optimization";
      case TranslationKey.permissionSettingsBatteryOptimiseDesc:
        return "Add battery optimization to prevent being killed by the background system";
      case TranslationKey.permissionSettingsSmsTitle:
        return "SMS Read";
      case TranslationKey.permissionSettingsSmsDesc:
        return "SMS sync is enabled, please grant SMS read permission";
      case TranslationKey.discoveringSettingsGroupName:
        return "Discovery";
      case TranslationKey.discoveringSettingsLocalDeviceName:
        return "Device Name";
      case TranslationKey.discoveringSettingsDeviceNameCopyTip:
        return "Device ID copied";
      case TranslationKey.copyDeviceId:
        return "Copy Device ID";
      case TranslationKey.modifyDeviceName:
        return "Modify Device Name";
      case TranslationKey.deviceName:
        return "Device Name";
      case TranslationKey.modifyDeviceNameCompletedTooltip:
        return "Restart the app after modification to take effect";
      case TranslationKey.port:
        return "Port";
      case TranslationKey.discoveringSettingsPortDesc:
        return "Default value ${Constants.port}. Modifying it may prevent automatic discovery.";
      case TranslationKey.modifyPort:
        return "Modify Port";
      case TranslationKey.modifyPortErrorText:
        return "Port number range 0-65535";
      case TranslationKey.discoveringSettingsModifyPortCompletedTooltip:
        return "Restart the app after modification to take effect";
      case TranslationKey.allowDiscovering:
        return "Discoverable";
      case TranslationKey.discoveringSettingsAllowDiscoveringDesc:
        return "Can be automatically discovered by other devices";
      case TranslationKey.discoveringSettingsOnlyForwardDiscoveringTitle:
        return "Only Forward Discovery (Debug)";
      case TranslationKey.discoveringSettingsOnlyForwardDiscoveringDesc:
        return "Only show this feature in development environments";
      case TranslationKey.discoveringSettingsHeartbeatIntervalTitle:
        return "Heartbeat Interval";
      case TranslationKey.discoveringSettingsHeartbeatIntervalDesc:
        return "Check device liveliness. Default 30s, 0 to disable";
      case TranslationKey.discoveringSettingsHeartbeatIntervalTooltip:
        return "Description";
      case TranslationKey.enable:
        return "Enable";
      case TranslationKey.disable:
        return "Disable";
      case TranslationKey.dontDetect:
        return "Don't Detect";
      case TranslationKey.discoveringSettingsHeartbeatIntervalTooltipDialogContent:
        return "When a device switches networks, it cannot automatically detect if the device is offline.\n"
            "Enabling heartbeat detection will periodically check the device's liveliness.";
      case TranslationKey.discoveringSettingsModifyHeartbeatDialogTitle:
        return "Heartbeat Interval";
      case TranslationKey.discoveringSettingsModifyHeartbeatDialogInputLabel:
        return "Heartbeat Interval";
      case TranslationKey.discoveringSettingsModifyHeartbeatDialogInputErrorText:
        return "Unit in seconds, 0 to disable detection";
      case TranslationKey.forwardSettingsGroupName:
        return "Forward";
      case TranslationKey.forwardSettingsForwardTitle:
        return "Use Forward Service";
      case TranslationKey.forwardSettingsForwardDownloadTooltip:
        return "Download Forward Program";
      case TranslationKey.forwardSettingsForwardDesc:
        return "Forward server can sync data in public network environments";
      case TranslationKey.forwardSettingsForwardEnableRequiredText:
        return "Please set the forward server address first";
      case TranslationKey.forwardSettingsForwardAddressTitle:
        return "Forward Server Address";
      case TranslationKey.forwardSettingsForwardAddressDesc:
        return "Please use a trusted address or set up your own";
      case TranslationKey.configure:
        return "Configure";
      case TranslationKey.change:
        return "Change";
      case TranslationKey.securitySettingsGroupName:
        return "Security";
      case TranslationKey.securitySettingsEnableSecurityTitle:
        return "Enable Security Authentication";
      case TranslationKey.securitySettingsEnableSecurityDesc:
        return "Enable password or biometric authentication";
      case TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogContent:
        return "Please create an app password first";
      case TranslationKey.securitySettingsEnableSecurityAppPwdRequiredDialogOkText:
        return "Go to Create";
      case TranslationKey.securitySettingsEnableSecurityAppPwdModifyTitle:
        return "Change Password";
      case TranslationKey.createAppPwd:
        return "Create App Password";
      case TranslationKey.changeAppPwd:
        return "Change App Password";
      case TranslationKey.create:
        return 'Create';
      case TranslationKey.securitySettingsReverificationTitle:
        return "Password Re-verification";
      case TranslationKey.securitySettingsReverificationDesc:
        return "Re-verify password after a specified duration in the background";
      case TranslationKey.securitySettingsReverificationValue:
        return "@value minutes";
      case TranslationKey.hotKeySettingsGroupName:
        return "Hotkeys";
      case TranslationKey.hotKeySettingsHistoryTitle:
        return "History Popup";
      case TranslationKey.hotKeySettingsHistoryDesc:
        return "Bring up the history popup from anywhere on the screen";
      case TranslationKey.hotKeySettingsCombinationInvalidText:
        return "Hotkey must be a combination of control and non-control keys!";
      case TranslationKey.hotKeySettingsSaveKeysDialogText:
        return "Save hotkey (@keys) settings?";
      case TranslationKey.hotKeySettingsSaveKeysFailedText:
        return "Failed to set @err";
      case TranslationKey.sendFile:
        return "Send File";
      case TranslationKey.hotKeySettingsFileDesc:
        return "Sync selected files to other devices (invalid on desktop)";
      case TranslationKey.syncSettingsGroupName:
        return "Sync";
      case TranslationKey.syncSettingsSmsTitle:
        return "SMS Sync";
      case TranslationKey.syncSettingsSmsDesc:
        return "SMS that match the rules will be automatically synced";
      case TranslationKey.syncSettingsSmsPermissionRequired:
        return "Please grant SMS read permission first";
      case TranslationKey.syncSettingsStoreImg2PicturesTitle:
        return "Store Images in Pictures";
      case TranslationKey.syncSettingsStoreImg2PicturesDesc:
        return "Will be saved to Pictures/${Constants.appName}";
      case TranslationKey.syncSettingsStoreImg2PicturesNoPermText:
        return "No read/write permission, authorization required";
      case TranslationKey.syncSettingsStoreImg2PicturesCancelPerm:
        return "User canceled authorization!";
      case TranslationKey.syncSettingsStoreFilePathTitle:
        return "File Storage Path";
      case TranslationKey.selection:
        return "Selection";
      case TranslationKey.syncSettingsAutoCopyImgTitle:
        return "Auto Copy Images";
      case TranslationKey.syncSettingsAutoCopyImgDesc:
        return "If enabled, images copied on other devices will be automatically copied on this device";
      case TranslationKey.ruleSettingsGroupName:
        return "Rules";
      case TranslationKey.ruleSettingsTagRuleTitle:
        return "Tag Rules";
      case TranslationKey.ruleSettingsTagRuleDesc:
        return "Records that match the rules will be automatically tagged";
      case TranslationKey.ruleSettingsSmsRuleTitle:
        return "SMS Rules";
      case TranslationKey.ruleSettingsSmsRuleDesc:
        return "SMS that match the rules will be synced, if not configured, all will be synced";
      case TranslationKey.logSettingsGroupName:
        return "Logs";
      case TranslationKey.logSettingsEnableTitle:
        return "Enable Logging";
      case TranslationKey.logSettingsEnableDesc:
        return "Will take up extra space, @size logs have been generated";
      case TranslationKey.openFolder:
        return "Open Folder";
      case TranslationKey.openFilePos:
        return "Open File Location";
      case TranslationKey.tips:
        return "Tips";
      case TranslationKey.logSettingsAckDelLogFiles:
        return "Delete log files?";
      case TranslationKey.statisticsSettingsGroupName:
        return "Statistics";
      case TranslationKey.statisticsSettingsTitle:
        return "View Statistics";
      case TranslationKey.statisticsSettingsDesc:
        return "Presents a brief statistical analysis of local records in charts";
      case TranslationKey.about:
        return "About";
      case TranslationKey.errorDialogTitle:
        return "Error";
      case TranslationKey.selfDeviceName:
        return "Self";
      case TranslationKey.saveFileToPathForSettingDialogText:
        return "This file cannot be read directly\n\nSave to [File Storage Path] first?";
      case TranslationKey.save:
        return "Save";
      case TranslationKey.saveFileNotSupportDialogText:
        return "Unsupported Type";
      case TranslationKey.pieDataStatisticsLocalItemLabel:
        return "Local";
      case TranslationKey.pieDataStatisticsSyncItemLabel:
        return "Sync";
      case TranslationKey.statisticsPageAppBarText:
        return "Statistical Analysis";
      case TranslationKey.statisticsPageFilterRangeText:
        return "Statistics Range";
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
        return "Receive Progress";
      case TranslationKey.syncingFilePageSendTabText:
        return "Send Progress";
      case TranslationKey.dragFileToSend:
        return "Drag and drop the file here to send";
      case TranslationKey.deleting:
        return "Deleting...";
      case TranslationKey.deletingSuccess:
        return "Deleted Successfully";
      case TranslationKey.partialDeletionFailed:
        return "Partial Deletion Failed";
      case TranslationKey.deletionFailed:
        return "Delete Failed";
      case TranslationKey.multiDelete:
        return "Multi-Delete";
      case TranslationKey.deselect:
        return "Deselect";
      case TranslationKey.delete:
        return "Delete";
      case TranslationKey.deleteWithFiles:
        return "Delete with Files";
      case TranslationKey.deleteWithFilesOnSyncFilePageAckDialogText:
        return "Delete selected @length items?\nFiles in sent records will not be deleted";
      case TranslationKey.onlyDeleteRecordsText:
        return "Only Delete Records";
      case TranslationKey.failedToReadUpdateLog:
        return "Failed to Read Update Log!";
      case TranslationKey.skipGuide:
        return "Skip This";
      case TranslationKey.previousGuide:
        return "Previous";
      case TranslationKey.nextGuide:
        return "Next";
      case TranslationKey.finishGuide:
        return "Finish";
      case TranslationKey.previewPageNoSuchFile:
        return "Image does not exist or has been deleted";
      case TranslationKey.copyPathSuccess:
        return "Path Copied Successfully";
      case TranslationKey.tagEditPageAppBarTitle:
        return "Edit Tag";
      case TranslationKey.tagEditPageSearchOrCreateTag:
        return "Search or Create Tag";
      case TranslationKey.tagEditPageCrateTagItem:
        return 'Create "@tag" Tag';
      case TranslationKey.updateLogPageAppBarTitle:
        return 'Update Logs';
      case TranslationKey.failedToReadFile:
        return "Failed to Read File";
      case TranslationKey.welcome:
        return "Welcome to ${Constants.appName}";
      case TranslationKey.welcomeContent:
        return "We need to request some necessary permissions and settings before using the app.";
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
        return "Successfully imported @length items";
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
      case TranslationKey.smsRuleSettingPageAppBarTitle:
        return "SMS Rule Configuration";
      case TranslationKey.inputCompletedErrorText:
        return "Please complete the input!";
      case TranslationKey.ruleSettingAddDialogLabel:
        return "Rule Name";
      case TranslationKey.ruleSettingAddDialogHint:
        return "Please enter the rule name";
      case TranslationKey.tagRuleSettingPageAppBarTitle:
        return "Tag Rule Configuration";
      case TranslationKey.onlineDevicesPageSelectDeviceToSend:
        return "Select devices";
      case TranslationKey.send:
        return "Send";
      case TranslationKey.multipleChoiceOperationAppBarTitle:
        return "Multiple Choice Operation";
      case TranslationKey.forwardServerNotAllowedSendFile:
        return "The connected forward server does not allow file sync";
      case TranslationKey.sendFailed:
        return "Send Failed";
      case TranslationKey.forwardServerUnknownResult:
        return "Unknown Result";
      case TranslationKey.forwardServerConnectFailed:
        return "Forward Server Connection Failed";
      case TranslationKey.newParingRequest:
        return "New Pairing Request";
      case TranslationKey.paringRequest:
        return "Pairing Request";
      case TranslationKey.pairingCodeDialogContent:
        return "Pairing request from @devName\nPairing Code:";
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
        return "Skip This Update";
      case TranslationKey.newVersionDialogOkText:
        return "Download Update";
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
        return "Neutral Button";
      case TranslationKey.open:
        return "Open";
      case TranslationKey.openLink:
        return "Open Link";
      case TranslationKey.moment:
        return "Just Now";
      case TranslationKey.minutesAgo:
        return "minutes ago";
      case TranslationKey.hoursAgo:
        return "hours Ago";
      case TranslationKey.connectFailed:
        return "Connection Failed";
      case TranslationKey.connectSuccess:
        return "Connection Successful";
      case TranslationKey.connect:
        return "Connect";
      case TranslationKey.addDeviceAppBarTittle:
        return 'Add Device';
      case TranslationKey.errorFormatIpv4:
        return "Please enter a valid IPv4 address";
      case TranslationKey.inputPassword:
        return "Enter Password";
      case TranslationKey.inputAgain:
        return "Enter Again";
      case TranslationKey.inputErrorAndAgain:
        return "Input Error, Please Enter Again";
      case TranslationKey.immediately:
        return "Immediately";
      case TranslationKey.minute:
        return 'Minute';
      case TranslationKey.alreadyNewestAppVersion:
        return "Already the Latest Version";
      case TranslationKey.checkUpdate:
        return "Check for Updates";
      case TranslationKey.topUp:
        return "Pin to Top";
      case TranslationKey.cancelTopUp:
        return "Unpin from Top";
      case TranslationKey.copyContent:
        return "Copy Content";
      case TranslationKey.syncRecord:
        return "Sync Record";
      case TranslationKey.resyncRecord:
        return "Resync Record";
      case TranslationKey.openFile:
        return "Open File";
      case TranslationKey.openFileFolder:
        return "Open File Folder";
      case TranslationKey.tagsManagement:
        return "Tags Management";
      case TranslationKey.copySuccess:
        return "Copied Successfully";
      case TranslationKey.copyFailed:
        return "Copy Failed";
      case TranslationKey.clipboardContent:
        return "Clipboard Details";
      case TranslationKey.deleteRecord:
        return "Delete Record";
      case TranslationKey.clipListViewDeleteAsk:
        return "Delete selected @length items?";
      case TranslationKey.deleteCompleted:
        return "Delete Completed";
      case TranslationKey.shareFile:
        return 'Share File';
      case TranslationKey.deleteTips:
        return "Delete Tips";
      case TranslationKey.deleteRecordAck:
        return "Confirm Delete This Record?";
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
      case TranslationKey.renameDevice:
        return "Rename Device";
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
        return "No Root required, Shizuku needs to be installed, reactivation required after phone restart";
      case TranslationKey.shizukuModeBatteryOptimiseTips:
        return "To ensure proper authorization, please add Shizuku to the battery optimization whitelist and allow background running";
      case TranslationKey.shizukuRequestFailedDialogText:
        return "Shizuku permission request failed, please ensure Shizuku is started and try again";
      case TranslationKey.requestFailed:
        return 'Request Failed';
      case TranslationKey.rootMode:
        return "Root Mode";
      case TranslationKey.rootModeDesc:
        return "Start with Root permissions, no reactivation required after phone restart";
      case TranslationKey.waitingRequestResult:
        return 'Waiting for Request Result';
      case TranslationKey.rootRequestFailedDialogText:
        return "Seems like no Root permissions, you can choose Shizuku mode to start";
      case TranslationKey.ignoreMode:
        return "Ignore";
      case TranslationKey.ignoreModeDesc:
        return "Clipboard cannot be monitored in the background, only passive sync is available";
      case TranslationKey.multiChoiceModeSelectedText:
        return "@text items selected";
      case TranslationKey.goAuthorize:
        return "Go to Authorize";
      case TranslationKey.authorized:
        return "Go to Authorize";
      case TranslationKey.cannotEmpty:
        return "Cannot be Empty";
      case TranslationKey.ruleCannotEmpty:
        return "Rule Cannot be Empty";
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
        return "Public Server";
      case TranslationKey.forwardServerSyncFileRateLimit:
        return "File Sync Rate Limit";
      case TranslationKey.forwardServerCannotSyncFile:
        return "This forward server cannot sync files";
      case TranslationKey.forwardServerNoLimits:
        return "No Restrictions";
      case TranslationKey.noLimits:
        return "No Limits";
      case TranslationKey.deviceUnit:
        return "Device";
      case TranslationKey.day:
        return "Day";
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
        return "Domain/IP";
      case TranslationKey.host:
        return "Host";
      case TranslationKey.useKey:
        return "Use Key";
      case TranslationKey.accessKey:
        return "Access Key";
      case TranslationKey.pleaseInputAccessKey:
        return "Please Enter Access Key";
      case TranslationKey.forwardServerConnCheck:
        return "Connection Check";
      case TranslationKey.pleaseInputValidPort:
        return 'Please Enter a Valid Port';
      case TranslationKey.pleaseInputValidDomainOrIpv4:
        return 'Please Enter a Valid Domain/IPv4 Address';
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
        return "Records Dialog Position Follows Mouse";
      case TranslationKey.current:
        return "Current";
      case TranslationKey.followMousePos:
        return "Follow the mouse position";
      case TranslationKey.rememberLastPos:
        return "Remember last position";
      case TranslationKey.showOnRecentTasks:
        return "Show on recent tasks";
      case TranslationKey.showOnRecentTasksTips:
        return "Hiding recent tasks in higher versions of Android may cause the system to kill the app when switching to other apps. Still want to try hiding?";
      case TranslationKey.showOnRecentTasksDesc:
        return "Hiding the backend on some systems may result in the backend being killed after switching applications（e.g. Xiaomi）, and the current reason is unknown";
      case TranslationKey.showLocalIpAddress:
        return "Show Local IP Address";
      case TranslationKey.localIpAddress:
        return "Local IP Address";
      case TranslationKey.syncAutoCloseSettingTitle:
        return "Screen-off Auto Disconnect";
      case TranslationKey.syncAutoCloseSettingDesc:
        return "For power-saving optimization, the sync connection will be disconnected after about 2~10 minutes of screen-off. To maintain background connection, please do not enable this feature.";
      case TranslationKey.scan:
        return "Scan QRCode";
      case TranslationKey.noCameraPermission:
        return "Please grant camera permission";
      case TranslationKey.qrCodeScannerPageTitle:
        return "Scan QR code";
      case TranslationKey.qrCodeScanError:
        return "It doesn't seem to be the connection QR code for ClipShare, please check";
      case TranslationKey.attemptingToConnect:
        return "Attempting to connect";
      case TranslationKey.forwardServerStatus:
        return "Forward Service Status";
      case TranslationKey.connected:
        return "Connected";
      case TranslationKey.disconnected:
        return "Disconnected";
      case TranslationKey.forwardMode:
        return "Forward Mode";
      case TranslationKey.deviceId:
        return "Device ID";
      case TranslationKey.forwardServerNotConnected:
        return "Not connected to the forward server";
      case TranslationKey.cleanData:
        return "Clean Data";
      case TranslationKey.syncSettingsAutoCopyScreenShotTitle:
        return "Auto Copy ScreenShot";
      case TranslationKey.syncSettingsAutoCopyScreenShotDesc:
        return "Some systems may experience delays in the background";
      case TranslationKey.showMoreItemsInRow:
        return "Display more items in row";
      case TranslationKey.showMoreItemsInRowDesc:
        return "When the width is sufficient, multiple items such as history records and device lists will be displayed on one line";
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
      case TranslationKey.defaultClipboardServerNotificationCfgStopListeningTitle:
        return "Warning";
      case TranslationKey.defaultClipboardServerNotificationCfgStopListeningText:
        return "Clipboard listening stopped";
      case TranslationKey.defaultClipboardServerNotificationCfgRunningTitle:
        return "Service is running";
      case TranslationKey.defaultClipboardServerNotificationCfgShizukuRunningText:
        return "Shizuku mode is active";
      case TranslationKey.defaultClipboardServerNotificationCfgRootRunningText:
        return "Root mode is active";
      case TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedTitle:
        return "Error";
      case TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedText:
        return "Shizuku service has been disconnected";
      case TranslationKey.defaultClipboardServerNotificationCfgWaitingRunningTitle:
        return "Waiting to Running";
      case TranslationKey.defaultClipboardServerNotificationCfgWaitingRunningText:
        return "Waiting to Running Service";
      case TranslationKey.startSendFileToast:
        return "The file has started sending, please check the sending progress";
      case TranslationKey.folder:
        return "Folder";
      case TranslationKey.removeFromPendingList:
        return "Remove from the sending list";
      case TranslationKey.onlineDevices:
        return "Online devices";
      case TranslationKey.noOnlineDevices:
        return "No online devices";
      case TranslationKey.pendingFiles:
        return "Pending files";
      case TranslationKey.clearPendingFiles:
        return "Clear pending list";
      case TranslationKey.pendingFileLen:
        return "Total of @len files";
      case TranslationKey.addFilesFromSystem:
        return "Add files from the system";
      case TranslationKey.viewPendingFiles:
        return "View pending files";
      case TranslationKey.sendFiles:
        return "Send files";
      case TranslationKey.unWriteablePathTips:
        return "The selected location cannot be written, please select again";
      case TranslationKey.clipboardListeningWay:
        return "Clipboard Listening Way";
      case TranslationKey.clipboardListeningWayTips:
        return "Tips";
      case TranslationKey.clipboardListeningWithSystemHiddenApi:
        return "Hidden API";
      case TranslationKey.clipboardListeningWithSystemLogs:
        return "System Logs";
      case TranslationKey.clipboardListeningWayTipsDetail:
        return "Provide two listening modes, but not both are compatible with your device. The default is to use the system's logs for listening, but not all are applicable. It may be found to be invalid on some devices. \n\nFor example, system log monitoring may not work on OriginOS. Please enable it according to the actual situation";
      case TranslationKey.clipboardListeningWayToggleConfirmContent:
        return "Are you sure to switch to monitoring mode? \n\nWill switch to @way";
      case TranslationKey.closeOnSameHotKeyTitle:
        return "Close the pop-up window using the same shortcut key";
      case TranslationKey.closeOnSameHotKeyDesc:
        return "The default mouse click on the form close button allows you to use the same shortcut keys to open and close pop ups when enabled";
      case TranslationKey.saveToAlbum:
        return "Save to album";
      case TranslationKey.openWithOtherApplications:
        return "Open With Other Applications";
      case TranslationKey.enableAutoSyncOnScreenOpenedTitle:
        return "Device detected when screen lights up";
      case TranslationKey.enableAutoSyncOnScreenOpenedDesc:
        return "When the screen lights up, it will scan the network to discover devices. If the option to disconnect from the network after turning off the screen is enabled, the device may not automatically connect after switching to the network when the screen is turned off";
      case TranslationKey.deviceDiscoveryStatusViaPaired:
        return "Connecting paired devices";
      case TranslationKey.export2Excel:
        return "Export to Excel";
      case TranslationKey.export2ExcelFileName:
        return "HistoryRecordsExport.xlsx";
      case TranslationKey.historyOutputTips:
        return "Export with current filters?\n\n(Excludes file sync records)";
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
      case TranslationKey.clipboardSettingsGroupName:
        return "Clipboard";
      case TranslationKey.clipboardSettingsSourceRecordTitle:
        return "Record clipboard content source";
      case TranslationKey.clipboardSettingsSourceRecordAndroidDesc:
        return "Accessibility services need to be enabled to assist with recording";
      case TranslationKey.permissionSettingsAccessibilityTitle:
        return "Accessibility";
      case TranslationKey.permissionSettingsAccessibilityDesc:
        return "Enable accessibility permission to assist in recording clipboard sources";
      case TranslationKey.noAccessibilityPermTips:
        return "Accessibility service is not enabled. Unable to detect the source of user-initiated copies. Would you like to grant accessibility permission?";
      case TranslationKey.appIconLoadError:
        return "Failed to load app icon (@appName)";
      case TranslationKey.clipboardSettingsSourceRecordTitleTooltip:
        return "Tips";
      case TranslationKey.clipboardSettingsSourceRecordTitleTooltipDialogContent:
        return "Source detection is divided into two types: foreground copying and background copying from other apps. Foreground copying requires accessibility permissions to detect, while background copying can be obtained via dumpsys (with a delay of several hundred milliseconds).\n\nSource detection cannot guarantee complete accuracy, as it mainly relies on accessibility recognition and may mistakenly tag other apps.";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitle:
        return "Record background copy source via dumpsys";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltip:
        return "Description";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysTitleTooltipDialogContent:
        return "Background copying may be misidentified. Using dumpsys to detect which app wrote to clipboard for correction";
      case TranslationKey.clipboardSettingsSourceRecordViaDumpsysAndroidDesc:
        return "Requires Root or Shizuku permissions, with several hundred milliseconds of delay";
      case TranslationKey.source:
        return "Source";
      case TranslationKey.clearSourceConfirmText:
        return "Are you sure you want to clear the source information of this record?";
      case TranslationKey.clearSuccess:
        return "Cleared successfully";
      case TranslationKey.clearFailed:
        return "Failed to clear";
      case TranslationKey.selectApplication:
        return "Select Applications";
      case TranslationKey.preferenceSettingsDevDisconnNotification:
        return "System notification when device disconnection";
      case TranslationKey.notification:
        return "Notification";
      case TranslationKey.aboutPageDatabaseVersionItemName:
        return "Database version";
      case TranslationKey.newVersionAvailable:
        return "New version available";
      case TranslationKey.showMainWindow:
        return "Main Window";
      case TranslationKey.exitApp:
        return "Exit";
      case TranslationKey.exitAppViaHotKey:
        return "Exiting ${Constants.appName} via hotkey";
      case TranslationKey.clearHotKeyConfirm:
        return "Are you sure you want to clear this shortcut key?";
      case TranslationKey.pleaseEnterHotKey:
        return "Please enter hotkey";
      case TranslationKey.userApp:
        return 'User';
      case TranslationKey.systemApp:
        return 'System';
    }
  }
}
