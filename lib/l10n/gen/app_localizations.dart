import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// translated key: unitWord
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get unitWord;

  /// translated key: dialogCancelText
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancelText;

  /// translated key: dialogAuthorizationButtonText
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get dialogAuthorizationButtonText;

  /// translated key: floatPermRequestDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Request Floating Window Permission'**
  String get floatPermRequestDialogTitle;

  /// translated key: floatPermRequestDialogContent
  ///
  /// In en, this message translates to:
  /// **'Because Android 10+ blocks background clipboard access, the app reads clipboard changes indirectly through system logs and floating window access.\n\nTap OK to open the floating window permission page.'**
  String get floatPermRequestDialogContent;

  /// translated key: requiredPermDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Required Permission Missing'**
  String get requiredPermDialogTitle;

  /// translated key: floatPermMissingDialogContent
  ///
  /// In en, this message translates to:
  /// **'Grant floating window access, or the clipboard cannot be read in the background.'**
  String get floatPermMissingDialogContent;

  /// translated key: shizukuPermRequestDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Shizuku Permission Request'**
  String get shizukuPermRequestDialogTitle;

  /// translated key: shizukuPermRequestDialogContent
  ///
  /// In en, this message translates to:
  /// **'Due to restrictions on Android 10 and above, Shizuku is required to read the clipboard in the background. Otherwise, the app can only passively receive clipboard data and cannot automatically sync.'**
  String get shizukuPermRequestDialogContent;

  /// translated key: dontShowAgain
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t Show Again'**
  String get dontShowAgain;

  /// translated key: dontShowAgainConfirm
  ///
  /// In en, this message translates to:
  /// **'Confirm Don\'\'t Show Again?'**
  String get dontShowAgainConfirm;

  /// translated key: notificationPermRequestDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Request Notification Permission'**
  String get notificationPermRequestDialogTitle;

  /// translated key: notificationPermRequestDialogContent
  ///
  /// In en, this message translates to:
  /// **'Used to send system notifications.'**
  String get notificationPermRequestDialogContent;

  /// translated key: batteryOptimization
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// translated key: batteryOptimizationPermRequestDialogContent
  ///
  /// In en, this message translates to:
  /// **'Turn off battery optimization to improve background keep-alive.\nIf tapping [Grant Access] does not respond, open the setting manually in your phone settings.'**
  String get batteryOptimizationPermRequestDialogContent;

  /// translated key: selectWorkMode
  ///
  /// In en, this message translates to:
  /// **'Select Work Mode'**
  String get selectWorkMode;

  /// translated key: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// translated key: completedGuideDesc
  ///
  /// In en, this message translates to:
  /// **'Setup complete.'**
  String get completedGuideDesc;

  /// translated key: floatPermGuideTitle
  ///
  /// In en, this message translates to:
  /// **'Floating Window Permission'**
  String get floatPermGuideTitle;

  /// translated key: floatPermGuideDesc
  ///
  /// In en, this message translates to:
  /// **'On newer Android versions, {appName} needs floating window access to read the clipboard in the background. After enabling it, you can open clipboard history from the screen edge and drag to select items.'**
  String floatPermGuideDesc(String appName);

  /// translated key: notificationPermGuideTitle
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermGuideTitle;

  /// translated key: notificationPermGuideDesc
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to start the foreground service.'**
  String get notificationPermGuideDesc;

  /// translated key: storagePermGuideTitle
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storagePermGuideTitle;

  /// translated key: storagePermGuideDesc
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to sync images and files, otherwise files cannot be saved.'**
  String get storagePermGuideDesc;

  /// translated key: batteryOptimizationPermGuideDesc
  ///
  /// In en, this message translates to:
  /// **'To improve background keep-alive, exclude the app from battery optimization.\nAlso lock it in recent tasks and allow auto-start in your phone manager.\nIf tapping [Grant Access] does not respond, open the setting manually in your phone settings.'**
  String get batteryOptimizationPermGuideDesc;

  /// translated key: aboutPageInstructionsItemName
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get aboutPageInstructionsItemName;

  /// translated key: aboutPageJoinQQGroupItemName
  ///
  /// In en, this message translates to:
  /// **'Join QQ Group'**
  String get aboutPageJoinQQGroupItemName;

  /// translated key: aboutPageWebsiteItemName
  ///
  /// In en, this message translates to:
  /// **'Official Website'**
  String get aboutPageWebsiteItemName;

  /// translated key: aboutPageLogsItemName
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get aboutPageLogsItemName;

  /// translated key: aboutPageVersionItemName
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get aboutPageVersionItemName;

  /// translated key: authenticationPageTitle
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authenticationPageTitle;

  /// translated key: authenticationPageBackendTimeoutVerificationTitle
  ///
  /// In en, this message translates to:
  /// **'Timeout Verification'**
  String get authenticationPageBackendTimeoutVerificationTitle;

  /// translated key: authenticationPageUsePassword
  ///
  /// In en, this message translates to:
  /// **'Use Password'**
  String get authenticationPageUsePassword;

  /// translated key: authenticationPageStartVerification
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get authenticationPageStartVerification;

  /// translated key: authenticationPageRequireAuthentication
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authenticationPageRequireAuthentication;

  /// translated key: deviceAdditionFailedDialogText
  ///
  /// In en, this message translates to:
  /// **'Device Addition Failed'**
  String get deviceAdditionFailedDialogText;

  /// translated key: rename
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// translated key: devicePageDisconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get devicePageDisconnect;

  /// translated key: devicePageReconnect
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get devicePageReconnect;

  /// translated key: devicePageUnpairedDialogContent
  ///
  /// In en, this message translates to:
  /// **'Do you want to unpair?'**
  String get devicePageUnpairedDialogContent;

  /// translated key: devicePageUnpairedButtonText
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get devicePageUnpairedButtonText;

  /// translated key: devicePagePairingDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Enter Pairing Code'**
  String get devicePagePairingDialogTitle;

  /// translated key: devicePagePairingTimeoutText
  ///
  /// In en, this message translates to:
  /// **'Pairing timed out!'**
  String get devicePagePairingTimeoutText;

  /// translated key: devicePagePairingErrorText
  ///
  /// In en, this message translates to:
  /// **'Wrong pairing code!'**
  String get devicePagePairingErrorText;

  /// translated key: devicePagePairingDialogConfirmText
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get devicePagePairingDialogConfirmText;

  /// translated key: devicePageMyDevicesText
  ///
  /// In en, this message translates to:
  /// **'My Devices ({length})'**
  String devicePageMyDevicesText(String length);

  /// translated key: devicePageForwardServerText
  ///
  /// In en, this message translates to:
  /// **'Forward Connection'**
  String get devicePageForwardServerText;

  /// translated key: devicePageDiscoverDevicesText
  ///
  /// In en, this message translates to:
  /// **'Discover Devices ({length})'**
  String devicePageDiscoverDevicesText(String length);

  /// translated key: devicePageRediscoverTooltip
  ///
  /// In en, this message translates to:
  /// **'Rediscover'**
  String get devicePageRediscoverTooltip;

  /// translated key: devicePageManuallyTooltip
  ///
  /// In en, this message translates to:
  /// **'Add Device Manually'**
  String get devicePageManuallyTooltip;

  /// translated key: devicePageStopDiscoveringTooltip
  ///
  /// In en, this message translates to:
  /// **'Stop Discovering'**
  String get devicePageStopDiscoveringTooltip;

  /// translated key: sms
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sms;

  /// translated key: homeAppBarSyncingProgressText
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get homeAppBarSyncingProgressText;

  /// translated key: search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// translated key: logPageAppBarTitle
  ///
  /// In en, this message translates to:
  /// **'Log Records'**
  String get logPageAppBarTitle;

  /// translated key: all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// translated key: text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// translated key: image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// translated key: file
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// translated key: moreFilter
  ///
  /// In en, this message translates to:
  /// **'More Filters'**
  String get moreFilter;

  /// translated key: startDate
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// translated key: endDate
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// translated key: filterByDate
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// translated key: filterByContentType
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByContentType;

  /// translated key: filterBySource
  ///
  /// In en, this message translates to:
  /// **'Filter by Source'**
  String get filterBySource;

  /// translated key: saveTopData
  ///
  /// In en, this message translates to:
  /// **'Keep Pinned Data'**
  String get saveTopData;

  /// translated key: removeLocalFiles
  ///
  /// In en, this message translates to:
  /// **'Remove local files'**
  String get removeLocalFiles;

  /// translated key: saveFilterConfig
  ///
  /// In en, this message translates to:
  /// **'Save Filter Preset'**
  String get saveFilterConfig;

  /// translated key: saveAutoCleanConfig
  ///
  /// In en, this message translates to:
  /// **'Save Auto-clean Settings'**
  String get saveAutoCleanConfig;

  /// translated key: noDataFromFilter
  ///
  /// In en, this message translates to:
  /// **'No data matched the filter'**
  String get noDataFromFilter;

  /// translated key: filterCleaningConfirmation
  ///
  /// In en, this message translates to:
  /// **'{cnt} items found. This cannot be undone.\nContinue?'**
  String filterCleaningConfirmation(String cnt);

  /// translated key: syncRecordsCleaningConfirmation
  ///
  /// In en, this message translates to:
  /// **'Clearing device sync records will resync data after the next connection.'**
  String get syncRecordsCleaningConfirmation;

  /// translated key: onlyNotSync
  ///
  /// In en, this message translates to:
  /// **'Only Unsynced'**
  String get onlyNotSync;

  /// translated key: syncRecordsCleanBtn
  ///
  /// In en, this message translates to:
  /// **'Clear Selected Sync Records'**
  String get syncRecordsCleanBtn;

  /// translated key: optionRecordsCleaningConfirmation
  ///
  /// In en, this message translates to:
  /// **'Clearing device operation records will stop unsynced data from auto-syncing again.'**
  String get optionRecordsCleaningConfirmation;

  /// translated key: optionRecordsCleanBtn
  ///
  /// In en, this message translates to:
  /// **'Clear Selected Operation Records'**
  String get optionRecordsCleanBtn;

  /// translated key: autoCleanFrequency
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get autoCleanFrequency;

  /// translated key: execTime
  ///
  /// In en, this message translates to:
  /// **'Run time'**
  String get execTime;

  /// translated key: nextExecTime
  ///
  /// In en, this message translates to:
  /// **'Next cleaning time: '**
  String get nextExecTime;

  /// translated key: errorCronTips
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Unix cron expression'**
  String get errorCronTips;

  /// translated key: filterTips
  ///
  /// In en, this message translates to:
  /// **'If a filter is left empty, all options are included.\nThe date range is not saved in filter presets.'**
  String get filterTips;

  /// translated key: autoCleanConfigTitle
  ///
  /// In en, this message translates to:
  /// **'Auto-clean'**
  String get autoCleanConfigTitle;

  /// translated key: daily
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// translated key: weekly
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// translated key: selectWeekDay
  ///
  /// In en, this message translates to:
  /// **'Select Weekday'**
  String get selectWeekDay;

  /// translated key: deleteItemsUnit
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get deleteItemsUnit;

  /// translated key: pleaseSelectDevices
  ///
  /// In en, this message translates to:
  /// **'Select devices first'**
  String get pleaseSelectDevices;

  /// translated key: saveSuccess
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saveSuccess;

  /// translated key: pleaseSaveFilterConfig
  ///
  /// In en, this message translates to:
  /// **'Save a filter preset first'**
  String get pleaseSaveFilterConfig;

  /// translated key: saveFailed
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// translated key: updateSuccess
  ///
  /// In en, this message translates to:
  /// **'Updated!'**
  String get updateSuccess;

  /// translated key: updateFailed
  ///
  /// In en, this message translates to:
  /// **'Update failed!'**
  String get updateFailed;

  /// translated key: confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// translated key: toToday
  ///
  /// In en, this message translates to:
  /// **'Go to Today'**
  String get toToday;

  /// translated key: clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// translated key: settingsSearchHint
  ///
  /// In en, this message translates to:
  /// **'Search settings...'**
  String get settingsSearchHint;

  /// translated key: filterByDevice
  ///
  /// In en, this message translates to:
  /// **'Filter by Device'**
  String get filterByDevice;

  /// translated key: filterByTag
  ///
  /// In en, this message translates to:
  /// **'Filter by Tag'**
  String get filterByTag;

  /// translated key: envStatusLoadingText
  ///
  /// In en, this message translates to:
  /// **'Loading environment status...'**
  String get envStatusLoadingText;

  /// translated key: shizukuModeStatusTitle
  ///
  /// In en, this message translates to:
  /// **'Shizuku Mode'**
  String get shizukuModeStatusTitle;

  /// translated key: shizukuModeRunningDesc
  ///
  /// In en, this message translates to:
  /// **'Service is running, API {version}'**
  String shizukuModeRunningDesc(String version);

  /// translated key: rootModeStatusTitle
  ///
  /// In en, this message translates to:
  /// **'Root Mode'**
  String get rootModeStatusTitle;

  /// translated key: rootModeRunningDesc
  ///
  /// In en, this message translates to:
  /// **'Authorized. Service is running.'**
  String get rootModeRunningDesc;

  /// translated key: serverNotRunningDesc
  ///
  /// In en, this message translates to:
  /// **'Service is not running. Some features are unavailable.'**
  String get serverNotRunningDesc;

  /// translated key: envPermissionIgnored
  ///
  /// In en, this message translates to:
  /// **'Permission Ignored'**
  String get envPermissionIgnored;

  /// translated key: envPermissionIgnoredDesc
  ///
  /// In en, this message translates to:
  /// **'Some features may be unavailable'**
  String get envPermissionIgnoredDesc;

  /// translated key: noSpecialPermissionRequired
  ///
  /// In en, this message translates to:
  /// **'No Special Permission Required'**
  String get noSpecialPermissionRequired;

  /// translated key: switchWorkingMode
  ///
  /// In en, this message translates to:
  /// **'Switch Working Mode'**
  String get switchWorkingMode;

  /// translated key: commonSettingsRunAtStartup
  ///
  /// In en, this message translates to:
  /// **'Run at Startup'**
  String get commonSettingsRunAtStartup;

  /// translated key: commonSettingsRunMinimize
  ///
  /// In en, this message translates to:
  /// **'Start Minimized'**
  String get commonSettingsRunMinimize;

  /// translated key: floatWindow
  ///
  /// In en, this message translates to:
  /// **'Floating Window'**
  String get floatWindow;

  /// translated key: commonSettingsShowHistoriesFloatWindow
  ///
  /// In en, this message translates to:
  /// **'Show History Panel'**
  String get commonSettingsShowHistoriesFloatWindow;

  /// translated key: commonSettingsShowHistoriesFloatWindowTips
  ///
  /// In en, this message translates to:
  /// **'Double-tap or drag the handle left to open the history panel.'**
  String get commonSettingsShowHistoriesFloatWindowTips;

  /// translated key: historyFloatTitle
  ///
  /// In en, this message translates to:
  /// **'Clipboard History'**
  String get historyFloatTitle;

  /// translated key: historyFloatCountTemplate
  ///
  /// In en, this message translates to:
  /// **'\'{count}\' records'**
  String get historyFloatCountTemplate;

  /// translated key: historyFloatImageUnavailable
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get historyFloatImageUnavailable;

  /// translated key: commonSettingsHistoriesFloatWindowHandleWidthValue
  ///
  /// In en, this message translates to:
  /// **'Handle Width: {width}'**
  String commonSettingsHistoriesFloatWindowHandleWidthValue(String width);

  /// translated key: commonSettingsHistoriesFloatWindowHandleColor
  ///
  /// In en, this message translates to:
  /// **'Handle Color'**
  String get commonSettingsHistoriesFloatWindowHandleColor;

  /// translated key: commonSettingsHistoriesFloatWindowHandleColorTips
  ///
  /// In en, this message translates to:
  /// **'Pick a floating window color. Changes sync in real time.'**
  String get commonSettingsHistoriesFloatWindowHandleColorTips;

  /// translated key: commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle
  ///
  /// In en, this message translates to:
  /// **'Apply alpha to whole handle'**
  String get commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandle;

  /// translated key: commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips
  ///
  /// In en, this message translates to:
  /// **'When enabled, the handle border, grip, and inner overlay follow the selected color alpha together.'**
  String get commonSettingsHistoriesFloatWindowHandleAlphaToWholeHandleTips;

  /// translated key: commonSettingsEnhanceBackgroundKeepAliveTitle
  ///
  /// In en, this message translates to:
  /// **'Boost Background Keep-alive'**
  String get commonSettingsEnhanceBackgroundKeepAliveTitle;

  /// translated key: commonSettingsEnhanceBackgroundKeepAliveDesc
  ///
  /// In en, this message translates to:
  /// **'Show a 1 px floating window to improve background keep-alive on some devices.'**
  String get commonSettingsEnhanceBackgroundKeepAliveDesc;

  /// translated key: commonSettingsLockHistoriesFloatWindowPosition
  ///
  /// In en, this message translates to:
  /// **'Lock Floating Window Position'**
  String get commonSettingsLockHistoriesFloatWindowPosition;

  /// translated key: preferenceSettingsRememberWindowSize
  ///
  /// In en, this message translates to:
  /// **'Remember Last Window Size'**
  String get preferenceSettingsRememberWindowSize;

  /// translated key: preferenceSettingsWindowSizeRecordValue
  ///
  /// In en, this message translates to:
  /// **'Recorded Value'**
  String get preferenceSettingsWindowSizeRecordValue;

  /// translated key: preferenceSettingsWindowSizeDefaultValue
  ///
  /// In en, this message translates to:
  /// **'Default Value'**
  String get preferenceSettingsWindowSizeDefaultValue;

  /// translated key: commonSettingsTheme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get commonSettingsTheme;

  /// translated key: language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// translated key: selectLanguage
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// translated key: themeAuto
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get themeAuto;

  /// translated key: themeLight
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// translated key: themeDark
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// translated key: permissionSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionSettingsGroupName;

  /// translated key: permissionSettingsNotificationTitle
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get permissionSettingsNotificationTitle;

  /// translated key: permissionSettingsNotificationDesc
  ///
  /// In en, this message translates to:
  /// **'Required to start the foreground service.'**
  String get permissionSettingsNotificationDesc;

  /// translated key: permissionSettingsFloatTitle
  ///
  /// In en, this message translates to:
  /// **'Floating Window Permission'**
  String get permissionSettingsFloatTitle;

  /// translated key: permissionSettingsFloatDesc
  ///
  /// In en, this message translates to:
  /// **'Used on newer Android versions to read the clipboard through a floating window.'**
  String get permissionSettingsFloatDesc;

  /// translated key: permissionSettingsBatteryOptimiseTitle
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get permissionSettingsBatteryOptimiseTitle;

  /// translated key: permissionSettingsBatteryOptimiseDesc
  ///
  /// In en, this message translates to:
  /// **'Exclude the app from battery optimization to reduce background kills.'**
  String get permissionSettingsBatteryOptimiseDesc;

  /// translated key: permissionSettingsSmsTitle
  ///
  /// In en, this message translates to:
  /// **'SMS Access'**
  String get permissionSettingsSmsTitle;

  /// translated key: permissionSettingsSmsDesc
  ///
  /// In en, this message translates to:
  /// **'SMS sync is enabled. Please grant SMS access.'**
  String get permissionSettingsSmsDesc;

  /// translated key: discoveringSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discoveringSettingsGroupName;

  /// translated key: discoveringSettingsLocalDeviceName
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get discoveringSettingsLocalDeviceName;

  /// translated key: discoveringSettingsDeviceNameCopyTip
  ///
  /// In en, this message translates to:
  /// **'Device ID copied'**
  String get discoveringSettingsDeviceNameCopyTip;

  /// translated key: copyDeviceId
  ///
  /// In en, this message translates to:
  /// **'Copy Device ID'**
  String get copyDeviceId;

  /// translated key: modifyDeviceName
  ///
  /// In en, this message translates to:
  /// **'Rename Device'**
  String get modifyDeviceName;

  /// translated key: deviceName
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// translated key: modifyDeviceNameCompletedTooltip
  ///
  /// In en, this message translates to:
  /// **'Restart to apply changes'**
  String get modifyDeviceNameCompletedTooltip;

  /// translated key: port
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// translated key: discoveringSettingsPortDesc
  ///
  /// In en, this message translates to:
  /// **'Default: {port}. Changing it may break auto-discovery.'**
  String discoveringSettingsPortDesc(String port);

  /// translated key: modifyPort
  ///
  /// In en, this message translates to:
  /// **'Change Port'**
  String get modifyPort;

  /// translated key: modifyPortErrorText
  ///
  /// In en, this message translates to:
  /// **'Port number range 0-65535'**
  String get modifyPortErrorText;

  /// translated key: discoveringSettingsModifyPortCompletedTooltip
  ///
  /// In en, this message translates to:
  /// **'Restart to apply changes'**
  String get discoveringSettingsModifyPortCompletedTooltip;

  /// translated key: allowDiscovering
  ///
  /// In en, this message translates to:
  /// **'Discoverable'**
  String get allowDiscovering;

  /// translated key: discoveringSettingsAllowDiscoveringDesc
  ///
  /// In en, this message translates to:
  /// **'Can be automatically discovered by other devices'**
  String get discoveringSettingsAllowDiscoveringDesc;

  /// translated key: discoveringSettingsOnlyForwardDiscoveringTitle
  ///
  /// In en, this message translates to:
  /// **'Forward-only Discovery (Debug)'**
  String get discoveringSettingsOnlyForwardDiscoveringTitle;

  /// translated key: discoveringSettingsOnlyForwardDiscoveringDesc
  ///
  /// In en, this message translates to:
  /// **'Visible only in development builds'**
  String get discoveringSettingsOnlyForwardDiscoveringDesc;

  /// translated key: discoveringSettingsHeartbeatIntervalTitle
  ///
  /// In en, this message translates to:
  /// **'Heartbeat Interval'**
  String get discoveringSettingsHeartbeatIntervalTitle;

  /// translated key: discoveringSettingsHeartbeatIntervalDesc
  ///
  /// In en, this message translates to:
  /// **'Device online check. Default: 30s; 0 disables it.'**
  String get discoveringSettingsHeartbeatIntervalDesc;

  /// translated key: discoveringSettingsHeartbeatIntervalTooltip
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get discoveringSettingsHeartbeatIntervalTooltip;

  /// translated key: enable
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// translated key: dontDetect
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t Detect'**
  String get dontDetect;

  /// translated key: discoveringSettingsHeartbeatIntervalDialogContent
  ///
  /// In en, this message translates to:
  /// **'When a device switches networks, its offline status cannot be detected automatically.\nEnable heartbeat checks to verify device availability at intervals.'**
  String get discoveringSettingsHeartbeatIntervalDialogContent;

  /// translated key: discoveringSettingsModifyHeartbeatDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Heartbeat Interval'**
  String get discoveringSettingsModifyHeartbeatDialogTitle;

  /// translated key: discoveringSettingsModifyHeartbeatDialogInputLabel
  ///
  /// In en, this message translates to:
  /// **'Heartbeat IntervalSeconds. 0 disables it.'**
  String get discoveringSettingsModifyHeartbeatDialogInputLabel;

  /// translated key: forwardSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forwardSettingsGroupName;

  /// translated key: forwardSettingsForwardTitle
  ///
  /// In en, this message translates to:
  /// **'Use Forward Service'**
  String get forwardSettingsForwardTitle;

  /// translated key: forwardSettingsForwardDownloadTooltip
  ///
  /// In en, this message translates to:
  /// **'Download Forward Service'**
  String get forwardSettingsForwardDownloadTooltip;

  /// translated key: forwardSettingsForwardDesc
  ///
  /// In en, this message translates to:
  /// **'Sync over the internet through a forward server.'**
  String get forwardSettingsForwardDesc;

  /// translated key: forwardSettingsForwardEnableRequiredText
  ///
  /// In en, this message translates to:
  /// **'Set the forward server address first.'**
  String get forwardSettingsForwardEnableRequiredText;

  /// translated key: forwardSettingsForwardAddressTitle
  ///
  /// In en, this message translates to:
  /// **'Forward Server Address'**
  String get forwardSettingsForwardAddressTitle;

  /// translated key: forwardSettingsForwardAddressDesc
  ///
  /// In en, this message translates to:
  /// **'Use a trusted server or host your own.'**
  String get forwardSettingsForwardAddressDesc;

  /// translated key: configure
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// translated key: change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// translated key: securitySettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySettingsGroupName;

  /// translated key: securitySettingsEnableSecurityTitle
  ///
  /// In en, this message translates to:
  /// **'Enable Authentication'**
  String get securitySettingsEnableSecurityTitle;

  /// translated key: securitySettingsEnableSecurityDesc
  ///
  /// In en, this message translates to:
  /// **'Use password or biometrics.Please create an app password first'**
  String get securitySettingsEnableSecurityDesc;

  /// translated key: securitySettingsEnableSecurityAppPwdModifyTitle
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get securitySettingsEnableSecurityAppPwdModifyTitle;

  /// translated key: createAppPwd
  ///
  /// In en, this message translates to:
  /// **'Create App Password'**
  String get createAppPwd;

  /// translated key: changeAppPwd
  ///
  /// In en, this message translates to:
  /// **'Change App Password'**
  String get changeAppPwd;

  /// translated key: create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// translated key: securitySettingsReverificationTitle
  ///
  /// In en, this message translates to:
  /// **'Password Recheck'**
  String get securitySettingsReverificationTitle;

  /// translated key: securitySettingsReverificationDesc
  ///
  /// In en, this message translates to:
  /// **'Ask for the password again after the app stays in the background for a while.'**
  String get securitySettingsReverificationDesc;

  /// translated key: securitySettingsReverificationValue
  ///
  /// In en, this message translates to:
  /// **'{value} minutes'**
  String securitySettingsReverificationValue(String value);

  /// translated key: hotKeySettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Hotkeys'**
  String get hotKeySettingsGroupName;

  /// translated key: hotKeySettingsHistoryTitle
  ///
  /// In en, this message translates to:
  /// **'History Popup'**
  String get hotKeySettingsHistoryTitle;

  /// translated key: hotKeySettingsHistoryDesc
  ///
  /// In en, this message translates to:
  /// **'Open the history popup from anywhere on screen'**
  String get hotKeySettingsHistoryDesc;

  /// translated key: hotKeySettingsHistoryTakeOverWinVTooltip
  ///
  /// In en, this message translates to:
  /// **'Win+V is taken over'**
  String get hotKeySettingsHistoryTakeOverWinVTooltip;

  /// translated key: hotKeySettingsCombinationInvalidText
  ///
  /// In en, this message translates to:
  /// **'A hotkey must include one modifier and one non-modifier key.'**
  String get hotKeySettingsCombinationInvalidText;

  /// translated key: hotKeySettingsSaveKeysDialogText
  ///
  /// In en, this message translates to:
  /// **'Save hotkey \"{keys}\"?'**
  String hotKeySettingsSaveKeysDialogText(String keys);

  /// translated key: hotKeySettingsSaveKeysFailedText
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {err}'**
  String hotKeySettingsSaveKeysFailedText(String err);

  /// translated key: sendFile
  ///
  /// In en, this message translates to:
  /// **'Send File'**
  String get sendFile;

  /// translated key: hotKeySettingsFileDesc
  ///
  /// In en, this message translates to:
  /// **'Send selected files to other devices; desktop selection is unsupported'**
  String get hotKeySettingsFileDesc;

  /// translated key: syncSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncSettingsGroupName;

  /// translated key: syncSettingsSmsPermissionRequired
  ///
  /// In en, this message translates to:
  /// **'Grant SMS access first.'**
  String get syncSettingsSmsPermissionRequired;

  /// translated key: syncSettingsStoreImg2PicturesTitle
  ///
  /// In en, this message translates to:
  /// **'Save Images to Pictures'**
  String get syncSettingsStoreImg2PicturesTitle;

  /// translated key: syncSettingsStoreImg2PicturesDesc
  ///
  /// In en, this message translates to:
  /// **'Saved to Pictures/{appName}'**
  String syncSettingsStoreImg2PicturesDesc(String appName);

  /// translated key: syncSettingsStoreImg2PicturesNoPermText
  ///
  /// In en, this message translates to:
  /// **'Storage access required.'**
  String get syncSettingsStoreImg2PicturesNoPermText;

  /// translated key: syncSettingsStoreImg2PicturesCancelPerm
  ///
  /// In en, this message translates to:
  /// **'Permission request canceled.'**
  String get syncSettingsStoreImg2PicturesCancelPerm;

  /// translated key: syncSettingsStoreImagePathTitle
  ///
  /// In en, this message translates to:
  /// **'Image Storage Path'**
  String get syncSettingsStoreImagePathTitle;

  /// translated key: syncSettingsStoreFilePathTitle
  ///
  /// In en, this message translates to:
  /// **'File Storage Path'**
  String get syncSettingsStoreFilePathTitle;

  /// translated key: selection
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selection;

  /// translated key: syncSettingsAutoCopyImgTitle
  ///
  /// In en, this message translates to:
  /// **'Copy Images Automatically'**
  String get syncSettingsAutoCopyImgTitle;

  /// translated key: syncSettingsAutoCopyImgDesc
  ///
  /// In en, this message translates to:
  /// **'When enabled, images copied on other devices are also copied locally.'**
  String get syncSettingsAutoCopyImgDesc;

  /// translated key: logSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logSettingsGroupName;

  /// translated key: logSettingsEnableTitle
  ///
  /// In en, this message translates to:
  /// **'Enable Logging'**
  String get logSettingsEnableTitle;

  /// translated key: logSettingsEnableDesc
  ///
  /// In en, this message translates to:
  /// **'Uses extra storage. Current logs: {size}'**
  String logSettingsEnableDesc(String size);

  /// translated key: openFolder
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// translated key: openFilePos
  ///
  /// In en, this message translates to:
  /// **'Open File Location'**
  String get openFilePos;

  /// translated key: tips
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// translated key: logSettingsDeleteLogFilesDialogContent
  ///
  /// In en, this message translates to:
  /// **'Delete log files?'**
  String get logSettingsDeleteLogFilesDialogContent;

  /// translated key: statisticsSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsSettingsGroupName;

  /// translated key: about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// translated key: errorDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorDialogTitle;

  /// translated key: selfDeviceName
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get selfDeviceName;

  /// translated key: save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// translated key: saved
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// translated key: saveFileNotSupportDialogText
  ///
  /// In en, this message translates to:
  /// **'Unsupported Type'**
  String get saveFileNotSupportDialogText;

  /// translated key: pieDataStatisticsLocalItemLabel
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get pieDataStatisticsLocalItemLabel;

  /// translated key: pieDataStatisticsSyncItemLabel
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get pieDataStatisticsSyncItemLabel;

  /// translated key: statisticsPageAppBarText
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsPageAppBarText;

  /// translated key: statisticsPageFilterRangeText
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get statisticsPageFilterRangeText;

  /// translated key: refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// translated key: statisticsPageHistoryTypeCntTitle
  ///
  /// In en, this message translates to:
  /// **'Record Count by Type'**
  String get statisticsPageHistoryTypeCntTitle;

  /// translated key: statisticsPageSyncRatePie
  ///
  /// In en, this message translates to:
  /// **'Sync Ratio'**
  String get statisticsPageSyncRatePie;

  /// translated key: statisticsPageHistoryCntForDevice
  ///
  /// In en, this message translates to:
  /// **'Record Count by Device'**
  String get statisticsPageHistoryCntForDevice;

  /// translated key: statisticsPageHistoryTagCnt
  ///
  /// In en, this message translates to:
  /// **'Record Count by Tag'**
  String get statisticsPageHistoryTagCnt;

  /// translated key: syncingFilePageHistoryTabText
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get syncingFilePageHistoryTabText;

  /// translated key: syncingFilePageReceiveTabText
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get syncingFilePageReceiveTabText;

  /// translated key: syncingFilePageSendTabText
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get syncingFilePageSendTabText;

  /// translated key: dragFileToSend
  ///
  /// In en, this message translates to:
  /// **'Drag files here to send'**
  String get dragFileToSend;

  /// translated key: deleting
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// translated key: deletingSuccess
  ///
  /// In en, this message translates to:
  /// **'Deleted Successfully'**
  String get deletingSuccess;

  /// translated key: partialDeletionFailed
  ///
  /// In en, this message translates to:
  /// **'Partial Deletion Failed'**
  String get partialDeletionFailed;

  /// translated key: deletionFailed
  ///
  /// In en, this message translates to:
  /// **'Delete Failed'**
  String get deletionFailed;

  /// translated key: deselect
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// translated key: delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// translated key: deleteWithFiles
  ///
  /// In en, this message translates to:
  /// **'Delete with Files'**
  String get deleteWithFiles;

  /// translated key: syncingFilePageDeleteSelectedDialogContent
  ///
  /// In en, this message translates to:
  /// **'Delete {length} selected items?\nFiles from sent records will be kept.'**
  String syncingFilePageDeleteSelectedDialogContent(String length);

  /// translated key: onlyDeleteRecordsText
  ///
  /// In en, this message translates to:
  /// **'Records Only'**
  String get onlyDeleteRecordsText;

  /// translated key: failedToReadUpdateLog
  ///
  /// In en, this message translates to:
  /// **'Failed to Read Update Log!'**
  String get failedToReadUpdateLog;

  /// translated key: skipGuide
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipGuide;

  /// translated key: previousGuide
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousGuide;

  /// translated key: nextGuide
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextGuide;

  /// translated key: finishGuide
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishGuide;

  /// translated key: previewPageNoSuchFile
  ///
  /// In en, this message translates to:
  /// **'Image does not exist or has been deleted'**
  String get previewPageNoSuchFile;

  /// translated key: copyPathSuccess
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get copyPathSuccess;

  /// translated key: tagEditPageAppBarTitle
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get tagEditPageAppBarTitle;

  /// translated key: tagEditPageSearchOrCreateTag
  ///
  /// In en, this message translates to:
  /// **'Search or Create Tag'**
  String get tagEditPageSearchOrCreateTag;

  /// translated key: tagEditPageCrateTagItem
  ///
  /// In en, this message translates to:
  /// **'Create \"{tag}\" Tag'**
  String tagEditPageCrateTagItem(String tag);

  /// translated key: updateLogPageAppBarTitle
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get updateLogPageAppBarTitle;

  /// translated key: failedToReadFile
  ///
  /// In en, this message translates to:
  /// **'Failed to Read File'**
  String get failedToReadFile;

  /// translated key: welcome
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String welcome(String appName);

  /// translated key: welcomeContent
  ///
  /// In en, this message translates to:
  /// **'Before you start, we need a few permissions and some basic setup.'**
  String get welcomeContent;

  /// translated key: startNow
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// translated key: name_
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name_;

  /// translated key: ruleContent
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get ruleContent;

  /// translated key: deleteSuccess
  ///
  /// In en, this message translates to:
  /// **'Deleted Successfully'**
  String get deleteSuccess;

  /// translated key: revoke
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// translated key: importRules
  ///
  /// In en, this message translates to:
  /// **'Import Rules'**
  String get importRules;

  /// translated key: importRulesSuccess
  ///
  /// In en, this message translates to:
  /// **'Imported {length} rules'**
  String importRulesSuccess(String length);

  /// translated key: importFromNet
  ///
  /// In en, this message translates to:
  /// **'Import from Network'**
  String get importFromNet;

  /// translated key: importFromLocal
  ///
  /// In en, this message translates to:
  /// **'Import from Local'**
  String get importFromLocal;

  /// translated key: urlFormatErrorText
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get urlFormatErrorText;

  /// translated key: fetch
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetch;

  /// translated key: fetchingData
  ///
  /// In en, this message translates to:
  /// **'Fetching Data...'**
  String get fetchingData;

  /// translated key: failedToLoad
  ///
  /// In en, this message translates to:
  /// **'Failed to Load'**
  String get failedToLoad;

  /// translated key: noSuchFile
  ///
  /// In en, this message translates to:
  /// **'The selected file path does not exist!'**
  String get noSuchFile;

  /// translated key: addRule
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get addRule;

  /// translated key: importRule
  ///
  /// In en, this message translates to:
  /// **'Import Rule'**
  String get importRule;

  /// translated key: import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// translated key: add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// translated key: modify
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// translated key: output
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get output;

  /// translated key: outputRule
  ///
  /// In en, this message translates to:
  /// **'Export Rule'**
  String get outputRule;

  /// translated key: outputSuccess
  ///
  /// In en, this message translates to:
  /// **'Exported Successfully!'**
  String get outputSuccess;

  /// translated key: outputFailed
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get outputFailed;

  /// translated key: exitSelectionMode
  ///
  /// In en, this message translates to:
  /// **'Exit Selection Mode'**
  String get exitSelectionMode;

  /// translated key: selectAll
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// translated key: cancelSelectAll
  ///
  /// In en, this message translates to:
  /// **'Cancel Select All'**
  String get cancelSelectAll;

  /// translated key: multipleChoiceOperationAppBarTitle
  ///
  /// In en, this message translates to:
  /// **'Bulk Actions'**
  String get multipleChoiceOperationAppBarTitle;

  /// translated key: forwardServerNotAllowedSendFile
  ///
  /// In en, this message translates to:
  /// **'This forward server does not allow file sync.'**
  String get forwardServerNotAllowedSendFile;

  /// translated key: sendFailed
  ///
  /// In en, this message translates to:
  /// **'Send Failed'**
  String get sendFailed;

  /// translated key: forwardServerUnknownResult
  ///
  /// In en, this message translates to:
  /// **'Unknown Result'**
  String get forwardServerUnknownResult;

  /// translated key: forwardServerConnectFailed
  ///
  /// In en, this message translates to:
  /// **'Forward Server Connection Failed'**
  String get forwardServerConnectFailed;

  /// translated key: devicePairingRequestNotificationContent
  ///
  /// In en, this message translates to:
  /// **'New Pairing Request'**
  String get devicePairingRequestNotificationContent;

  /// translated key: devicePairingRequestDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Pairing Request'**
  String get devicePairingRequestDialogTitle;

  /// translated key: pairingCodeDialogContent
  ///
  /// In en, this message translates to:
  /// **'Pairing request from {devName}\nCode:'**
  String pairingCodeDialogContent(String devName);

  /// translated key: cancelCurrentPairing
  ///
  /// In en, this message translates to:
  /// **'Cancel This Pairing'**
  String get cancelCurrentPairing;

  /// translated key: deviceDiscoveryStatusViaBroadcast
  ///
  /// In en, this message translates to:
  /// **'Broadcast Discovery'**
  String get deviceDiscoveryStatusViaBroadcast;

  /// translated key: deviceDiscoveryStatusViaScan
  ///
  /// In en, this message translates to:
  /// **'Network Scan'**
  String get deviceDiscoveryStatusViaScan;

  /// translated key: deviceDiscoveryStatusViaForward
  ///
  /// In en, this message translates to:
  /// **'Forward Discovery'**
  String get deviceDiscoveryStatusViaForward;

  /// translated key: newVersionDialogTitle
  ///
  /// In en, this message translates to:
  /// **'New Version'**
  String get newVersionDialogTitle;

  /// translated key: newVersionDialogSkipText
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get newVersionDialogSkipText;

  /// translated key: newVersionDialogOkText
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get newVersionDialogOkText;

  /// translated key: defaultLinkTagName
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get defaultLinkTagName;

  /// translated key: unknownHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownHistoryContentType;

  /// translated key: allHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allHistoryContentType;

  /// translated key: textHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textHistoryContentType;

  /// translated key: imageHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageHistoryContentType;

  /// translated key: richTextHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'Rich Text'**
  String get richTextHistoryContentType;

  /// translated key: smsHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get smsHistoryContentType;

  /// translated key: fileHistoryContentType
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileHistoryContentType;

  /// translated key: dialogConfirmText
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirmText;

  /// translated key: dialogNeutralText
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get dialogNeutralText;

  /// translated key: dialogRestoreDefaultText
  ///
  /// In en, this message translates to:
  /// **'Restore Default'**
  String get dialogRestoreDefaultText;

  /// translated key: open
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// translated key: openLink
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// translated key: moment
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get moment;

  /// translated key: minutesAgo
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// translated key: hoursAgo
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// translated key: connectFailed
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectFailed;

  /// translated key: connectSuccess
  ///
  /// In en, this message translates to:
  /// **'Connection Successful'**
  String get connectSuccess;

  /// translated key: connect
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// translated key: addDeviceDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDeviceDialogTitle;

  /// translated key: errorFormatIp
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid IPv4/v6 address'**
  String get errorFormatIp;

  /// translated key: inputPassword
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get inputPassword;

  /// translated key: inputAgain
  ///
  /// In en, this message translates to:
  /// **'Enter Again'**
  String get inputAgain;

  /// translated key: inputErrorAndAgain
  ///
  /// In en, this message translates to:
  /// **'Incorrect input. Try again.'**
  String get inputErrorAndAgain;

  /// translated key: immediately
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// translated key: minute
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// translated key: alreadyNewestAppVersion
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get alreadyNewestAppVersion;

  /// translated key: checkUpdate
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkUpdate;

  /// translated key: topUp
  ///
  /// In en, this message translates to:
  /// **'Pin to Top'**
  String get topUp;

  /// translated key: cancelTopUp
  ///
  /// In en, this message translates to:
  /// **'Unpin from Top'**
  String get cancelTopUp;

  /// translated key: copyContent
  ///
  /// In en, this message translates to:
  /// **'Copy Content'**
  String get copyContent;

  /// translated key: copyMergedContent
  ///
  /// In en, this message translates to:
  /// **'Copy Merged Content'**
  String get copyMergedContent;

  /// translated key: syncRecord
  ///
  /// In en, this message translates to:
  /// **'Sync Record'**
  String get syncRecord;

  /// translated key: resyncRecord
  ///
  /// In en, this message translates to:
  /// **'Sync Again'**
  String get resyncRecord;

  /// translated key: openFile
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// translated key: openFileFolder
  ///
  /// In en, this message translates to:
  /// **'Open File Folder'**
  String get openFileFolder;

  /// translated key: tagsManagement
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsManagement;

  /// translated key: copySuccess
  ///
  /// In en, this message translates to:
  /// **'Copied Successfully'**
  String get copySuccess;

  /// translated key: copyFailed
  ///
  /// In en, this message translates to:
  /// **'Copied Failed'**
  String get copyFailed;

  /// translated key: clipboardContent
  ///
  /// In en, this message translates to:
  /// **'Clipboard Details'**
  String get clipboardContent;

  /// translated key: deleteRecord
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// translated key: multiDeleteAsk
  ///
  /// In en, this message translates to:
  /// **'Delete selected {length} items?'**
  String multiDeleteAsk(String length);

  /// translated key: deleteCompleted
  ///
  /// In en, this message translates to:
  /// **'Delete Completed'**
  String get deleteCompleted;

  /// translated key: shareFile
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get shareFile;

  /// translated key: deleteTips
  ///
  /// In en, this message translates to:
  /// **'Delete Tips'**
  String get deleteTips;

  /// translated key: clipListDeleteRecordDialogContent
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get clipListDeleteRecordDialogContent;

  /// translated key: backToTop
  ///
  /// In en, this message translates to:
  /// **'Back to Top'**
  String get backToTop;

  /// translated key: fold
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get fold;

  /// translated key: unfold
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get unfold;

  /// translated key: clipboard
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboard;

  /// translated key: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// translated key: tag
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// translated key: pleaseInput
  ///
  /// In en, this message translates to:
  /// **'Please Enter'**
  String get pleaseInput;

  /// translated key: forward
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// translated key: notCompatible
  ///
  /// In en, this message translates to:
  /// **'Version Incompatible'**
  String get notCompatible;

  /// translated key: notCompatibleDialogText
  ///
  /// In en, this message translates to:
  /// **'Incompatible with the device\'\'s software version, device connection and data sync may not work properly.\nMinimum version required is {minName}({minCode})\nCurrent software version is {selfName}({selfCode})'**
  String notCompatibleDialogText(
    String minName,
    String minCode,
    String selfName,
    String selfCode,
  );

  /// translated key: emptyData
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get emptyData;

  /// translated key: shizukuMode
  ///
  /// In en, this message translates to:
  /// **'Shizuku Mode'**
  String get shizukuMode;

  /// translated key: shizukuModeDesc
  ///
  /// In en, this message translates to:
  /// **'No Root needed. Requires Shizuku and must be reactivated after a restart.'**
  String get shizukuModeDesc;

  /// translated key: shizukuModeBatteryOptimiseTips
  ///
  /// In en, this message translates to:
  /// **'To keep Shizuku authorized, exclude it from battery optimization and allow it to run in the background.'**
  String get shizukuModeBatteryOptimiseTips;

  /// translated key: shizukuRequestFailedDialogText
  ///
  /// In en, this message translates to:
  /// **'Shizuku request failed. Make sure Shizuku is running and try again.'**
  String get shizukuRequestFailedDialogText;

  /// translated key: requestFailed
  ///
  /// In en, this message translates to:
  /// **'Request Failed'**
  String get requestFailed;

  /// translated key: selectInstallerType
  ///
  /// In en, this message translates to:
  /// **'Select Installer Type'**
  String get selectInstallerType;

  /// translated key: openPathAfterDownload
  ///
  /// In en, this message translates to:
  /// **'Open after download'**
  String get openPathAfterDownload;

  /// translated key: updateFromZipTips
  ///
  /// In en, this message translates to:
  /// **'The portable ZIP also supports auto-updating upon download completion.'**
  String get updateFromZipTips;

  /// translated key: requestSuccess
  ///
  /// In en, this message translates to:
  /// **'Request Success'**
  String get requestSuccess;

  /// translated key: clipboardPermissionRequestFailed
  ///
  /// In en, this message translates to:
  /// **'Requesting clipboard permission requires Shizuku or Root'**
  String get clipboardPermissionRequestFailed;

  /// translated key: rootMode
  ///
  /// In en, this message translates to:
  /// **'Root Mode'**
  String get rootMode;

  /// translated key: rootModeDesc
  ///
  /// In en, this message translates to:
  /// **'Runs with Root. No reactivation needed after a restart.'**
  String get rootModeDesc;

  /// translated key: waitingRequestResult
  ///
  /// In en, this message translates to:
  /// **'Waiting for Request Result'**
  String get waitingRequestResult;

  /// translated key: applyingSettings
  ///
  /// In en, this message translates to:
  /// **'Applying settings...'**
  String get applyingSettings;

  /// translated key: rootRequestFailedDialogText
  ///
  /// In en, this message translates to:
  /// **'Root access was not found. You can use Shizuku mode instead.'**
  String get rootRequestFailedDialogText;

  /// translated key: ignoreMode
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignoreMode;

  /// translated key: ignoreModeDesc
  ///
  /// In en, this message translates to:
  /// **'Clipboard cannot be monitored in the background, only passive sync is available'**
  String get ignoreModeDesc;

  /// translated key: multiChoiceModeSelectedText
  ///
  /// In en, this message translates to:
  /// **'{text} items selected'**
  String multiChoiceModeSelectedText(String text);

  /// translated key: goAuthorize
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get goAuthorize;

  /// translated key: cannotEmpty
  ///
  /// In en, this message translates to:
  /// **'Cannot be empty'**
  String get cannotEmpty;

  /// translated key: ruleCannotEmpty
  ///
  /// In en, this message translates to:
  /// **'Rule cannot be empty'**
  String get ruleCannotEmpty;

  /// translated key: ruleAddDialogLabel
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get ruleAddDialogLabel;

  /// translated key: ruleAddDialogHint
  ///
  /// In en, this message translates to:
  /// **'Please enter a regular expression'**
  String get ruleAddDialogHint;

  /// translated key: validationTesting
  ///
  /// In en, this message translates to:
  /// **'Validation Testing'**
  String get validationTesting;

  /// translated key: validationFailed
  ///
  /// In en, this message translates to:
  /// **'Validation Failed'**
  String get validationFailed;

  /// translated key: verify
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// translated key: stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// translated key: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// translated key: pleaseInputKey
  ///
  /// In en, this message translates to:
  /// **'Please Enter Key'**
  String get pleaseInputKey;

  /// translated key: forwardServerUnlimitedDevices
  ///
  /// In en, this message translates to:
  /// **'No restrictions for whitelist devices'**
  String get forwardServerUnlimitedDevices;

  /// translated key: publicForwardServer
  ///
  /// In en, this message translates to:
  /// **'Public Forward Server'**
  String get publicForwardServer;

  /// translated key: forwardServerSyncFileRateLimit
  ///
  /// In en, this message translates to:
  /// **'File Sync Rate Limit'**
  String get forwardServerSyncFileRateLimit;

  /// translated key: forwardServerCannotSyncFile
  ///
  /// In en, this message translates to:
  /// **'This forward server does not support file sync.'**
  String get forwardServerCannotSyncFile;

  /// translated key: forwardServerNoLimits
  ///
  /// In en, this message translates to:
  /// **'No Restrictions'**
  String get forwardServerNoLimits;

  /// translated key: noLimits
  ///
  /// In en, this message translates to:
  /// **'No Limit'**
  String get noLimits;

  /// translated key: deviceUnit
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get deviceUnit;

  /// translated key: day
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// translated key: hour
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// translated key: second
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get second;

  /// translated key: forwardServerKeyNotStarted
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get forwardServerKeyNotStarted;

  /// translated key: exhausted
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get exhausted;

  /// translated key: forwardServerDeviceConnectionLimit
  ///
  /// In en, this message translates to:
  /// **'Device Connection Limit'**
  String get forwardServerDeviceConnectionLimit;

  /// translated key: forwardServerLifeSpan
  ///
  /// In en, this message translates to:
  /// **'Validity Period'**
  String get forwardServerLifeSpan;

  /// translated key: forwardServerRemainingTime
  ///
  /// In en, this message translates to:
  /// **'Remaining Time'**
  String get forwardServerRemainingTime;

  /// translated key: forwardServerRateLimit
  ///
  /// In en, this message translates to:
  /// **'Rate Limit'**
  String get forwardServerRateLimit;

  /// translated key: forwardServerRemark
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get forwardServerRemark;

  /// translated key: configureForwardServerDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Configure Forward Server'**
  String get configureForwardServerDialogTitle;

  /// translated key: domainAndIp
  ///
  /// In en, this message translates to:
  /// **'Domain / IP'**
  String get domainAndIp;

  /// translated key: host
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// translated key: useKey
  ///
  /// In en, this message translates to:
  /// **'Use Key'**
  String get useKey;

  /// translated key: accessKey
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get accessKey;

  /// translated key: pleaseInputAccessKey
  ///
  /// In en, this message translates to:
  /// **'Please Enter Access Key'**
  String get pleaseInputAccessKey;

  /// translated key: checkConnection
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get checkConnection;

  /// translated key: pleaseInputValidPort
  ///
  /// In en, this message translates to:
  /// **'Please Enter a Valid Port'**
  String get pleaseInputValidPort;

  /// translated key: pleaseInputValidDomainOrIpv4_6
  ///
  /// In en, this message translates to:
  /// **'Please Enter a Valid Domain or IPv4/v6 Address'**
  String get pleaseInputValidDomainOrIpv4_6;

  /// translated key: historyRecord
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get historyRecord;

  /// translated key: myDevice
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get myDevice;

  /// translated key: fileTransfer
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get fileTransfer;

  /// translated key: appSettings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appSettings;

  /// translated key: syncFile
  ///
  /// In en, this message translates to:
  /// **'Sync Files'**
  String get syncFile;

  /// translated key: preference
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get preference;

  /// translated key: preferenceSettingsRecordsDialogLocation
  ///
  /// In en, this message translates to:
  /// **'History Popup Position'**
  String get preferenceSettingsRecordsDialogLocation;

  /// translated key: preferenceSettingsRecordsDialogSize
  ///
  /// In en, this message translates to:
  /// **'Records Dialog Size'**
  String get preferenceSettingsRecordsDialogSize;

  /// translated key: preferenceSettingsAutoClosePopupOnBlurTitle
  ///
  /// In en, this message translates to:
  /// **'Auto-dismiss popups'**
  String get preferenceSettingsAutoClosePopupOnBlurTitle;

  /// translated key: preferenceSettingsAutoClosePopupOnBlurDesc
  ///
  /// In en, this message translates to:
  /// **'Dismisses popups when they lose focus.'**
  String get preferenceSettingsAutoClosePopupOnBlurDesc;

  /// translated key: current
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// translated key: followMousePos
  ///
  /// In en, this message translates to:
  /// **'Follow Cursor'**
  String get followMousePos;

  /// translated key: rememberLastPos
  ///
  /// In en, this message translates to:
  /// **'Remember last position'**
  String get rememberLastPos;

  /// translated key: showOnRecentTasks
  ///
  /// In en, this message translates to:
  /// **'Show in Recent Tasks'**
  String get showOnRecentTasks;

  /// translated key: showOnRecentTasksDesc
  ///
  /// In en, this message translates to:
  /// **'When off, hide the app from recent tasks.'**
  String get showOnRecentTasksDesc;

  /// translated key: showLocalIpAddress
  ///
  /// In en, this message translates to:
  /// **'Show Local IP Address'**
  String get showLocalIpAddress;

  /// translated key: localIpAddress
  ///
  /// In en, this message translates to:
  /// **'Local IP Address'**
  String get localIpAddress;

  /// translated key: syncAutoCloseSettingTitle
  ///
  /// In en, this message translates to:
  /// **'Screen-off Auto Disconnect'**
  String get syncAutoCloseSettingTitle;

  /// translated key: syncAutoCloseSettingDesc
  ///
  /// In en, this message translates to:
  /// **'Disconnect sync after the screen stays off for 2-10 minutes. Leave this off to keep background connections.'**
  String get syncAutoCloseSettingDesc;

  /// translated key: scan
  ///
  /// In en, this message translates to:
  /// **'Scan QRCode'**
  String get scan;

  /// translated key: noCameraPermission
  ///
  /// In en, this message translates to:
  /// **'Please grant camera permission'**
  String get noCameraPermission;

  /// translated key: noPhotoPermission
  ///
  /// In en, this message translates to:
  /// **'Please grant photo permission'**
  String get noPhotoPermission;

  /// translated key: noNotificationPermission
  ///
  /// In en, this message translates to:
  /// **'Please grant notification permission'**
  String get noNotificationPermission;

  /// translated key: permissionSettingsIOSPhotosTitle
  ///
  /// In en, this message translates to:
  /// **'Photo Permission'**
  String get permissionSettingsIOSPhotosTitle;

  /// translated key: permissionSettingsIOSPhotosDesc
  ///
  /// In en, this message translates to:
  /// **'Without this permission, images cannot be saved to Photos.'**
  String get permissionSettingsIOSPhotosDesc;

  /// translated key: qrCodeScannerPageTitle
  ///
  /// In en, this message translates to:
  /// **'Scan to Connect'**
  String get qrCodeScannerPageTitle;

  /// translated key: qrCodeScanError
  ///
  /// In en, this message translates to:
  /// **'This does not look like a ClipShare connection QR code. Please check.'**
  String get qrCodeScanError;

  /// translated key: attemptingToConnect
  ///
  /// In en, this message translates to:
  /// **'Attempting to connect'**
  String get attemptingToConnect;

  /// translated key: forwardServerStatus
  ///
  /// In en, this message translates to:
  /// **'Forward Status'**
  String get forwardServerStatus;

  /// translated key: connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// translated key: disconnected
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// translated key: initializing
  ///
  /// In en, this message translates to:
  /// **'Initializing'**
  String get initializing;

  /// translated key: connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// translated key: forwardMode
  ///
  /// In en, this message translates to:
  /// **'Forward Mode'**
  String get forwardMode;

  /// translated key: deviceId
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// translated key: forwardServerNotConnected
  ///
  /// In en, this message translates to:
  /// **'Not connected to the forward server'**
  String get forwardServerNotConnected;

  /// translated key: cleanData
  ///
  /// In en, this message translates to:
  /// **'Clean Data'**
  String get cleanData;

  /// translated key: syncSettingsAutoCopyScreenShotTitle
  ///
  /// In en, this message translates to:
  /// **'Auto-copy Screenshots'**
  String get syncSettingsAutoCopyScreenShotTitle;

  /// translated key: syncSettingsAutoCopyScreenShotDesc
  ///
  /// In en, this message translates to:
  /// **'Background copy may be delayed on some systems.'**
  String get syncSettingsAutoCopyScreenShotDesc;

  /// translated key: showMoreItemsInRow
  ///
  /// In en, this message translates to:
  /// **'More per Row'**
  String get showMoreItemsInRow;

  /// translated key: showMoreItemsInRowDesc
  ///
  /// In en, this message translates to:
  /// **'Use available width to fit more history & device items per row.'**
  String get showMoreItemsInRowDesc;

  /// translated key: filter
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// translated key: monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// translated key: tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// translated key: wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// translated key: thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// translated key: friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// translated key: saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// translated key: sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// translated key: defaultClipboardServerNotificationCfgErrorTitle
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get defaultClipboardServerNotificationCfgErrorTitle;

  /// translated key: defaultClipboardServerNotificationCfgErrorTextPrefix
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get defaultClipboardServerNotificationCfgErrorTextPrefix;

  /// translated key: defaultClipboardServerNotificationCfgRunningTitle
  ///
  /// In en, this message translates to:
  /// **'Service is runningShizuku mode is active'**
  String get defaultClipboardServerNotificationCfgRunningTitle;

  /// translated key: defaultClipboardServerNotificationCfgRootRunningText
  ///
  /// In en, this message translates to:
  /// **'Root mode is activeError'**
  String get defaultClipboardServerNotificationCfgRootRunningText;

  /// translated key: startSendFileToast
  ///
  /// In en, this message translates to:
  /// **'File transfer started. Check the send progress.'**
  String get startSendFileToast;

  /// translated key: folder
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// translated key: removeFromPendingList
  ///
  /// In en, this message translates to:
  /// **'Remove from pending list'**
  String get removeFromPendingList;

  /// translated key: onlineDevices
  ///
  /// In en, this message translates to:
  /// **'Online devices'**
  String get onlineDevices;

  /// translated key: noOnlineDevices
  ///
  /// In en, this message translates to:
  /// **'No online devices'**
  String get noOnlineDevices;

  /// translated key: pendingFiles
  ///
  /// In en, this message translates to:
  /// **'Pending files'**
  String get pendingFiles;

  /// translated key: clearPendingFiles
  ///
  /// In en, this message translates to:
  /// **'Clear pending list'**
  String get clearPendingFiles;

  /// translated key: pendingFileLen
  ///
  /// In en, this message translates to:
  /// **'{len} files total'**
  String pendingFileLen(String len);

  /// translated key: addFilesFromSystem
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFilesFromSystem;

  /// translated key: viewPendingFiles
  ///
  /// In en, this message translates to:
  /// **'View Pending Files'**
  String get viewPendingFiles;

  /// translated key: sendFiles
  ///
  /// In en, this message translates to:
  /// **'Send Files'**
  String get sendFiles;

  /// translated key: unWriteablePathTips
  ///
  /// In en, this message translates to:
  /// **'The selected location is not writable. Choose another one.'**
  String get unWriteablePathTips;

  /// translated key: clipboardListeningWay
  ///
  /// In en, this message translates to:
  /// **'Clipboard Detection Mode'**
  String get clipboardListeningWay;

  /// translated key: clipboardListeningWayTips
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get clipboardListeningWayTips;

  /// translated key: clipboardListeningWithSystemHiddenApi
  ///
  /// In en, this message translates to:
  /// **'Hidden API'**
  String get clipboardListeningWithSystemHiddenApi;

  /// translated key: clipboardListeningWithSystemLogs
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get clipboardListeningWithSystemLogs;

  /// translated key: clipboardListeningWayTipsDetail
  ///
  /// In en, this message translates to:
  /// **'Two detection modes are available, but your device may not support both. The default uses system logs, which may not work on some devices.\n\nFor example, system log detection does not work on OriginOS. Choose the mode that fits your device.'**
  String get clipboardListeningWayTipsDetail;

  /// translated key: clipboardListeningWayToggleConfirmContent
  ///
  /// In en, this message translates to:
  /// **'Switch detection mode?\n\nNew mode: {way}'**
  String clipboardListeningWayToggleConfirmContent(String way);

  /// translated key: closeOnSameHotKeyTitle
  ///
  /// In en, this message translates to:
  /// **'Hotkey Toggles Popup'**
  String get closeOnSameHotKeyTitle;

  /// translated key: closeOnSameHotKeyDesc
  ///
  /// In en, this message translates to:
  /// **'Use the popup hotkey to both open and close it.'**
  String get closeOnSameHotKeyDesc;

  /// translated key: saveToAlbum
  ///
  /// In en, this message translates to:
  /// **'Save to album'**
  String get saveToAlbum;

  /// translated key: openWithOtherApplications
  ///
  /// In en, this message translates to:
  /// **'Open with Other Apps'**
  String get openWithOtherApplications;

  /// translated key: enableAutoSyncOnScreenOpenedTitle
  ///
  /// In en, this message translates to:
  /// **'Discover Devices on Wake'**
  String get enableAutoSyncOnScreenOpenedTitle;

  /// translated key: enableAutoSyncOnScreenOpenedDesc
  ///
  /// In en, this message translates to:
  /// **'Scan for devices when the screen turns on. If screen-off auto-disconnect is on, network switches while off may not reconnect.'**
  String get enableAutoSyncOnScreenOpenedDesc;

  /// translated key: deviceDiscoveryStatusViaPaired
  ///
  /// In en, this message translates to:
  /// **'Connecting paired devices'**
  String get deviceDiscoveryStatusViaPaired;

  /// translated key: export2Excel
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get export2Excel;

  /// translated key: export2ExcelFileName
  ///
  /// In en, this message translates to:
  /// **'HistoryRecordsExport.xlsx'**
  String get export2ExcelFileName;

  /// translated key: historyOutputTips
  ///
  /// In en, this message translates to:
  /// **'Export using the current filters?\nFile sync records will not be exported.'**
  String get historyOutputTips;

  /// translated key: exporting
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// translated key: modifyContent
  ///
  /// In en, this message translates to:
  /// **'Modify Content'**
  String get modifyContent;

  /// translated key: confirmModifyContent
  ///
  /// In en, this message translates to:
  /// **'Confirm the update content?'**
  String get confirmModifyContent;

  /// translated key: modifyContentConfirmExitAndNoSave
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t save'**
  String get modifyContentConfirmExitAndNoSave;

  /// translated key: unsavedTips
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave this page?'**
  String get unsavedTips;

  /// translated key: done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// translated key: download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// translated key: downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// translated key: devDisconnectNotifyContent
  ///
  /// In en, this message translates to:
  /// **'Device {devName} disconnected'**
  String devDisconnectNotifyContent(String devName);

  /// translated key: devConnectedNotifyContent
  ///
  /// In en, this message translates to:
  /// **'Device {devName} connected'**
  String devConnectedNotifyContent(String devName);

  /// translated key: clipboardSettingsGroupName
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboardSettingsGroupName;

  /// translated key: clipboardSettingsTakeOverWinVTitle
  ///
  /// In en, this message translates to:
  /// **'Take Over Win+V'**
  String get clipboardSettingsTakeOverWinVTitle;

  /// translated key: clipboardSettingsTakeOverWinVDesc
  ///
  /// In en, this message translates to:
  /// **'Use Win+V to open the history popup.'**
  String get clipboardSettingsTakeOverWinVDesc;

  /// translated key: clipboardSettingsTakeOverWinVDialogContent
  ///
  /// In en, this message translates to:
  /// **'Taking over Win+V changes the current user\'\'s system hotkey setting and restarts Explorer so it takes effect immediately. Continue?'**
  String get clipboardSettingsTakeOverWinVDialogContent;

  /// translated key: clipboardSettingsRestoreWinVOnExitTitle
  ///
  /// In en, this message translates to:
  /// **'Restore on App Exit'**
  String get clipboardSettingsRestoreWinVOnExitTitle;

  /// translated key: clipboardSettingsRestoreWinVOnExitDesc
  ///
  /// In en, this message translates to:
  /// **'Automatically restore Win+V when the app exits or is uninstalled.'**
  String get clipboardSettingsRestoreWinVOnExitDesc;

  /// translated key: clipboardSettingsSourceRecordTitle
  ///
  /// In en, this message translates to:
  /// **'Record Clipboard Source'**
  String get clipboardSettingsSourceRecordTitle;

  /// translated key: clipboardSettingsSourceRecordAndroidDesc
  ///
  /// In en, this message translates to:
  /// **'Requires Accessibility to help identify the source.'**
  String get clipboardSettingsSourceRecordAndroidDesc;

  /// translated key: permissionSettingsAccessibilityTitle
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get permissionSettingsAccessibilityTitle;

  /// translated key: permissionSettingsAccessibilityDesc
  ///
  /// In en, this message translates to:
  /// **'Enable this to help detect clipboard sources.'**
  String get permissionSettingsAccessibilityDesc;

  /// translated key: noAccessibilityPermTips
  ///
  /// In en, this message translates to:
  /// **'Accessibility is off, so manual copy sources cannot be detected. Grant Accessibility access now?'**
  String get noAccessibilityPermTips;

  /// translated key: appIconLoadError
  ///
  /// In en, this message translates to:
  /// **'Failed to load app icon ({appName})'**
  String appIconLoadError(String appName);

  /// translated key: clipboardSettingsSourceRecordTitleTooltip
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get clipboardSettingsSourceRecordTitleTooltip;

  /// translated key: clipboardSettingsSourceRecordDialogContent
  ///
  /// In en, this message translates to:
  /// **'Source detection has two cases: foreground copies and background copies from other apps. Foreground copies rely on Accessibility. Background copies can be identified through dumpsys, with a delay of a few hundred milliseconds.\n\nSource detection is not always exact. It mainly depends on Accessibility and may occasionally tag the wrong app.'**
  String get clipboardSettingsSourceRecordDialogContent;

  /// translated key: clipboardSettingsSourceRecordViaDumpsysTitle
  ///
  /// In en, this message translates to:
  /// **'Background Source via dumpsys'**
  String get clipboardSettingsSourceRecordViaDumpsysTitle;

  /// translated key: clipboardSettingsSourceRecordViaDumpsysTitleTooltip
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get clipboardSettingsSourceRecordViaDumpsysTitleTooltip;

  /// translated key: clipboardSettingsSourceRecordViaDumpsysDialogContent
  ///
  /// In en, this message translates to:
  /// **'Background copies may be misidentified. Use dumpsys to check which app wrote to the clipboard and correct the source.'**
  String get clipboardSettingsSourceRecordViaDumpsysDialogContent;

  /// translated key: clipboardSettingsSourceRecordViaDumpsysAndroidDesc
  ///
  /// In en, this message translates to:
  /// **'Requires Root or Shizuku and adds a delay of a few hundred milliseconds.'**
  String get clipboardSettingsSourceRecordViaDumpsysAndroidDesc;

  /// translated key: source
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// translated key: clearSourceConfirmText
  ///
  /// In en, this message translates to:
  /// **'Clear the source info for this record?'**
  String get clearSourceConfirmText;

  /// translated key: clearSuccess
  ///
  /// In en, this message translates to:
  /// **'Cleared successfully'**
  String get clearSuccess;

  /// translated key: clearFailed
  ///
  /// In en, this message translates to:
  /// **'Failed to clear'**
  String get clearFailed;

  /// translated key: selectApplication
  ///
  /// In en, this message translates to:
  /// **'Select App'**
  String get selectApplication;

  /// translated key: preferenceSettingsDevDisconnNotification
  ///
  /// In en, this message translates to:
  /// **'Notify when a device disconnects'**
  String get preferenceSettingsDevDisconnNotification;

  /// translated key: preferenceSettingsDevConnNotification
  ///
  /// In en, this message translates to:
  /// **'Notify when a device connects'**
  String get preferenceSettingsDevConnNotification;

  /// translated key: preferenceSettingsNotifyOnReceivedFile
  ///
  /// In en, this message translates to:
  /// **'Notify after receiving files'**
  String get preferenceSettingsNotifyOnReceivedFile;

  /// translated key: preferenceSettingsNotifyOnReceivedFileDesc
  ///
  /// In en, this message translates to:
  /// **'Click notification to open file'**
  String get preferenceSettingsNotifyOnReceivedFileDesc;

  /// translated key: notification
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// translated key: aboutPageDatabaseVersionItemName
  ///
  /// In en, this message translates to:
  /// **'Database Version'**
  String get aboutPageDatabaseVersionItemName;

  /// translated key: newVersionAvailable
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionAvailable;

  /// translated key: showMainWindow
  ///
  /// In en, this message translates to:
  /// **'Show Main Window'**
  String get showMainWindow;

  /// translated key: exitApp
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitApp;

  /// translated key: exitAppViaHotKey
  ///
  /// In en, this message translates to:
  /// **'Exiting {appName} via hotkey'**
  String exitAppViaHotKey(String appName);

  /// translated key: clearHotKeyConfirm
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear this shortcut key?'**
  String get clearHotKeyConfirm;

  /// translated key: pleaseEnterHotKey
  ///
  /// In en, this message translates to:
  /// **'Press a hotkey'**
  String get pleaseEnterHotKey;

  /// translated key: userApp
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userApp;

  /// translated key: systemApp
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemApp;

  /// translated key: fileNotFound
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// translated key: openingFile
  ///
  /// In en, this message translates to:
  /// **'Opening File'**
  String get openingFile;

  /// translated key: syncData
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// translated key: syncSettingsAutoSyncMissingDataTitle
  ///
  /// In en, this message translates to:
  /// **'Auto-sync Missing Data'**
  String get syncSettingsAutoSyncMissingDataTitle;

  /// translated key: syncSettingsAutoSyncMissingDataDesc
  ///
  /// In en, this message translates to:
  /// **'After a device reconnects, sync data missed while it was offline.'**
  String get syncSettingsAutoSyncMissingDataDesc;

  /// translated key: syncingData
  ///
  /// In en, this message translates to:
  /// **'Syncing data'**
  String get syncingData;

  /// translated key: content
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// translated key: title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// translated key: preferenceSettingsShowMobileNotificationTitle
  ///
  /// In en, this message translates to:
  /// **'Mobile Device Notifications'**
  String get preferenceSettingsShowMobileNotificationTitle;

  /// translated key: preferenceSettingsShowMobileNotificationDesc
  ///
  /// In en, this message translates to:
  /// **'Show connected mobile notifications here. Enable source-device history first.'**
  String get preferenceSettingsShowMobileNotificationDesc;

  /// translated key: permissionSettingsNotificationRecordTitle
  ///
  /// In en, this message translates to:
  /// **'Notification History Access'**
  String get permissionSettingsNotificationRecordTitle;

  /// translated key: permissionSettingsNotificationRecordDesc
  ///
  /// In en, this message translates to:
  /// **'Records notification history. On some devices it may keep the app from fully stopping; revoke it before stopping the app.'**
  String get permissionSettingsNotificationRecordDesc;

  /// translated key: noNotificationRecordPermTips
  ///
  /// In en, this message translates to:
  /// **'Notification History access is missing, so notification history cannot be recorded.'**
  String get noNotificationRecordPermTips;

  /// translated key: recordNotification
  ///
  /// In en, this message translates to:
  /// **'Record Notification History'**
  String get recordNotification;

  /// translated key: logSettingsAutoUploadCrashLogTitle
  ///
  /// In en, this message translates to:
  /// **'Auto-upload Crash Logs'**
  String get logSettingsAutoUploadCrashLogTitle;

  /// translated key: logSettingsAutoUploadCrashLogDesc
  ///
  /// In en, this message translates to:
  /// **'Upload crash logs after an app crash to help developers analyze issues.'**
  String get logSettingsAutoUploadCrashLogDesc;

  /// translated key: logSettingsAutoUploadCrashLogTips
  ///
  /// In en, this message translates to:
  /// **'Uses ACRA to upload only the data needed for analysis, including the crash stack trace. Logs may be uploaded the next time the app starts.'**
  String get logSettingsAutoUploadCrashLogTips;

  /// translated key: backupRestore
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// translated key: backup
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// translated key: restore
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// translated key: backupSettingDesc
  ///
  /// In en, this message translates to:
  /// **'Export a backup file for restoring the database later.'**
  String get backupSettingDesc;

  /// translated key: restoreSettingDesc
  ///
  /// In en, this message translates to:
  /// **'Restore data from a backup file.'**
  String get restoreSettingDesc;

  /// translated key: startUp
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startUp;

  /// translated key: userCancelled
  ///
  /// In en, this message translates to:
  /// **'User cancelled'**
  String get userCancelled;

  /// translated key: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// translated key: exportFailedAndViewLogs
  ///
  /// In en, this message translates to:
  /// **'Export failed, see logs for details'**
  String get exportFailedAndViewLogs;

  /// translated key: exportSuccess
  ///
  /// In en, this message translates to:
  /// **'Export succeeded'**
  String get exportSuccess;

  /// translated key: importing
  ///
  /// In en, this message translates to:
  /// **'Importing'**
  String get importing;

  /// translated key: importFailed
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// translated key: importSuccess
  ///
  /// In en, this message translates to:
  /// **'Import succeeded'**
  String get importSuccess;

  /// translated key: restoreRestartPrompt
  ///
  /// In en, this message translates to:
  /// **'Please restart the app manually to load the latest data and configuration'**
  String get restoreRestartPrompt;

  /// translated key: loading
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// translated key: segmenting
  ///
  /// In en, this message translates to:
  /// **'Segmenting'**
  String get segmenting;

  /// translated key: auto
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// translated key: doubleClick2OpenPath
  ///
  /// In en, this message translates to:
  /// **'Double-click to open path'**
  String get doubleClick2OpenPath;

  /// translated key: editDb
  ///
  /// In en, this message translates to:
  /// **'Edit Database'**
  String get editDb;

  /// translated key: enterSQLHere
  ///
  /// In en, this message translates to:
  /// **'Enter SQL here...'**
  String get enterSQLHere;

  /// translated key: optionalTables
  ///
  /// In en, this message translates to:
  /// **'Optional table names:'**
  String get optionalTables;

  /// translated key: execSQL
  ///
  /// In en, this message translates to:
  /// **'Execute SQL'**
  String get execSQL;

  /// translated key: execSQLNoLimitTips
  ///
  /// In en, this message translates to:
  /// **'This appears to be a SELECT statement without LIMIT clause. Large result sets may cause performance issues. Continue anyway?'**
  String get execSQLNoLimitTips;

  /// translated key: toggleSQLLimitCheck
  ///
  /// In en, this message translates to:
  /// **'Toggle query LIMIT detection'**
  String get toggleSQLLimitCheck;

  /// translated key: result
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// translated key: execFailed
  ///
  /// In en, this message translates to:
  /// **'Execution failed'**
  String get execFailed;

  /// translated key: notificationServerStatus
  ///
  /// In en, this message translates to:
  /// **'Notification Status'**
  String get notificationServerStatus;

  /// translated key: notificationServerTips
  ///
  /// In en, this message translates to:
  /// **'When storage is used as the forward method, devices cannot automatically tell when data needs to be synced.\nA notification service is used to notify devices about changes.\nYou can use either a self-hosted service or a public service.\nNotification messages do not contain sensitive data.'**
  String get notificationServerTips;

  /// translated key: forwardSettingsWebDAVTitle
  ///
  /// In en, this message translates to:
  /// **'WebDAV Settings'**
  String get forwardSettingsWebDAVTitle;

  /// translated key: forwardSettingsS3Title
  ///
  /// In en, this message translates to:
  /// **'S3 Settings'**
  String get forwardSettingsS3Title;

  /// translated key: configureWebDAVServer
  ///
  /// In en, this message translates to:
  /// **'Configure WebDAV'**
  String get configureWebDAVServer;

  /// translated key: webdavServerUrlRequired
  ///
  /// In en, this message translates to:
  /// **'Please enter WebDAV server URL'**
  String get webdavServerUrlRequired;

  /// translated key: webdavUrlMustStartWithHttp
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get webdavUrlMustStartWithHttp;

  /// translated key: usernameRequired
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get usernameRequired;

  /// translated key: passwordRequired
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordRequired;

  /// translated key: baseDirectoryRequired
  ///
  /// In en, this message translates to:
  /// **'Please select base directory'**
  String get baseDirectoryRequired;

  /// translated key: baseDirectoryMustStartWithSlash
  ///
  /// In en, this message translates to:
  /// **'Base directory must start with /'**
  String get baseDirectoryMustStartWithSlash;

  /// translated key: serverUrl
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// translated key: username
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// translated key: password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// translated key: storagePath
  ///
  /// In en, this message translates to:
  /// **'Storage Path'**
  String get storagePath;

  /// translated key: storagePathHint
  ///
  /// In en, this message translates to:
  /// **'Select Storage Path'**
  String get storagePathHint;

  /// translated key: pleaseInputCorrectURL
  ///
  /// In en, this message translates to:
  /// **'Please enter the correct URL'**
  String get pleaseInputCorrectURL;

  /// translated key: nameRequired
  ///
  /// In en, this message translates to:
  /// **'Please enter config name'**
  String get nameRequired;

  /// translated key: configName
  ///
  /// In en, this message translates to:
  /// **'Config Name'**
  String get configName;

  /// translated key: noConfig
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noConfig;

  /// translated key: s3EndpointRequired
  ///
  /// In en, this message translates to:
  /// **'S3 endpoint is required'**
  String get s3EndpointRequired;

  /// translated key: accessKeyRequired
  ///
  /// In en, this message translates to:
  /// **'Access Key is required'**
  String get accessKeyRequired;

  /// translated key: secretKeyRequired
  ///
  /// In en, this message translates to:
  /// **'Secret Key is required'**
  String get secretKeyRequired;

  /// translated key: bucketNameRequired
  ///
  /// In en, this message translates to:
  /// **'Bucket name is required'**
  String get bucketNameRequired;

  /// translated key: configureS3Storage
  ///
  /// In en, this message translates to:
  /// **'Configure S3 Storage'**
  String get configureS3Storage;

  /// translated key: endpoint
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get endpoint;

  /// translated key: s3AccessKey
  ///
  /// In en, this message translates to:
  /// **'Access Key'**
  String get s3AccessKey;

  /// translated key: s3SecretKey
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get s3SecretKey;

  /// translated key: bucketName
  ///
  /// In en, this message translates to:
  /// **'Bucket Name'**
  String get bucketName;

  /// translated key: region
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// translated key: optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// translated key: objectStorageType
  ///
  /// In en, this message translates to:
  /// **'Storage Type'**
  String get objectStorageType;

  /// translated key: standardS3Protocol
  ///
  /// In en, this message translates to:
  /// **'Standard S3 protocol'**
  String get standardS3Protocol;

  /// translated key: aliyunOss
  ///
  /// In en, this message translates to:
  /// **'Alibaba Cloud OSS'**
  String get aliyunOss;

  /// translated key: pleaseInputCorrectDomain
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid domain'**
  String get pleaseInputCorrectDomain;

  /// translated key: notificationServerConfigure
  ///
  /// In en, this message translates to:
  /// **'Notification Server Settings'**
  String get notificationServerConfigure;

  /// translated key: notificationServerAddress
  ///
  /// In en, this message translates to:
  /// **'Notification Server Address'**
  String get notificationServerAddress;

  /// translated key: regionRequired
  ///
  /// In en, this message translates to:
  /// **'Region is required'**
  String get regionRequired;

  /// translated key: pleaseInputCorrectWsURL
  ///
  /// In en, this message translates to:
  /// **'Please enter the correct address (ws:// or wss://)'**
  String get pleaseInputCorrectWsURL;

  /// translated key: selectStoragePath
  ///
  /// In en, this message translates to:
  /// **'Select Storage Path'**
  String get selectStoragePath;

  /// translated key: readonly
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readonly;

  /// translated key: version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// translated key: changeForwardWayConfirm
  ///
  /// In en, this message translates to:
  /// **'Switch forward method? Current forward connections will be disconnected.'**
  String get changeForwardWayConfirm;

  /// translated key: s3
  ///
  /// In en, this message translates to:
  /// **'S3'**
  String get s3;

  /// translated key: none
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// translated key: forwardServer
  ///
  /// In en, this message translates to:
  /// **'Forward Server'**
  String get forwardServer;

  /// translated key: forwardSettingsForwardEnableRequiredWebDAVText
  ///
  /// In en, this message translates to:
  /// **'Configure WebDAV first'**
  String get forwardSettingsForwardEnableRequiredWebDAVText;

  /// translated key: forwardSettingsForwardEnableRequiredS3Text
  ///
  /// In en, this message translates to:
  /// **'Configure S3 first'**
  String get forwardSettingsForwardEnableRequiredS3Text;

  /// translated key: createFolder
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createFolder;

  /// translated key: invalidFolderName
  ///
  /// In en, this message translates to:
  /// **'Invalid name, cannot contain special characters and must be less than 255 characters'**
  String get invalidFolderName;

  /// translated key: createFailed
  ///
  /// In en, this message translates to:
  /// **'Creation failed'**
  String get createFailed;

  /// translated key: notAllowRootPath
  ///
  /// In en, this message translates to:
  /// **'Root path is not allowed'**
  String get notAllowRootPath;

  /// translated key: rootPathCannotEnableForward
  ///
  /// In en, this message translates to:
  /// **'The storage path cannot be the root path'**
  String get rootPathCannotEnableForward;

  /// translated key: s3TypeTips
  ///
  /// In en, this message translates to:
  /// **'Any object storage service compatible with the standard S3 protocol can be configured directly.\n\nTencent Cloud and Qiniu Cloud have been tested and work well.\n\nAlibaba Cloud OSS requires separate settings.'**
  String get s3TypeTips;

  /// translated key: forwardWay
  ///
  /// In en, this message translates to:
  /// **'Forward Method'**
  String get forwardWay;

  /// translated key: backupTypeConfig
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get backupTypeConfig;

  /// translated key: backupTypeAppInfo
  ///
  /// In en, this message translates to:
  /// **'Clipboard Source'**
  String get backupTypeAppInfo;

  /// translated key: backupTypeDevice
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get backupTypeDevice;

  /// translated key: backupTypeHistory
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get backupTypeHistory;

  /// translated key: backupTypeHistoryTag
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get backupTypeHistoryTag;

  /// translated key: backupTypeOperationRecord
  ///
  /// In en, this message translates to:
  /// **'Operation Record'**
  String get backupTypeOperationRecord;

  /// translated key: backupTypeOperationSync
  ///
  /// In en, this message translates to:
  /// **'Sync Record'**
  String get backupTypeOperationSync;

  /// translated key: selectBackupItems
  ///
  /// In en, this message translates to:
  /// **'Select Backup Items'**
  String get selectBackupItems;

  /// translated key: online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// translated key: offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// translated key: enterSoftware
  ///
  /// In en, this message translates to:
  /// **'Enter App'**
  String get enterSoftware;

  /// translated key: segmentWords
  ///
  /// In en, this message translates to:
  /// **'Segment Words'**
  String get segmentWords;

  /// translated key: downloadFromGithub
  ///
  /// In en, this message translates to:
  /// **'Download from Github'**
  String get downloadFromGithub;

  /// translated key: notFoundJiebaFiles
  ///
  /// In en, this message translates to:
  /// **'Jieba files not found.\nDownload them and copy them to:\n{dirPath}\nOnly dict.txt and prob_emit.txt are required.'**
  String notFoundJiebaFiles(String dirPath);

  /// translated key: installJiebaDictFile
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installJiebaDictFile;

  /// translated key: downloadFailed
  ///
  /// In en, this message translates to:
  /// **'Download failed!'**
  String get downloadFailed;

  /// translated key: jiebaFileInstallSuccess
  ///
  /// In en, this message translates to:
  /// **'Jieba files installed'**
  String get jiebaFileInstallSuccess;

  /// translated key: encryptKey
  ///
  /// In en, this message translates to:
  /// **'Encryption Key'**
  String get encryptKey;

  /// translated key: encryptKeyErrorTip
  ///
  /// In en, this message translates to:
  /// **'Length must be at least 8 characters and cannot contain whitespace'**
  String get encryptKeyErrorTip;

  /// translated key: confirmClearEncryptKey
  ///
  /// In en, this message translates to:
  /// **'Confirm clear encryption key?'**
  String get confirmClearEncryptKey;

  /// translated key: authFailed
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authFailed;

  /// translated key: dhKeySettingName
  ///
  /// In en, this message translates to:
  /// **'Encrypt Key Exchange'**
  String get dhKeySettingName;

  /// translated key: dhKeySettingDesc
  ///
  /// In en, this message translates to:
  /// **'All devices need this and the same password, or connection fails.'**
  String get dhKeySettingDesc;

  /// translated key: dhKeySettingTips
  ///
  /// In en, this message translates to:
  /// **'Encrypts the Diffie-Hellman key exchange parameters used during device connection.\nWhen enabled, all connected devices must enable this and use the same password, or they cannot connect.\n\nLeaving it off is also acceptable.'**
  String get dhKeySettingTips;

  /// translated key: syncOutDateSettingTitle
  ///
  /// In en, this message translates to:
  /// **'Sync Date Range'**
  String get syncOutDateSettingTitle;

  /// translated key: syncOutDateSettingDesc
  ///
  /// In en, this message translates to:
  /// **'Sync only data in the selected time range.'**
  String get syncOutDateSettingDesc;

  /// translated key: pleaseWait
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// translated key: generateTodayAndroidLog
  ///
  /// In en, this message translates to:
  /// **'Generate Android native logs (today)'**
  String get generateTodayAndroidLog;

  /// translated key: noDiscoveryIfsSettingTitle
  ///
  /// In en, this message translates to:
  /// **'Exclude Discovery NICs'**
  String get noDiscoveryIfsSettingTitle;

  /// translated key: noDiscoveryIfsSettingDesc
  ///
  /// In en, this message translates to:
  /// **'Skip selected NICs during subnet scans.'**
  String get noDiscoveryIfsSettingDesc;

  /// translated key: onlyManualDiscoverySubNetSettingTitle
  ///
  /// In en, this message translates to:
  /// **'Manual Subnet Scan Only'**
  String get onlyManualDiscoverySubNetSettingTitle;

  /// translated key: onlyManualDiscoverySubNetSettingDesc
  ///
  /// In en, this message translates to:
  /// **'No auto scans after network changes or screen wake; scan from Devices.'**
  String get onlyManualDiscoverySubNetSettingDesc;

  /// translated key: stopListeningOnScreenClosedSettingTitle
  ///
  /// In en, this message translates to:
  /// **'Stop on Screen-off (Experimental)'**
  String get stopListeningOnScreenClosedSettingTitle;

  /// translated key: stopListeningOnScreenClosedSettingDesc
  ///
  /// In en, this message translates to:
  /// **'Stops clipboard listening 1 minute after screen-off to save battery on some devices.'**
  String get stopListeningOnScreenClosedSettingDesc;

  /// translated key: keepConnectionsOnNetworkSwitchTitle
  ///
  /// In en, this message translates to:
  /// **'Keep Existing Connections'**
  String get keepConnectionsOnNetworkSwitchTitle;

  /// translated key: keepConnectionsOnNetworkSwitchDesc
  ///
  /// In en, this message translates to:
  /// **'Reconnect only on Wi-Fi/mobile or online/offline changes; otherwise keep existing connections.'**
  String get keepConnectionsOnNetworkSwitchDesc;

  /// translated key: notNow
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// translated key: faq
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// translated key: sendBroadcastOnAddData
  ///
  /// In en, this message translates to:
  /// **'Send broadcast when adding data'**
  String get sendBroadcastOnAddData;

  /// translated key: sendBroadcastOnAddDataDesc
  ///
  /// In en, this message translates to:
  /// **'Send a system broadcast on clipboard changes or synced data so apps like Tasker can process it.'**
  String get sendBroadcastOnAddDataDesc;

  /// translated key: explain
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explain;

  /// translated key: sendBroadcastOnAddDataTips
  ///
  /// In en, this message translates to:
  /// **'The broadcast Action is: {kOnHistoryChangedBroadcastAction}\n\nThe current broadcast contains the following variables:\n1.type: Content type, valid values are: text, image, sms, file, notification\n2. content: Content, when it is an image or file, it is a local path; when it is a notification, it is JSON\n3. from_dev_id: Source device ID\n4. from_dev_name: Source device name'**
  String sendBroadcastOnAddDataTips(String kOnHistoryChangedBroadcastAction);

  /// translated key: recopyOnScreenUnlockedTitle
  ///
  /// In en, this message translates to:
  /// **'Retry Latest Copy After Unlock'**
  String get recopyOnScreenUnlockedTitle;

  /// translated key: recopyOnScreenUnlockedTitleDesc
  ///
  /// In en, this message translates to:
  /// **'On some systems, auto-copy fails while locked. Retry copying the latest synced data after unlock.'**
  String get recopyOnScreenUnlockedTitleDesc;

  /// translated key: rulesManagement
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rulesManagement;

  /// translated key: excludePrivateFormat
  ///
  /// In en, this message translates to:
  /// **'Skip Excluded Formats'**
  String get excludePrivateFormat;

  /// translated key: excludePrivateFormatDesc
  ///
  /// In en, this message translates to:
  /// **'Do not record clipboard entries marked for exclusion.'**
  String get excludePrivateFormatDesc;

  /// translated key: excludePrivateFormatTips
  ///
  /// In en, this message translates to:
  /// **'When clipboard content contains the ExcludeClipboardContentFromMonitorProcessing marker, it will not be recorded.'**
  String get excludePrivateFormatTips;

  /// translated key: moreActions
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;

  /// translated key: retainDays
  ///
  /// In en, this message translates to:
  /// **'Keep Last'**
  String get retainDays;

  /// translated key: onlyLocal
  ///
  /// In en, this message translates to:
  /// **'Only Local'**
  String get onlyLocal;

  /// translated key: enablePIP
  ///
  /// In en, this message translates to:
  /// **'Enable Picture-in-Picture'**
  String get enablePIP;

  /// translated key: enablePIPTip
  ///
  /// In en, this message translates to:
  /// **'Open received videos in Picture-in-Picture and improve clipboard detection.'**
  String get enablePIPTip;

  /// translated key: permissionSettingsClipboardTitle
  ///
  /// In en, this message translates to:
  /// **'Clipboard Permission'**
  String get permissionSettingsClipboardTitle;

  /// translated key: permissionSettingsClipboardDesc
  ///
  /// In en, this message translates to:
  /// **'Some Android systems allow clipboard access only while in use. Grant this to enable background clipboard access.'**
  String get permissionSettingsClipboardDesc;

  /// translated key: local
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// translated key: directConnect
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get directConnect;

  /// translated key: selectBackupSource
  ///
  /// In en, this message translates to:
  /// **'Backup Location'**
  String get selectBackupSource;

  /// translated key: notConfigured
  ///
  /// In en, this message translates to:
  /// **'Not Configured'**
  String get notConfigured;

  /// translated key: storagePathTips
  ///
  /// In en, this message translates to:
  /// **'Backup files and transfer files are stored in different folders within the same directory.\nIf the storage path is set to /ClipShare\nthen the temporary transfer files are stored in /ClipShare/history, \nthe backup files are stored in /ClipShare/backup.'**
  String get storagePathTips;

  /// translated key: uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// translated key: useTrayFlashingForConnectionTitle
  ///
  /// In en, this message translates to:
  /// **'Flash Tray on Connect/Disconnect'**
  String get useTrayFlashingForConnectionTitle;

  /// translated key: useTrayFlashingForConnectionDesc
  ///
  /// In en, this message translates to:
  /// **'Flash the tray instead of showing system notifications.'**
  String get useTrayFlashingForConnectionDesc;

  /// translated key: trayDevAliveTooltip
  ///
  /// In en, this message translates to:
  /// **'{first}\nConnected to {pairedCnt} paired devices\nConnected to {unpairedCnt} unpaired devices'**
  String trayDevAliveTooltip(
    String first,
    String pairedCnt,
    String unpairedCnt,
  );

  /// translated key: displayExtractedContent
  ///
  /// In en, this message translates to:
  /// **'Display Extracted Content'**
  String get displayExtractedContent;

  /// translated key: displayOriginContent
  ///
  /// In en, this message translates to:
  /// **'Display Original Content'**
  String get displayOriginContent;

  /// translated key: codePromptParamsContentIsSyncDisabled
  ///
  /// In en, this message translates to:
  /// **'Whether to prevent sync'**
  String get codePromptParamsContentIsSyncDisabled;

  /// translated key: codePromptParamsContentTags
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get codePromptParamsContentTags;

  /// translated key: codePromptParamsContentExtracted
  ///
  /// In en, this message translates to:
  /// **'Extracted content'**
  String get codePromptParamsContentExtracted;

  /// translated key: codePromptParamsContentDetail
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get codePromptParamsContentDetail;

  /// translated key: codePromptParamsContentNotificationTitle
  ///
  /// In en, this message translates to:
  /// **'Notification title (notification type only)'**
  String get codePromptParamsContentNotificationTitle;

  /// translated key: codePromptParamsContentSource
  ///
  /// In en, this message translates to:
  /// **'Source, such as a local path or app package name'**
  String get codePromptParamsContentSource;

  /// translated key: codePromptParamsContentType
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get codePromptParamsContentType;

  /// translated key: codePromptNotificationType
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get codePromptNotificationType;

  /// translated key: codePromptImageType
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get codePromptImageType;

  /// translated key: codePromptTextType
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get codePromptTextType;

  /// translated key: codePromptSmsType
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get codePromptSmsType;

  /// translated key: codePromptJsonDecode
  ///
  /// In en, this message translates to:
  /// **'JSON decode'**
  String get codePromptJsonDecode;

  /// translated key: codePromptLogError
  ///
  /// In en, this message translates to:
  /// **'Log an error-level message'**
  String get codePromptLogError;

  /// translated key: codePromptLogWarn
  ///
  /// In en, this message translates to:
  /// **'Log a warning-level message'**
  String get codePromptLogWarn;

  /// translated key: codePromptLogDebug
  ///
  /// In en, this message translates to:
  /// **'Log a debug-level message'**
  String get codePromptLogDebug;

  /// translated key: codePromptLogInfo
  ///
  /// In en, this message translates to:
  /// **'Log an info-level message'**
  String get codePromptLogInfo;

  /// translated key: codePromptContentType
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get codePromptContentType;

  /// translated key: codePromptJson
  ///
  /// In en, this message translates to:
  /// **'JSON Module'**
  String get codePromptJson;

  /// translated key: codePromptLog
  ///
  /// In en, this message translates to:
  /// **'Log Module'**
  String get codePromptLog;

  /// translated key: codePromptPrint
  ///
  /// In en, this message translates to:
  /// **'Print output, equivalent to logger.debug()'**
  String get codePromptPrint;

  /// translated key: codePromptMath
  ///
  /// In en, this message translates to:
  /// **'Math Module'**
  String get codePromptMath;

  /// translated key: codePromptString
  ///
  /// In en, this message translates to:
  /// **'String Module'**
  String get codePromptString;

  /// translated key: codePromptTable
  ///
  /// In en, this message translates to:
  /// **'Table manipulation Module'**
  String get codePromptTable;

  /// translated key: codePromptUtf8
  ///
  /// In en, this message translates to:
  /// **'UTF-8 Module'**
  String get codePromptUtf8;

  /// translated key: codePromptOs
  ///
  /// In en, this message translates to:
  /// **'OS Module (safe subset)'**
  String get codePromptOs;

  /// translated key: codePromptType
  ///
  /// In en, this message translates to:
  /// **'Get value type'**
  String get codePromptType;

  /// translated key: codePromptToString
  ///
  /// In en, this message translates to:
  /// **'Convert to string'**
  String get codePromptToString;

  /// translated key: codePromptToNumber
  ///
  /// In en, this message translates to:
  /// **'Convert to number'**
  String get codePromptToNumber;

  /// translated key: codePromptPairs
  ///
  /// In en, this message translates to:
  /// **'Iterate table (key-value pairs)'**
  String get codePromptPairs;

  /// translated key: codePromptIpairs
  ///
  /// In en, this message translates to:
  /// **'Iterate array (numeric index)'**
  String get codePromptIpairs;

  /// translated key: codePromptNext
  ///
  /// In en, this message translates to:
  /// **'Get next element'**
  String get codePromptNext;

  /// translated key: codePromptPcall
  ///
  /// In en, this message translates to:
  /// **'Protected function call'**
  String get codePromptPcall;

  /// translated key: codePromptXpcall
  ///
  /// In en, this message translates to:
  /// **'Protected call with error handler'**
  String get codePromptXpcall;

  /// translated key: codePromptSelect
  ///
  /// In en, this message translates to:
  /// **'Access variadic arguments'**
  String get codePromptSelect;

  /// translated key: codePromptAssert
  ///
  /// In en, this message translates to:
  /// **'Assertion check'**
  String get codePromptAssert;

  /// translated key: codePromptError
  ///
  /// In en, this message translates to:
  /// **'Raise an error'**
  String get codePromptError;

  /// translated key: codePromptMathAbs
  ///
  /// In en, this message translates to:
  /// **'Absolute value'**
  String get codePromptMathAbs;

  /// translated key: codePromptMathAcos
  ///
  /// In en, this message translates to:
  /// **'Arc cosine'**
  String get codePromptMathAcos;

  /// translated key: codePromptMathAsin
  ///
  /// In en, this message translates to:
  /// **'Arc sine'**
  String get codePromptMathAsin;

  /// translated key: codePromptMathAtan
  ///
  /// In en, this message translates to:
  /// **'Arc tangent'**
  String get codePromptMathAtan;

  /// translated key: codePromptMathCeil
  ///
  /// In en, this message translates to:
  /// **'Round up'**
  String get codePromptMathCeil;

  /// translated key: codePromptMathCos
  ///
  /// In en, this message translates to:
  /// **'Cosine'**
  String get codePromptMathCos;

  /// translated key: codePromptMathDeg
  ///
  /// In en, this message translates to:
  /// **'Radians to degrees'**
  String get codePromptMathDeg;

  /// translated key: codePromptMathExp
  ///
  /// In en, this message translates to:
  /// **'Exponential'**
  String get codePromptMathExp;

  /// translated key: codePromptMathFloor
  ///
  /// In en, this message translates to:
  /// **'Round down'**
  String get codePromptMathFloor;

  /// translated key: codePromptMathFmod
  ///
  /// In en, this message translates to:
  /// **'Remainder'**
  String get codePromptMathFmod;

  /// translated key: codePromptMathHuge
  ///
  /// In en, this message translates to:
  /// **'Largest float value'**
  String get codePromptMathHuge;

  /// translated key: codePromptMathLog
  ///
  /// In en, this message translates to:
  /// **'Logarithm'**
  String get codePromptMathLog;

  /// translated key: codePromptMathMax
  ///
  /// In en, this message translates to:
  /// **'Maximum value'**
  String get codePromptMathMax;

  /// translated key: codePromptMathMaxInteger
  ///
  /// In en, this message translates to:
  /// **'Maximum integer'**
  String get codePromptMathMaxInteger;

  /// translated key: codePromptMathMin
  ///
  /// In en, this message translates to:
  /// **'Minimum value'**
  String get codePromptMathMin;

  /// translated key: codePromptMathMinInteger
  ///
  /// In en, this message translates to:
  /// **'Minimum integer'**
  String get codePromptMathMinInteger;

  /// translated key: codePromptMathModf
  ///
  /// In en, this message translates to:
  /// **'Integer and fractional parts'**
  String get codePromptMathModf;

  /// translated key: codePromptMathPi
  ///
  /// In en, this message translates to:
  /// **'Pi constant'**
  String get codePromptMathPi;

  /// translated key: codePromptMathRad
  ///
  /// In en, this message translates to:
  /// **'Degrees to radians'**
  String get codePromptMathRad;

  /// translated key: codePromptMathRandom
  ///
  /// In en, this message translates to:
  /// **'Random number'**
  String get codePromptMathRandom;

  /// translated key: codePromptMathRandomSeed
  ///
  /// In en, this message translates to:
  /// **'Set random seed'**
  String get codePromptMathRandomSeed;

  /// translated key: codePromptMathSin
  ///
  /// In en, this message translates to:
  /// **'Sine'**
  String get codePromptMathSin;

  /// translated key: codePromptMathSqrt
  ///
  /// In en, this message translates to:
  /// **'Square root'**
  String get codePromptMathSqrt;

  /// translated key: codePromptMathTan
  ///
  /// In en, this message translates to:
  /// **'Tangent'**
  String get codePromptMathTan;

  /// translated key: codePromptMathToInteger
  ///
  /// In en, this message translates to:
  /// **'Convert to integer'**
  String get codePromptMathToInteger;

  /// translated key: codePromptMathType
  ///
  /// In en, this message translates to:
  /// **'Number subtype'**
  String get codePromptMathType;

  /// translated key: codePromptMathUlt
  ///
  /// In en, this message translates to:
  /// **'Unsigned integer comparison'**
  String get codePromptMathUlt;

  /// translated key: codePromptStringByte
  ///
  /// In en, this message translates to:
  /// **'Character code'**
  String get codePromptStringByte;

  /// translated key: codePromptStringChar
  ///
  /// In en, this message translates to:
  /// **'Create string from character codes'**
  String get codePromptStringChar;

  /// translated key: codePromptStringDump
  ///
  /// In en, this message translates to:
  /// **'Dump function bytecode'**
  String get codePromptStringDump;

  /// translated key: codePromptStringLen
  ///
  /// In en, this message translates to:
  /// **'String length'**
  String get codePromptStringLen;

  /// translated key: codePromptStringSub
  ///
  /// In en, this message translates to:
  /// **'Substring'**
  String get codePromptStringSub;

  /// translated key: codePromptStringFind
  ///
  /// In en, this message translates to:
  /// **'Find substring'**
  String get codePromptStringFind;

  /// translated key: codePromptStringFormat
  ///
  /// In en, this message translates to:
  /// **'Format string'**
  String get codePromptStringFormat;

  /// translated key: codePromptStringGMatch
  ///
  /// In en, this message translates to:
  /// **'Iterate matches'**
  String get codePromptStringGMatch;

  /// translated key: codePromptStringGSub
  ///
  /// In en, this message translates to:
  /// **'Replace matches'**
  String get codePromptStringGSub;

  /// translated key: codePromptStringLower
  ///
  /// In en, this message translates to:
  /// **'Convert to lowercase'**
  String get codePromptStringLower;

  /// translated key: codePromptStringMatch
  ///
  /// In en, this message translates to:
  /// **'Match pattern'**
  String get codePromptStringMatch;

  /// translated key: codePromptStringPack
  ///
  /// In en, this message translates to:
  /// **'Pack values into binary string'**
  String get codePromptStringPack;

  /// translated key: codePromptStringPackSize
  ///
  /// In en, this message translates to:
  /// **'Packed size'**
  String get codePromptStringPackSize;

  /// translated key: codePromptStringRep
  ///
  /// In en, this message translates to:
  /// **'Repeat string'**
  String get codePromptStringRep;

  /// translated key: codePromptStringReverse
  ///
  /// In en, this message translates to:
  /// **'Reverse string'**
  String get codePromptStringReverse;

  /// translated key: codePromptStringUnpack
  ///
  /// In en, this message translates to:
  /// **'Unpack binary string'**
  String get codePromptStringUnpack;

  /// translated key: codePromptStringUpper
  ///
  /// In en, this message translates to:
  /// **'Convert to uppercase'**
  String get codePromptStringUpper;

  /// translated key: codePromptTableInsert
  ///
  /// In en, this message translates to:
  /// **'Insert element'**
  String get codePromptTableInsert;

  /// translated key: codePromptTableMove
  ///
  /// In en, this message translates to:
  /// **'Move elements between tables'**
  String get codePromptTableMove;

  /// translated key: codePromptTableRemove
  ///
  /// In en, this message translates to:
  /// **'Remove element'**
  String get codePromptTableRemove;

  /// translated key: codePromptTableSort
  ///
  /// In en, this message translates to:
  /// **'Sort table'**
  String get codePromptTableSort;

  /// translated key: codePromptTableConcat
  ///
  /// In en, this message translates to:
  /// **'Concatenate strings'**
  String get codePromptTableConcat;

  /// translated key: codePromptUtf8Len
  ///
  /// In en, this message translates to:
  /// **'UTF-8 string length'**
  String get codePromptUtf8Len;

  /// translated key: codePromptUtf8Char
  ///
  /// In en, this message translates to:
  /// **'Create UTF-8 character'**
  String get codePromptUtf8Char;

  /// translated key: codePromptUtf8CharPattern
  ///
  /// In en, this message translates to:
  /// **'UTF-8 character pattern'**
  String get codePromptUtf8CharPattern;

  /// translated key: codePromptUtf8Codes
  ///
  /// In en, this message translates to:
  /// **'Iterate UTF-8 code points'**
  String get codePromptUtf8Codes;

  /// translated key: codePromptUtf8CodePoint
  ///
  /// In en, this message translates to:
  /// **'Get UTF-8 code points'**
  String get codePromptUtf8CodePoint;

  /// translated key: codePromptUtf8Offset
  ///
  /// In en, this message translates to:
  /// **'Get UTF-8 offset'**
  String get codePromptUtf8Offset;

  /// translated key: codePromptOsClock
  ///
  /// In en, this message translates to:
  /// **'CPU time used'**
  String get codePromptOsClock;

  /// translated key: codePromptOsDate
  ///
  /// In en, this message translates to:
  /// **'Get current date'**
  String get codePromptOsDate;

  /// translated key: codePromptOsTime
  ///
  /// In en, this message translates to:
  /// **'Get timestamp'**
  String get codePromptOsTime;

  /// translated key: codePromptOsDiffTime
  ///
  /// In en, this message translates to:
  /// **'Time difference'**
  String get codePromptOsDiffTime;

  /// translated key: codePromptLuaVersion
  ///
  /// In en, this message translates to:
  /// **'Current Lua version'**
  String get codePromptLuaVersion;

  /// translated key: codePromptTablePack
  ///
  /// In en, this message translates to:
  /// **'Pack arguments into a table'**
  String get codePromptTablePack;

  /// translated key: codePromptTableUnpack
  ///
  /// In en, this message translates to:
  /// **'Unpack a table into multiple return values'**
  String get codePromptTableUnpack;

  /// translated key: codePromptScriptParams
  ///
  /// In en, this message translates to:
  /// **'Script parameters, including content, type, source, and other information'**
  String get codePromptScriptParams;

  /// translated key: codePromptIfSnippet
  ///
  /// In en, this message translates to:
  /// **'If condition snippet'**
  String get codePromptIfSnippet;

  /// translated key: codePromptElseSnippet
  ///
  /// In en, this message translates to:
  /// **'Else snippet'**
  String get codePromptElseSnippet;

  /// translated key: codePromptElseIfSnippet
  ///
  /// In en, this message translates to:
  /// **'Else-if snippet'**
  String get codePromptElseIfSnippet;

  /// translated key: codePromptWhileSnippet
  ///
  /// In en, this message translates to:
  /// **'While loop snippet'**
  String get codePromptWhileSnippet;

  /// translated key: codePromptRepeatSnippet
  ///
  /// In en, this message translates to:
  /// **'Repeat-until loop snippet'**
  String get codePromptRepeatSnippet;

  /// translated key: codePromptForSnippet
  ///
  /// In en, this message translates to:
  /// **'For numeric loop snippet'**
  String get codePromptForSnippet;

  /// translated key: codePromptForStepSnippet
  ///
  /// In en, this message translates to:
  /// **'For loop with step snippet'**
  String get codePromptForStepSnippet;

  /// translated key: codePromptIPairsSnippet
  ///
  /// In en, this message translates to:
  /// **'Ipairs iteration snippet'**
  String get codePromptIPairsSnippet;

  /// translated key: codePromptPairsSnippet
  ///
  /// In en, this message translates to:
  /// **'Pairs table iteration snippet'**
  String get codePromptPairsSnippet;

  /// translated key: codePromptFunctionSnippet
  ///
  /// In en, this message translates to:
  /// **'Function definition snippet'**
  String get codePromptFunctionSnippet;

  /// translated key: codePromptLocalFunctionSnippet
  ///
  /// In en, this message translates to:
  /// **'Local function definition snippet'**
  String get codePromptLocalFunctionSnippet;

  /// translated key: codePromptPlatformAndroid
  ///
  /// In en, this message translates to:
  /// **'Android platform'**
  String get codePromptPlatformAndroid;

  /// translated key: codePromptNotify
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get codePromptNotify;

  /// translated key: codePromptAndroidToast
  ///
  /// In en, this message translates to:
  /// **'Android toast message'**
  String get codePromptAndroidToast;

  /// translated key: codePromptAndroidSendHistoryChangedBroadcast
  ///
  /// In en, this message translates to:
  /// **'Android send history changed broadcast'**
  String get codePromptAndroidSendHistoryChangedBroadcast;

  /// translated key: codePromptPlatform
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get codePromptPlatform;

  /// translated key: codePromptPlatformIsAndroid
  ///
  /// In en, this message translates to:
  /// **'Check if platform is Android'**
  String get codePromptPlatformIsAndroid;

  /// translated key: codePromptPlatformIsIOS
  ///
  /// In en, this message translates to:
  /// **'Check if platform is iOS'**
  String get codePromptPlatformIsIOS;

  /// translated key: codePromptPlatformIsWindows
  ///
  /// In en, this message translates to:
  /// **'Check if platform is Windows'**
  String get codePromptPlatformIsWindows;

  /// translated key: codePromptPlatformIsMacOS
  ///
  /// In en, this message translates to:
  /// **'Check if platform is macOS'**
  String get codePromptPlatformIsMacOS;

  /// translated key: codePromptPlatformIsLinux
  ///
  /// In en, this message translates to:
  /// **'Check if platform is Linux'**
  String get codePromptPlatformIsLinux;

  /// translated key: codePromptApp
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get codePromptApp;

  /// translated key: codePromptAppVersionName
  ///
  /// In en, this message translates to:
  /// **'App version name'**
  String get codePromptAppVersionName;

  /// translated key: codePromptAppVersionNumber
  ///
  /// In en, this message translates to:
  /// **'App version number'**
  String get codePromptAppVersionNumber;

  /// translated key: codePromptDeviceSelf
  ///
  /// In en, this message translates to:
  /// **'Current device'**
  String get codePromptDeviceSelf;

  /// translated key: codePromptDeviceSelfName
  ///
  /// In en, this message translates to:
  /// **'Current device name'**
  String get codePromptDeviceSelfName;

  /// translated key: codePromptDeviceSelfId
  ///
  /// In en, this message translates to:
  /// **'Current device ID'**
  String get codePromptDeviceSelfId;

  /// translated key: codePromptCrypto
  ///
  /// In en, this message translates to:
  /// **'Cryptography'**
  String get codePromptCrypto;

  /// translated key: codePromptCryptoMD5
  ///
  /// In en, this message translates to:
  /// **'Compute MD5 hash'**
  String get codePromptCryptoMD5;

  /// translated key: codePromptCryptoSHA256
  ///
  /// In en, this message translates to:
  /// **'Compute SHA-256 hash'**
  String get codePromptCryptoSHA256;

  /// translated key: codePromptCryptoSHA1
  ///
  /// In en, this message translates to:
  /// **'Compute SHA-1 hash'**
  String get codePromptCryptoSHA1;

  /// translated key: codePromptBase64
  ///
  /// In en, this message translates to:
  /// **'Base64'**
  String get codePromptBase64;

  /// translated key: codePromptBase64Encode
  ///
  /// In en, this message translates to:
  /// **'Encode Base64'**
  String get codePromptBase64Encode;

  /// translated key: codePromptBase64Decode
  ///
  /// In en, this message translates to:
  /// **'Decode Base64'**
  String get codePromptBase64Decode;

  /// translated key: codePromptRegex
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get codePromptRegex;

  /// translated key: codePromptRegexMatch
  ///
  /// In en, this message translates to:
  /// **'Match all full matches and return as a list'**
  String get codePromptRegexMatch;

  /// translated key: codePromptRegexMatchGroups
  ///
  /// In en, this message translates to:
  /// **'Match all capture groups and return as a nested list'**
  String get codePromptRegexMatchGroups;

  /// translated key: codePromptHttp
  ///
  /// In en, this message translates to:
  /// **'HTTP request Module'**
  String get codePromptHttp;

  /// translated key: codePromptTask
  ///
  /// In en, this message translates to:
  /// **'Async task Module'**
  String get codePromptTask;

  /// translated key: codePromptAsync
  ///
  /// In en, this message translates to:
  /// **'Wraps a function as async, allowing await inside'**
  String get codePromptAsync;

  /// translated key: codePromptAwait
  ///
  /// In en, this message translates to:
  /// **'Waits for an awaiter to complete and returns its result; can only be used inside an async function'**
  String get codePromptAwait;

  /// translated key: codePromptHttpGet
  ///
  /// In en, this message translates to:
  /// **'GET request method (async)'**
  String get codePromptHttpGet;

  /// translated key: codePromptHttpPost
  ///
  /// In en, this message translates to:
  /// **'POST request method (async)'**
  String get codePromptHttpPost;

  /// translated key: codePromptPut
  ///
  /// In en, this message translates to:
  /// **'PUT request method (async)'**
  String get codePromptPut;

  /// translated key: codePromptDelete
  ///
  /// In en, this message translates to:
  /// **'DELETE request method (async)'**
  String get codePromptDelete;

  /// translated key: codePromptTaskCreate
  ///
  /// In en, this message translates to:
  /// **'Creates a task (awaiter)'**
  String get codePromptTaskCreate;

  /// translated key: rulesPageUnsavedChangesConfirm
  ///
  /// In en, this message translates to:
  /// **'There are unsaved changes. Continue anyway?'**
  String get rulesPageUnsavedChangesConfirm;

  /// translated key: ruleItemContentRequired
  ///
  /// In en, this message translates to:
  /// **'Rule content cannot be empty'**
  String get ruleItemContentRequired;

  /// translated key: ruleItemExtractRuleRequired
  ///
  /// In en, this message translates to:
  /// **'Extraction rule cannot be empty'**
  String get ruleItemExtractRuleRequired;

  /// translated key: ruleItemScriptContentRequired
  ///
  /// In en, this message translates to:
  /// **'Script content cannot be empty'**
  String get ruleItemScriptContentRequired;

  /// translated key: ruleItemUnsupportedOperation
  ///
  /// In en, this message translates to:
  /// **'Unsupported operation'**
  String get ruleItemUnsupportedOperation;

  /// translated key: ruleTriggerOnCopyText
  ///
  /// In en, this message translates to:
  /// **'After copy'**
  String get ruleTriggerOnCopyText;

  /// translated key: ruleTriggerOnNotificationText
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get ruleTriggerOnNotificationText;

  /// translated key: ruleTriggerOnSmsText
  ///
  /// In en, this message translates to:
  /// **'New SMS'**
  String get ruleTriggerOnSmsText;

  /// translated key: ruleDetailRegexHint
  ///
  /// In en, this message translates to:
  /// **'Enter a regular expression'**
  String get ruleDetailRegexHint;

  /// translated key: ruleDetailNameLabel
  ///
  /// In en, this message translates to:
  /// **'Rule name: '**
  String get ruleDetailNameLabel;

  /// translated key: ruleDetailNameHint
  ///
  /// In en, this message translates to:
  /// **'Enter rule name'**
  String get ruleDetailNameHint;

  /// translated key: ruleDetailPlatformLabel
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get ruleDetailPlatformLabel;

  /// translated key: ruleDetailTriggerLabel
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get ruleDetailTriggerLabel;

  /// translated key: ruleDetailRuleLabel
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get ruleDetailRuleLabel;

  /// translated key: ruleDetailRegexTab
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get ruleDetailRegexTab;

  /// translated key: ruleDetailScriptTab
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get ruleDetailScriptTab;

  /// translated key: ruleDetailAutoWrapTooltip
  ///
  /// In en, this message translates to:
  /// **'Auto wrap'**
  String get ruleDetailAutoWrapTooltip;

  /// translated key: ruleDetailFullScreenTooltip
  ///
  /// In en, this message translates to:
  /// **'Enter full-screen editor'**
  String get ruleDetailFullScreenTooltip;

  /// translated key: ruleDetailModeDefault
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get ruleDetailModeDefault;

  /// translated key: ruleDetailModeBlacklist
  ///
  /// In en, this message translates to:
  /// **'Blacklist'**
  String get ruleDetailModeBlacklist;

  /// translated key: ruleDetailModeWhitelist
  ///
  /// In en, this message translates to:
  /// **'Whitelist'**
  String get ruleDetailModeWhitelist;

  /// translated key: ruleDetailRegexLabel
  ///
  /// In en, this message translates to:
  /// **'Match rule:'**
  String get ruleDetailRegexLabel;

  /// translated key: ruleDetailRegexTip
  ///
  /// In en, this message translates to:
  /// **'Regex is case-insensitive by default; the extraction rule only extracts the first match.'**
  String get ruleDetailRegexTip;

  /// translated key: ruleDetailExtractContent
  ///
  /// In en, this message translates to:
  /// **'Extract rule:'**
  String get ruleDetailExtractContent;

  /// translated key: ruleDetailModeLabel
  ///
  /// In en, this message translates to:
  /// **'Rule mode'**
  String get ruleDetailModeLabel;

  /// translated key: ruleDetailActionLabel
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get ruleDetailActionLabel;

  /// translated key: ruleDetailAddTagLabel
  ///
  /// In en, this message translates to:
  /// **'Add tags:'**
  String get ruleDetailAddTagLabel;

  /// translated key: ruleDetailAddTagDialogTitle
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get ruleDetailAddTagDialogTitle;

  /// translated key: ruleDetailFinalRule
  ///
  /// In en, this message translates to:
  /// **'Stop following rules'**
  String get ruleDetailFinalRule;

  /// translated key: ruleDetailRunTestTooltip
  ///
  /// In en, this message translates to:
  /// **'Run test'**
  String get ruleDetailRunTestTooltip;

  /// translated key: ruleDetailPageTitle
  ///
  /// In en, this message translates to:
  /// **'Rule details'**
  String get ruleDetailPageTitle;

  /// translated key: ruleModulesDetailSyntaxError
  ///
  /// In en, this message translates to:
  /// **'Contains syntax errors. Please fix them'**
  String get ruleModulesDetailSyntaxError;

  /// translated key: scriptModulesDetailDisplayNameRequired
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty'**
  String get scriptModulesDetailDisplayNameRequired;

  /// translated key: scriptModulesDetailModuleNameRequired
  ///
  /// In en, this message translates to:
  /// **'Module name cannot be empty'**
  String get scriptModulesDetailModuleNameRequired;

  /// translated key: scriptModulesDetailModuleNameDuplicated
  ///
  /// In en, this message translates to:
  /// **'Module name must be unique'**
  String get scriptModulesDetailModuleNameDuplicated;

  /// translated key: scriptModuleDetailContentRequired
  ///
  /// In en, this message translates to:
  /// **'Content cannot be empty'**
  String get scriptModuleDetailContentRequired;

  /// translated key: scriptModuleDetailDisplayNameLabel
  ///
  /// In en, this message translates to:
  /// **'Display name: '**
  String get scriptModuleDetailDisplayNameLabel;

  /// translated key: scriptModuleDetailDisplayNameHint
  ///
  /// In en, this message translates to:
  /// **'Enter display name'**
  String get scriptModuleDetailDisplayNameHint;

  /// translated key: scriptModuleDetailModuleNameLabel
  ///
  /// In en, this message translates to:
  /// **'Module name'**
  String get scriptModuleDetailModuleNameLabel;

  /// translated key: scriptModuleDetailModuleNameImmutableTooltip
  ///
  /// In en, this message translates to:
  /// **'Module name cannot be changed after saving'**
  String get scriptModuleDetailModuleNameImmutableTooltip;

  /// translated key: scriptModuleDetailModuleNameHint
  ///
  /// In en, this message translates to:
  /// **'Module name'**
  String get scriptModuleDetailModuleNameHint;

  /// translated key: scriptModuleDetailNameInvalid
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores are allowed, and it cannot start with a number'**
  String get scriptModuleDetailNameInvalid;

  /// translated key: scriptModuleDetailPageTitle
  ///
  /// In en, this message translates to:
  /// **'Module details'**
  String get scriptModuleDetailPageTitle;

  /// translated key: ruleListDeleteModuleConfirm
  ///
  /// In en, this message translates to:
  /// **'Delete it? If other scripts use it, they will stop working.'**
  String get ruleListDeleteModuleConfirm;

  /// translated key: ruleListExitSelectionModeTooltip
  ///
  /// In en, this message translates to:
  /// **'Exit selection mode'**
  String get ruleListExitSelectionModeTooltip;

  /// translated key: ruleCardDragDisabledTooltip
  ///
  /// In en, this message translates to:
  /// **'Save data or clear the search input before reordering'**
  String get ruleCardDragDisabledTooltip;

  /// translated key: ruleCardDragTooltip
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get ruleCardDragTooltip;

  /// translated key: scriptEditTestViewPanelTooltip
  ///
  /// In en, this message translates to:
  /// **'Run panel'**
  String get scriptEditTestViewPanelTooltip;

  /// translated key: scriptEditTestViewRunTooltip
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get scriptEditTestViewRunTooltip;

  /// translated key: scriptEditTestViewExitFullScreenTooltip
  ///
  /// In en, this message translates to:
  /// **'Exit full-screen editor'**
  String get scriptEditTestViewExitFullScreenTooltip;

  /// translated key: scriptTestPanelParamsTab
  ///
  /// In en, this message translates to:
  /// **'Params'**
  String get scriptTestPanelParamsTab;

  /// translated key: scriptTestPanelCompileInfoTab
  ///
  /// In en, this message translates to:
  /// **'Compile info'**
  String get scriptTestPanelCompileInfoTab;

  /// translated key: scriptTestPanelOutputTab
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get scriptTestPanelOutputTab;

  /// translated key: scriptTestPanelRunResultTab
  ///
  /// In en, this message translates to:
  /// **'Run result'**
  String get scriptTestPanelRunResultTab;

  /// translated key: scriptTestPanelCollapseTooltip
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get scriptTestPanelCollapseTooltip;

  /// translated key: ruleCompileCodeNotFound
  ///
  /// In en, this message translates to:
  /// **'Code not found'**
  String get ruleCompileCodeNotFound;

  /// translated key: ruleCompileCodeEmpty
  ///
  /// In en, this message translates to:
  /// **'Code is empty'**
  String get ruleCompileCodeEmpty;

  /// translated key: ruleCompileSuccess
  ///
  /// In en, this message translates to:
  /// **'Compile succeeded.'**
  String get ruleCompileSuccess;

  /// translated key: ruleCompileFailedPrefix
  ///
  /// In en, this message translates to:
  /// **'Compile failed:\n{message}'**
  String ruleCompileFailedPrefix(String message);

  /// translated key: scriptModuleCompileReturnTableRequired
  ///
  /// In en, this message translates to:
  /// **'The Module return value must be a table.'**
  String get scriptModuleCompileReturnTableRequired;

  /// translated key: success
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// translated key: error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// translated key: extracted
  ///
  /// In en, this message translates to:
  /// **'Extracted'**
  String get extracted;

  /// translated key: tags
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// translated key: flags
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get flags;

  /// translated key: finalRule
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get finalRule;

  /// translated key: dropped
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get dropped;

  /// translated key: syncDisabled
  ///
  /// In en, this message translates to:
  /// **'Prevent Sync'**
  String get syncDisabled;

  /// translated key: rules
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// translated key: scriptModules
  ///
  /// In en, this message translates to:
  /// **'Script Modules'**
  String get scriptModules;

  /// translated key: modules
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// translated key: unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// translated key: triggerOnCopy
  ///
  /// In en, this message translates to:
  /// **'Trigger: Copy'**
  String get triggerOnCopy;

  /// translated key: triggerOnNotification
  ///
  /// In en, this message translates to:
  /// **'Trigger: Notification'**
  String get triggerOnNotification;

  /// translated key: triggerOnSms
  ///
  /// In en, this message translates to:
  /// **'Trigger: SMS'**
  String get triggerOnSms;

  /// translated key: modulesTip
  ///
  /// In en, this message translates to:
  /// **'You can import pure Lua libraries, or encapsulate some frequently used methods for scripts to call. The return value must be a table.\nThe sandbox environment is the same as in the script.'**
  String get modulesTip;

  /// translated key: recordMaxLength
  ///
  /// In en, this message translates to:
  /// **'Max content length'**
  String get recordMaxLength;

  /// translated key: recordMaxLengthTips
  ///
  /// In en, this message translates to:
  /// **'Can save 2 MB+ content, but search may fail.'**
  String get recordMaxLengthTips;

  /// translated key: length
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// translated key: mustGreaterThanZero
  ///
  /// In en, this message translates to:
  /// **'Must >= 0'**
  String get mustGreaterThanZero;

  /// translated key: settingsSectionLanguageSubtitle
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get settingsSectionLanguageSubtitle;

  /// translated key: settingsSectionPreferenceSubtitle
  ///
  /// In en, this message translates to:
  /// **'UI & interaction'**
  String get settingsSectionPreferenceSubtitle;

  /// translated key: settingsSectionNotificationSubtitle
  ///
  /// In en, this message translates to:
  /// **'Alerts & reminders'**
  String get settingsSectionNotificationSubtitle;

  /// translated key: settingsSectionClipboardSubtitle
  ///
  /// In en, this message translates to:
  /// **'Capture & history'**
  String get settingsSectionClipboardSubtitle;

  /// translated key: settingsSectionPermissionSubtitle
  ///
  /// In en, this message translates to:
  /// **'App permissions'**
  String get settingsSectionPermissionSubtitle;

  /// translated key: settingsSectionFloatWindowSubtitle
  ///
  /// In en, this message translates to:
  /// **'Floating window and keep-alive'**
  String get settingsSectionFloatWindowSubtitle;

  /// translated key: settingsSectionDiscoverySubtitle
  ///
  /// In en, this message translates to:
  /// **'Devices & connections'**
  String get settingsSectionDiscoverySubtitle;

  /// translated key: settingsSectionForwardSubtitle
  ///
  /// In en, this message translates to:
  /// **'Relay & storage'**
  String get settingsSectionForwardSubtitle;

  /// translated key: settingsSectionSecuritySubtitle
  ///
  /// In en, this message translates to:
  /// **'Auth & encryption'**
  String get settingsSectionSecuritySubtitle;

  /// translated key: settingsSectionHotKeySubtitle
  ///
  /// In en, this message translates to:
  /// **'Popup & window shortcuts'**
  String get settingsSectionHotKeySubtitle;

  /// translated key: settingsSectionSyncSubtitle
  ///
  /// In en, this message translates to:
  /// **'History saving'**
  String get settingsSectionSyncSubtitle;

  /// translated key: settingsSectionCleanDataSubtitle
  ///
  /// In en, this message translates to:
  /// **'Clean history and records'**
  String get settingsSectionCleanDataSubtitle;

  /// translated key: settingsSectionRulesSubtitle
  ///
  /// In en, this message translates to:
  /// **'Rules & scripts'**
  String get settingsSectionRulesSubtitle;

  /// translated key: settingsSectionBackupSubtitle
  ///
  /// In en, this message translates to:
  /// **'Import & export'**
  String get settingsSectionBackupSubtitle;

  /// translated key: settingsSectionAboutLogSubtitle
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get settingsSectionAboutLogSubtitle;

  /// translated key: settingsSectionStatisticsSubtitle
  ///
  /// In en, this message translates to:
  /// **'Usage insights'**
  String get settingsSectionStatisticsSubtitle;

  /// translated key: settingsOverviewPermissionNormal
  ///
  /// In en, this message translates to:
  /// **'All granted'**
  String get settingsOverviewPermissionNormal;

  /// translated key: settingsOverviewPermissionIssueCount
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String settingsOverviewPermissionIssueCount(String count);

  /// translated key: settingsOverviewForwardClosed
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOverviewForwardClosed;

  /// translated key: storageWsVersionIncompatibleTitle
  ///
  /// In en, this message translates to:
  /// **'Incompatible version'**
  String get storageWsVersionIncompatibleTitle;

  /// translated key: storageWsVersionIncompatibleDialogContent
  ///
  /// In en, this message translates to:
  /// **'Current notification service version: {version}. Minimum required: {minVersion}. Please upgrade it before using storage sync.'**
  String storageWsVersionIncompatibleDialogContent(
    String version,
    String minVersion,
  );

  /// translated key: noTargetWindow
  ///
  /// In en, this message translates to:
  /// **'Paste failed: no target window was found that can receive the paste action.'**
  String get noTargetWindow;

  /// translated key: openTargetProcessFailed
  ///
  /// In en, this message translates to:
  /// **'Paste failed: the target process could not be opened for inspection.'**
  String get openTargetProcessFailed;

  /// translated key: inspectTargetFailed
  ///
  /// In en, this message translates to:
  /// **'Paste failed: the target process integrity level could not be read. Elevated privileges may be required.'**
  String get inspectTargetFailed;

  /// translated key: inspectSelfFailed
  ///
  /// In en, this message translates to:
  /// **'Paste failed: the current process integrity level could not be read.'**
  String get inspectSelfFailed;

  /// translated key: targetIntegrityHigher
  ///
  /// In en, this message translates to:
  /// **'Paste failed: elevated privileges may be required.'**
  String get targetIntegrityHigher;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
