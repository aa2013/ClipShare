import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/providers/settings/sync/sync_settings_provider.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/core/utils/permission/permission_helper.dart';
import 'package:clipshare/core/utils/snackbar.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/theme_aware_context_menu_item.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:share_plus/share_plus.dart';

/// 预览页路由参数，go_router 通过 extra 携带历史记录与展示配置。
class PreviewRouteArgs {
  final History history;
  final bool onlyView;
  final bool single;

  const PreviewRouteArgs({
    required this.history,
    this.onlyView = false,
    this.single = false,
  });
}

/// 图片历史全屏预览页，支持单张查看与全部图片滑动浏览。
class PreviewPage extends ConsumerStatefulWidget {
  final History history;

  /// 仅查看模式：不展示底部操作栏。
  final bool onlyView;

  /// 单张模式：只显示传入的这条记录，不再加载全部图片做滑动浏览。
  final bool single;

  const PreviewPage({
    super.key,
    required this.history,
    this.onlyView = false,
    this.single = false,
  });

  @override
  ConsumerState<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends ConsumerState<PreviewPage> {
  static const tag = 'PreviewPage';
  final TransformationController _controller = TransformationController();

  /// 是否处于放大状态，通过变换矩阵第二行是否仍等于单位矩阵判断。
  bool get isImageZoomed => _controller.value.getRow(2) != Matrix4.identity().getRow(2);

  int _current = 1;
  int _total = 1;
  bool _initFinished = false;
  bool _showInfo = true;

  History get _currentImage => _images.isEmpty ? widget.history : _images[_current - 1];

  PageController? _pageController;
  final List<History> _images = [];

  /// 触点计数：PageView 与 InteractiveViewer 共享手势，双指操作时
  /// 需禁用 PageView 翻页，让位给图片缩放。
  int _pointerCnt = 0;

  /// 是否已进入全黑预览态，首次布局时按预览页样式调整系统栏。
  bool _didSetDarkOverlay = false;

  /// 进入预览前的应用主题亮度，用于离开时恢复原系统栏样式。
  bool _wasDarkTheme = false;
  Color? _restoreNavColor;
  Brightness? _restoreNavIconBrightness;

  @override
  void initState() {
    super.initState();
    if (widget.single) {
      _images.add(widget.history);
      _current = 1;
      _total = 1;
      _initFinished = true;
      _pageController = PageController(initialPage: 0);
    } else {
      _loadAllImages();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSetDarkOverlay) {
      return;
    }
    _didSetDarkOverlay = true;
    _wasDarkTheme = context.currentTheme.brightness == Brightness.dark;
    final scheme = context.currentTheme.colorScheme;
    // 离开时需要按进入前主题还原系统栏，记录与 context_extension 自动样式一致的配置
    _restoreNavColor = _wasDarkTheme ? scheme.surfaceBright : scheme.surface;
    _restoreNavIconBrightness = _wasDarkTheme ? Brightness.light : Brightness.dark;
    context.setSystemUIOverlayDarkStyle();
  }

  /// 加载全部图片历史并定位到传入记录，实现左右滑动浏览。
  Future<void> _loadAllImages() async {
    final db = await ref.read(appDbProvider.future);
    final images = await db.historyDao.getAllImages();
    if (!mounted) {
      return;
    }
    _images.addAll(images);
    _total = _images.length;
    final i = images.indexWhere((item) => item.id == widget.history.id);
    final index = i < 0 ? 0 : i;
    _current = index + 1;
    _pageController = PageController(initialPage: index);
    _initFinished = true;
    setState(() {});
  }

  bool get _canPre => _current > 1;

  bool get _canNext => _current < _total;

  void _loadPreImage() {
    if (!_canPre) return;
    _current--;
    _pageController?.previousPage(
      duration: 200.ms,
      curve: Curves.ease,
    );
    setState(() {});
  }

  void _loadNextImage() {
    if (!_canNext) return;
    _current++;
    _pageController?.nextPage(
      duration: 200.ms,
      curve: Curves.ease,
    );
    setState(() {});
  }

  Widget renderImageItem(int idx, BoxConstraints ct) {
    final file = File(_images[idx].content);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: ct.maxWidth,
        height: ct.maxHeight,
      );
    }
    return EmptyContent(
      description: TranslationKey.previewPageNoSuchFile.tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    const height = 48.0;
    final isCompactScreen = context.isCompactScreen;
    final header = SizedBox(
      height: height,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Row(
          children: [
            const SizedBox(width: 15),
            IconButton(
              hoverColor: Colors.white12,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: GestureDetector(
                      onDoubleTap: () {
                        // 双击复制当前图片路径文本
                        clipboardManager.copy(
                          ClipboardContentType.text,
                          _currentImage.content,
                        );
                        snackbar.success(
                          context,
                          TranslationKey.copyPathSuccess.tr,
                        );
                      },
                      child: Text(
                        _currentImage.content,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _currentImage.time,
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
            // 小屏下仅保留返回按钮，避免顶栏拥挤
            if (!isCompactScreen) const SizedBox(width: 5),
            if (!isCompactScreen)
              IconButton(
                hoverColor: Colors.white12,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
    final footer = SizedBox(
      height: height,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Visibility(
                  visible: _total > 0,
                  child: Text(
                    '$_current/$_total',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            if (!isLinux)
              IconButton(
                onPressed: () {
                  Share.shareXFiles(
                    [XFile(_currentImage.content)],
                    text: TranslationKey.shareFile.tr,
                  );
                },
                hoverColor: Colors.white12,
                icon: const Icon(Icons.share, color: Colors.white, size: 15),
              ),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, ct) {
              return SizedBox(
                width: ct.maxWidth,
                height: ct.maxHeight,
                child: _initFinished
                    ? Stack(
                        children: [
                          GestureDetector(
                            // 右击空白区域关闭预览
                            onSecondaryTap: () => context.pop(),
                            // 双击空白区域放大或复位
                            onDoubleTap: () => _toggleZoom(
                              Offset(ct.maxWidth / 2, ct.maxHeight / 2),
                            ),
                            // Listener 解决 PageView 与 InteractiveViewer 之间的缩放与滚动冲突
                            child: Listener(
                              onPointerUp: (_) => setState(() => _pointerCnt--),
                              onPointerDown: (_) {
                                _pointerCnt++;
                                setState(() {});
                              },
                              child: PageView.builder(
                                itemCount: _images.length,
                                controller: _pageController,
                                physics: _pointerCnt == 2 || isImageZoomed
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                onPageChanged: (idx) {
                                  _current = idx + 1;
                                  setState(() {});
                                },
                                itemBuilder: (ctx, idx) {
                                  return GestureDetector(
                                    child: InteractiveViewer(
                                      maxScale: 15.0,
                                      transformationController: _controller,
                                      child: renderImageItem(idx, ct),
                                    ),
                                    onTap: () {
                                      setState(() => _showInfo = !_showInfo);
                                    },
                                    onSecondaryTapDown: (details) {
                                      final imgPath = _images[idx].content;
                                      final position = details.globalPosition -
                                          const Offset(0, 70);
                                      showMenu(imgPath, position);
                                    },
                                    // TODO: 移动端长按菜单依赖“保存到相册”能力，尚未迁移，恢复后放开：
                                    // onLongPressStart: (details) {
                                    //   if (isDesktop) {
                                    //     return;
                                    //   }
                                    //   final imgPath = _images[idx].content;
                                    //   final position = details.globalPosition;
                                    //   showMenu(imgPath, position);
                                    // },
                                  );
                                },
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: 150.ms,
                            top: _showInfo ? 0 : -height,
                            left: 0,
                            right: 0,
                            child: header,
                          ),
                          Visibility(
                            visible: _showInfo &&
                                _canPre &&
                                context.media.size.width >= smallScreenWidth,
                            child: Positioned(
                              left: 10,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    child: IconButton(
                                      hoverColor: Colors.white12,
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: _canPre
                                          ? _loadPreImage
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _showInfo &&
                                _canNext &&
                                context.media.size.width >= smallScreenWidth,
                            child: Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    child: IconButton(
                                      hoverColor: Colors.white12,
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: _canNext
                                          ? _loadNextImage
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: 150.ms,
                            bottom: _showInfo ? 0 : -height,
                            left: 0,
                            right: 0,
                            child: Visibility(
                              visible: !widget.onlyView,
                              child: footer,
                            ),
                          ),
                        ],
                      )
                    : const Loading(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 展示图片右键菜单。
  void showMenu(String imgPath, Offset? position) {
    final isAndroidDataPath = imgPath.startsWith(androidDataPath);
    final syncSettings = ref.read(syncSettingsProvider).requireValue;
    final appPaths = ref.read(appPathsProvider).requireValue;
    final save2Pictures = syncSettings.saveToPictures;
    final menu = ContextMenu(
      entries: [
        if (isAndroidDataPath || (isIOS && !save2Pictures))
          MyMenuItem(
            label: TranslationKey.saveToAlbum.tr,
            icon: Icons.save_alt,
            onSelected: () async {
              if (Platform.isAndroid) {
                final rootStorePath = appPaths.rootStorePath;
                final localDeviceInfo = ref.read(localDeviceInfoProvider).requireValue;
                final osVersion = localDeviceInfo.androidOsVersion;
                //如果没有权限则请求
                if (!(await PermissionHelper.testAndroidStoragePerm(rootStorePath, osVersion))) {
                  await PermissionHelper.reqAndroidStoragePerm(rootStorePath, osVersion);
                }
                final originFile = File(imgPath);
                final fileName = originFile.fileName;
                // 根据配置决定新路径
                String newPath = '${appPaths.imageStorePath}/$fileName'.normalizePath;
                if(newPath.startsWith(androidDataPath) || newPath==originFile.normalizePath || save2Pictures){
                  //私有目录 或 等于原始路径 或 保存到相册
                  newPath = '$androidPicturesPath/$appName/$fileName'.normalizePath;
                }
                try {
                  await File(newPath).parent.create(recursive: true);
                  // 先读入内存再写入，避免 File.copy 自复制时先删目标文件导致 0B
                  final bytes = await originFile.readAsBytes();
                  await File(newPath).writeAsBytes(bytes);
                  if (mounted) {
                    snackbar.success(
                      context,
                      TranslationKey.saveSuccess.tr,
                    );
                  }
                  //todo
                  // final androidChannelService = Get.find<AndroidChannelService>();
                  // androidChannelService.notifyMediaScan(newPath);
                } catch (err, stack) {
                  logger.error(tag, '$err $stack');
                  if (!mounted) {
                    return;
                  }
                  snackbar.warn(context, TranslationKey.saveFailed.tr);
                }
              } else {
                if (await PermissionHelper.checkIOSPhotoPermission()) {
                  if (!await PermissionHelper.reqIOSPhotoPermission()) {
                    if(mounted) {
                      unawaited(dialogManager.tips(
                        context,
                        text: TranslationKey.noPhotoPermission.tr,
                      ));
                    }
                    return;
                  }
                  final file = File(imgPath);
                  final bytes = await file.readAsBytes();
                  final imageSaver = ImageGallerySaver();
                  await imageSaver.saveImage(bytes);
                  if (!mounted) {
                    return;
                  }
                  snackbar.success(context, TranslationKey.saveSuccess.tr);
                } else {
                  if(mounted) {
                    unawaited(dialogManager.tips(
                      context,
                      text: TranslationKey.noPhotoPermission.tr,
                    ));
                  }
                }
              }
            },
          ),
        if (isDesktop)
          MyMenuItem(
            label: TranslationKey.openWithOtherApplications.tr,
            icon: Icons.open_in_new,
            onSelected: () {
              OpenFile.open(imgPath);
            },
          ),
        MyMenuItem(
          label: TranslationKey.openFilePos.tr,
          icon: Icons.folder_outlined,
          onSelected: () {
            File(imgPath).openPath();
          },
        ),
        if (isDesktop)
          MyMenuItem(
            label: TranslationKey.close.tr,
            icon: Icons.close,
            onSelected: () {
              context.pop();
            },
          ),
      ],
      position: position,
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
  }

  /// 以指定焦点放大 2.5 倍，再次调用复位。
  ///
  /// 平移系数取 -(放大倍数-1)，保证焦点处的画面内容不发生跳动。
  void _toggleZoom(Offset focalPoint) {
    if (isImageZoomed) {
      _controller.value = Matrix4.identity();
    } else {
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          -1.5 * focalPoint.dx,
          -1.5 * focalPoint.dy,
          0.0,
          1.0,
        )
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController?.dispose();
    if (_didSetDarkOverlay) {
      // dispose 时已无法使用 context，按进入前记录的主题亮度还原系统栏样式
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final base = _wasDarkTheme
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light;
        SystemChrome.setSystemUIOverlayStyle(
          base.copyWith(
            systemNavigationBarColor: _restoreNavColor,
            systemNavigationBarIconBrightness: _restoreNavIconBrightness,
          ),
        );
      });
    }
    super.dispose();
  }
}
