import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/window_type.dart';
import 'package:clipshare/app/data/models/my_drop_item.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/extensions/history_data_extension.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/channelMethods/android_channel_method.dart';
import 'package:clipshare/app/data/enums/channelMethods/clip_channel_method.dart';
import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/search_filter.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/views/windows/file_sender/online_devices_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/windows_win_v_takeover.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_handler/share_handler.dart';
import 'package:uri_file_reader/uri_file_reader.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SplashController extends GetxController {
  static const tag = "SplashController";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final devService = Get.find<DeviceService>();
  final devController = Get.find<DeviceController>();
  final pendingFileService = Get.find<PendingFileService>();
  final multiWindowService = Get.find<MultiWindowChannelService>();

  @override
  void onReady() {
    super.onReady();
    init()
        .then((ignore) {
          // 初始化完成，导航到下一个页面
          if (appConfig.firstStartup && Platform.isAndroid) {
            Get.offNamed(Routes.WELCOME);
          } else {
            Get.offNamed(Routes.HOME);
          }
          _scheduleDetachedAndroidRouteFrame();
        })
        .catchError((err, stack) {
          Global.showTipsDialog(
            context: Get.context!,
            text: "$err\n$stack",
            title: TranslationKey.errorDialogTitle.tr,
          );
        });
  }

  /// 服务无 Activity 拉起 Android 引擎时，规则迁移会让路由发生在初始预热帧结束后。
  /// detached 生命周期不会调度普通帧，需要强制提交一次路由帧以创建目标页及其 Binding。
  void _scheduleDetachedAndroidRouteFrame() {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (!Platform.isAndroid || lifecycleState != AppLifecycleState.detached) {
      return;
    }
    WidgetsBinding.instance.scheduleForcedFrame();
  }

  Future<void> init() async {
    // 先更新语言，确保后续下发给 Android 悬浮窗的文案已是最终 locale。
    appConfig.updateLanguage();
    if (PlatformExt.isDesktop) {
      //加载配置后初始化窗体配置
      await initWindowsManager();
      await initWinVTakeover();
      await initHotKey();
      initMultiWindowEvent();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: PlatformExt.startupExecutablePath,
      );
      var isLaunchAtStartup = await launchAtStartup.isEnabled();
      final isSystem = isLaunchAtStartup;
      if (Platform.isWindows) {
        final startupPaths = <String>[
          Constants.windowsStartUpPath,
        ];
        final userStartupPath = appConfig.windowsUserStartUpPath;
        if (userStartupPath != null) {
          startupPaths.add(userStartupPath);
        }
        for (var startupPath in startupPaths) {
          final dir = Directory(startupPath);
          if (!dir.existsSync()) continue;
          final hasShortcut = await dir.existsTargetFileShortcut(
            Platform.resolvedExecutable,
          );
          isLaunchAtStartup = isLaunchAtStartup || hasShortcut;
        }
      }
      logger.debug(tag, "isLaunchAtStartup  $isLaunchAtStartup, isSystem $isSystem");
      appConfig.setLaunchAtStartup(isLaunchAtStartup, isLaunchAtStartup && isSystem);
      var updateDir = Directory(appConfig.updateDownloadFileDirPath);
      logger.debug(tag, "updateDir = $updateDir");
      if (await updateDir.exists()) {
        updateDir.delete(recursive: true);
      }
    }
    if (Platform.isAndroid) {
      androidChannelService.setAutoReportCrashes(appConfig.enableAutoUploadCrashLogs);
      await copyAssets();
      if (appConfig.showHistoryFloat) {
        androidChannelService.showHistoryFloatWindow();
      }
      if (appConfig.enhanceBackgroundKeepAlive) {
        androidChannelService.showKeepAliveFloatWindow();
      }
      androidChannelService.lockHistoryFloatLoc(
        {"loc": appConfig.lockHistoryFloatLoc},
      );
    }
    if (Platform.isIOS) {
      if (appConfig.enablePIP) {
        final tempPath = await FileUtil.copyAssetToTemp(Constants.iosPIPDefaultVideoPath);
        final result = await clipboardManager.startPIP(tempPath);
        logger.debug(tag, "start pip $result");
      }
    }
    // 初始化channel
    initChannel();
    initShareHandler();
    if (Platform.isAndroid && appConfig.showHistoryFloat) {
      // 语言更新与 channel 初始化完成后再补发一次，避免首次启动过早导致悬浮窗文案未刷新。
      androidChannelService.showHistoryFloatWindow();
    }
    // 初始化托盘服务（必须在语言初始化之后，以确保菜单项使用正确的翻译）
    if (PlatformExt.isDesktop) {
      await Get.putAsync(() => TrayService().init(), permanent: true);
    }
    await appConfig.migrateRules();
  }

  Future<void> copyAssets() async {
    final luaFiles = ['dkjson.lua', 'task.lua'];
    for (var fileName in luaFiles) {
      try {
        final newLuaPath = File(p.join(appConfig.luaLibDirPath, fileName));
        await newLuaPath.parent.create(recursive: true);
        final bytes = await rootBundle.load('assets/lua/$fileName');
        await newLuaPath.writeAsBytes(
          bytes.buffer.asUint8List(),
          flush: true,
        );
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  Future<void> initWindowsManager() async {
    final [width, height] = appConfig.windowSize.split("x").map((e) => e.toDouble()).toList();
    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      minimumSize: kReleaseMode ? const Size(Constants.showHistoryRightWidth * 1.0, 200) : null,
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    return windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (!appConfig.startMini) {
        //非最小化启动
        windowManager.show();
        windowManager.focus();
      } else if (Platform.isLinux) {
        //todo 待测试为什么要取消
        // windowManager.hide();
      }
    });
  }

  ///初始化快捷键
  initHotKey() async {
    await AppHotKeyHandler.unRegisterAll();
    final historyWindowHotKeys = appConfig.takeOverWinV ? Constants.winVHistoryWindowKeys : appConfig.historyWindowHotKeys;
    if (historyWindowHotKeys.isNotEmpty) {
      var hotKey = AppHotKeyHandler.toSystemHotKey(historyWindowHotKeys);
      AppHotKeyHandler.registerHistoryWindow(hotKey);
    }
    if (appConfig.syncFileHotKeys.isNotEmpty) {
      var hotKey = AppHotKeyHandler.toSystemHotKey(appConfig.syncFileHotKeys);
      AppHotKeyHandler.registerFileSync(hotKey);
    }
  }

  ///初始化 Win+V 接管状态，并以系统 DisabledHotkeys 当前值同步应用设置。
  Future<void> initWinVTakeover() async {
    if (!Platform.isWindows) {
      return;
    }
    final disabled = await isWinVDisabled();
    if (disabled && !appConfig.takeOverWinV) {
      await appConfig.setTakeOverWinV(true);
      return;
    }
    if (!disabled && appConfig.takeOverWinV) {
      final changed = await takeOverWinV();
      if (changed) {
        await restartExplorer();
      }
    }
  }

  void initMultiWindowEvent() {
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      var method = MultiWindowMethod.values.byName(call.method);
      switch (method) {
        case MultiWindowMethod.getHistories:
          int fromId = args["fromId"];
          final filter = SearchFilter.fromJson(args["filter"]);
          var historyDao = dbService.historyDao;
          final lst = await historyDao.getHistoriesPageByFilter(
            appConfig.userId,
            filter,
            fromId != 0,
            max(fromId, 0),
          );
          var devMap = devService.toIdNameMap();
          devMap[appConfig.devInfo.guid] = appConfig.device.displayName;
          var res = {
            "list": lst,
            "devInfos": devMap,
          };
          return jsonEncode(res);
        case MultiWindowMethod.getAllDevices:
          //加载所有设备
          final devices = await dbService.deviceDao.getAllDevices(appConfig.userId);
          return jsonEncode([appConfig.device, ...devices]);
        case MultiWindowMethod.getAllTagNames:
          //加载所有标签名
          final tagNames = await dbService.historyTagDao.getAllTagNames();
          return jsonEncode(tagNames);
        case MultiWindowMethod.getAllSources:
          //加载所有设备信息
          return jsonEncode(sourceService.appInfos);
        case MultiWindowMethod.copy:
          final id = args["id"];
          dbService.historyDao.getById(id).then(
            (history) async {
              if (history == null) return;
              await history.copyContent();
              clipboardManager.pasteToPreviousWindow();
            },
          );
          break;
        case MultiWindowMethod.copyContent:
          final content = args["content"];
          await clipboardManager.copy(ClipboardContentType.text, content);
          break;
        case MultiWindowMethod.getCompatibleOnlineDevices:
          var devices = devController.compatibleOnlineDevices;
          logger.info(tag, "devices $devices");
          return jsonEncode(devices);
        case MultiWindowMethod.syncFiles:
          final paths = (args["files"] as List<dynamic>).cast<String>();
          final items = paths.map((path) => DropItemFile(path)).toList(growable: false);
          final files = await pendingFileService.resolvePendingItems(items);
          var devices = List<Device>.empty(growable: true);
          for (var devMap in (args["devices"] as List<dynamic>)) {
            devices.add(Device.fromJson(devMap));
          }
          logger.info(tag, "files $paths");
          logger.info(tag, "devIds $devices");
          FileSyncHandler.sendFiles(
            devices: devices,
            files: files,
            context: Get.context!,
          );
          break;
        case MultiWindowMethod.storeWindowPos:
          var pos = args["pos"].toString();
          if (appConfig.recordHistoryDialogPosition) {
            appConfig.setHistoryDialogPosition(pos);
          }
          break;
        case MultiWindowMethod.closeWindow:
          var windowId = args["closeWindowId"] as int;
          multiWindowService.addHideWindow(windowId);
          break;
        case MultiWindowMethod.updateWindowSize:
          //判断是否记录窗体大小，并记录
          if (!appConfig.rememberPopupWindowSize) {
            break;
          }
          final type = WindowType.parse(args["type"]);
          final [width, height] = (args["size"] as String).split("x").map((item) => item.toDouble()).toList();
          final size = Size(width, height);
          await appConfig.updatePopupWindowSize(type, size);
          break;
        case MultiWindowMethod.updateHistoryTop:
          final id = args["id"] as int;
          final isTop = args["isTop"] as bool;
          await dbService.historyDao.setTop(id, isTop).then((v) async {
            if (v == null || v <= 0) return;
            final historyController = Get.find<HistoryController>();
            historyController.refreshData();
            var opRecord = newOperationRecord(
              Module.historyTop,
              OpMethod.update,
              id,
            );
            await dbService.opRecordDao.addAndNotify(opRecord);
          });
          break;
        case MultiWindowMethod.deleteHistory:
          final id = args["id"] as int;
          await dbService.historyDao.deleteByCascade(id);
          final historyController = Get.find<HistoryController>();
          historyController.refreshData();
          //添加删除记录
          var opRecord = newOperationRecord(
            Module.history,
            OpMethod.delete,
            id,
          );
          //通知其他设备
          await dbService.opRecordDao.addAndNotify(opRecord);
          break;
        default:
      }
      //都不符合，返回空
      return Future.value();
    });
  }

  void initChannel() {
    appConfig.clipChannel.setMethodCallHandler((call) async {
      var arguments = call.arguments;
      var method = ClipChannelMethod.values.byName(call.method);
      switch (method) {
        case ClipChannelMethod.ignoreNextCopy:
          break;
        case ClipChannelMethod.setTop:
          int id = arguments['id'];
          bool top = arguments['top'];
          return dbService.historyDao.setTop(id, top).then((cnt) {
            if (cnt != null && cnt > 0) {
              final historyController = Get.find<HistoryController>();
              historyController.updateData(
                (history) => history.id == id,
                (history) => history.copyWith(top: top),
                true,
              );
              return true;
            }
            return false;
          });
          break;
        case ClipChannelMethod.getHistory:
          int fromId = arguments["fromId"];
          var historyDao = dbService.historyDao;
          var lst = List<History>.empty();
          if (fromId == 0) {
            lst = await historyDao.getHistoriesTop100(appConfig.userId, Constants.historyFloatTypes);
          } else {
            lst = await historyDao.getHistoriesPage(appConfig.userId, fromId, Constants.historyFloatTypes);
          }
          var contentLst = lst
              .map(
                (e) => {
                  "id": e.id,
                  "content": e.content,
                  "time": e.time,
                  "top": e.top,
                  "type": e.type,
                },
              )
              .toList();
          return Future(() => contentLst);
        default:
      }
      return Future(() => false);
    });
    if (Platform.isAndroid) {
      appConfig.androidChannel.setMethodCallHandler((call) async {
        var method = AndroidChannelMethod.values.byName(call.method);
        switch (method) {
          case AndroidChannelMethod.onScreenOpened:
          case AndroidChannelMethod.onScreenUnlocked:
          case AndroidChannelMethod.onScreenClosed:
            ScreenOpenedListener.inst.notify(method);
            break;
          case AndroidChannelMethod.onFileOpened:
            final uri = call.arguments["uri"]?.toString();
            if (uri.isBlank == true) {
              logger.debug(tag, "ignore empty uri");
              break;
            }
            await _handleIncomingUri(uri!);
            break;
          case AndroidChannelMethod.onSmsChanged:
            final content = call.arguments["content"]!;
            HistoryDataListener.inst.onChanged(HistoryContentType.sms, content, null);
            break;
          default:
        }
        return Future(() => false);
      });
    }
  }

  Future<void> initShareHandler() async {
    if (!Platform.isAndroid) {
      return;
    }
    final handler = ShareHandlerPlatform.instance;
    appConfig.shareHandlerStream?.cancel();
    appConfig.shareHandlerStream = handler.sharedMediaStream.listen((SharedMedia media) async {
      await _handleExternalSharedMedia(media);
    });
  }

  /// 将 share_handler 的分享事件与 Android 原生补偿上送的打开文件事件收敛到同一套处理逻辑。
  Future<void> _handleExternalSharedMedia(SharedMedia media) async {
    logger.info(tag, "ShareMedia: ${media.attachments}, content: ${media.content}");
    final attachments = media.attachments;
    if (attachments != null) {
      final files = attachments
          .where((attachment) => attachment != null)
          .map((attachment) => attachment!.path)
          .map((path) => DropItemFile(path))
          .toList(growable: false);
      await _handleIncomingDropItems(files);
      return;
    }
    final content = media.content;
    if (content.isNullOrBlank != true) {
      await _handleIncomingUri(content!);
      return;
    }
    Global.showTipsDialog(context: Get.context!, text: TranslationKey.saveFileNotSupportDialogText.tr);
  }

  /// 统一处理直接可落地为本地路径的外部文件集合。
  Future<void> _handleIncomingDropItems(List<DropItem> files) async {
    logger.debug(tag, files);
    if (files.isEmpty) {
      return;
    }
    gotoOnlineDevicesPage(files);
  }

  /// 统一处理以 Uri 形式进入应用的外部文件，并复用现有文件信息解析能力。
  Future<void> _handleIncomingUri(String uri) async {
    final fileInfo = await uriFileReader.getFileInfoFromUri(uri);
    if (fileInfo == null) {
      Global.showSnackBarWarn(text: TranslationKey.failedToLoad.tr);
      logger.debug(tag, "未从uri中获取到文件名称和大小：uri = $uri");
      return;
    }
    final fileName = fileInfo.fileName;
    final size = fileInfo.size;
    logger.info(tag, "ShareMedia fileName $fileName, size $size");
    await _handleIncomingDropItems([DropItemFileUri(uri, fileName, size)]);
  }

  void gotoOnlineDevicesPage(List<DropItem> files) {
    var devices = devController.compatibleOnlineDevices;
    pendingFileService.addDropItems(files);
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (context) => FileSenderPage(
          devices: devices,
          onSendClicked: (List<Device> devices, List<DropItem> items) async {
            final files = await pendingFileService.resolvePendingItems(items);
            FileSyncHandler.sendFiles(
              devices: devices,
              files: files,
              context: context,
            );
            pendingFileService.clearPendingInfo();
            Navigator.pop(context);
            Global.showSnackBarSuc(text: TranslationKey.startSendFileToast.tr, context: Get.context!);
          },
          onItemRemove: (DropItem item) {
            pendingFileService.removeDropItem(item);
          },
        ),
      ),
    );
  }
}
