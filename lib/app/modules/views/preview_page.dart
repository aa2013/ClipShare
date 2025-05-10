import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:share_plus/share_plus.dart';

class PreviewPage extends StatefulWidget {
  final ClipData clip;
  final bool onlyView;
  final bool single;

  const PreviewPage({
    super.key,
    required this.clip,
    this.onlyView = false,
    this.single = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _PreviewPageState();
  }
}

class _PreviewPageState extends State<PreviewPage> {
  final TransformationController _controller = TransformationController();
  static const tag = "PreviewPage";

  bool get isImageZoomed {
    //row 2 column 3 => scale
    return _controller.value.getRow(2) != Matrix4.identity().getRow(2);
  }

  int _current = 1;
  int _total = 1;
  bool _initFinished = false;
  var checkedList = <int>{};

  History get _currentImage => _images.isEmpty ? widget.clip.data : _images[_current - 1];
  late PageController _pageController;

  bool get _canPre => _current > 1;

  bool get _canNext => _current < _total;
  final List<History> _images = List.empty(growable: true);

  ConfigService? appConfig;
  DbService? dbService;
  int _pointerCnt = 0;

  @override
  void initState() {
    super.initState();
    if (widget.single) {
      _images.add(widget.clip.data);
      _current = 1;
      _total = 1;
      _initFinished = true;
      _pageController = PageController(initialPage: 0);
    } else {
      appConfig = Get.find<ConfigService>();
      dbService = Get.find<DbService>();
      dbService!.historyDao.getAllImages(appConfig!.userId).then((images) {
        _images.addAll(images);
        _total = _images.length;
        var i = images.indexWhere((item) => item.id == widget.clip.data.id);
        _current = i + 1;
        _pageController = PageController(initialPage: i);
        _initFinished = true;
        setState(() {});
      });
    }
    appConfig?.setSystemUIOverlayDarkStyle();
  }

  Future<void> _loadPreImage() async {
    if (!_canPre) return;
    _current--;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
    setState(() {});
  }

  Future<void> _loadNextImage() async {
    if (!_canNext) return;
    _current++;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
    setState(() {});
  }

  Widget renderImageItem(int idx, BoxConstraints ct) {
    var file = File(_images[idx].content);
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
    var header = SizedBox(
      height: 48,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            IconButton(
              hoverColor: Colors.white12,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: GestureDetector(
                      child: Text(
                        _currentImage.content,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onDoubleTap: () {
                        appConfig?.innerCopy = true;
                        Clipboard.setData(ClipboardData(text: _currentImage.content));
                        Global.showSnackBarSuc(
                          text: TranslationKey.copyPathSuccess.tr,
                          context: Get.context,
                        );
                      },
                    ),
                  ),
                  Text(
                    _currentImage.time,
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (!(appConfig?.isSmallScreen ?? true)) const SizedBox(width: 5),
            if (!(appConfig?.isSmallScreen ?? true))
              IconButton(
                hoverColor: Colors.white12,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
    var footer = SizedBox(
      height: 48,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            Visibility(
              visible: false,
              child: Checkbox(
                value: checkedList.contains(_currentImage.id),
                hoverColor: Colors.white12,
                onChanged: (checked) {
                  if (checked == null || !checked) {
                    checkedList.remove(_currentImage.id);
                  } else {
                    checkedList.add(_currentImage.id);
                  }
                  setState(() {});
                },
                side: const BorderSide(color: Colors.white70),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Center(
                child: Visibility(
                  visible: _total > 0,
                  child: Text(
                    "$_current/$_total",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !Platform.isLinux,
              child: IconButton(
                onPressed: () {
                  final path = _currentImage.content;
                  Share.shareXFiles([XFile(path)], text: TranslationKey.shareFile.tr);
                },
                hoverColor: Colors.white12,
                icon: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
          ],
        ),
      ),
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        // systemOverlayStyle: SystemUiOverlayStyle.light,
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
                            //listener解决PageView和InteractiveViewer之间的缩放与滚动冲突
                            child: Listener(
                              onPointerUp: (_) => setState(() {
                                _pointerCnt--;
                              }),
                              onPointerDown: (_) {
                                _pointerCnt++;
                                setState(() {});
                              },
                              child: PageView.builder(
                                itemCount: _images.length,
                                controller: _pageController,
                                physics: _pointerCnt == 2 || isImageZoomed ? const NeverScrollableScrollPhysics() : null,
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
                                    onSecondaryTapDown: (details) {
                                      final imgPath = _images[idx].content;
                                      final position = details.globalPosition - const Offset(0, 70);
                                      showMenu(imgPath, position);
                                    },
                                    onLongPressStart: (details) {
                                      if (PlatformExt.isDesktop) {
                                        return;
                                      }
                                      final imgPath = _images[idx].content;
                                      final position = details.globalPosition;
                                      showMenu(imgPath, position);
                                    },
                                  );
                                },
                              ),
                            ),
                            onSecondaryTap: () => Navigator.pop(context),
                            onDoubleTap: () {
                              _toggleZoom(context.size!.center(Offset.zero));
                            },
                          ),
                          header,
                          Visibility(
                            visible: _canPre && MediaQuery.of(context).size.width >= Constants.smallScreenWidth,
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
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                    child: IconButton(
                                      hoverColor: Colors.white12,
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: _canPre ? _loadPreImage : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _canNext && MediaQuery.of(context).size.width >= Constants.smallScreenWidth,
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
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                    child: IconButton(
                                      hoverColor: Colors.white12,
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: _canNext ? _loadNextImage : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
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

  ///右键菜单
  void showMenu(String imgPath, Offset? position) {
    final menu = ContextMenu(
      entries: [
        if (Platform.isAndroid && !appConfig!.saveToPictures && imgPath.startsWith(appConfig!.androidPrivatePicturesPath))
          MenuItem(
            label: TranslationKey.saveToAlbum.tr,
            icon: Icons.save_alt,
            onSelected: () async {
              //如果没有权限则请求
              if (!(await PermissionHelper.testAndroidStoragePerm())) {
                await PermissionHelper.reqAndroidStoragePerm();
              }
              final file = File(imgPath);
              final fileName = file.fileName;
              final newPath = "${Constants.androidPicturesPath}/${Constants.appName}/$fileName";
              try {
                file.copySync(newPath);
                Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: context);
                final androidChannelService = Get.find<AndroidChannelService>();
                androidChannelService.notifyMediaScan(newPath);
              } catch (err, stack) {
                Log.error(tag, "$err $stack");
                Global.showSnackBarWarn(text: TranslationKey.saveFailed.tr, context: context);
              }
            },
          ),
        if (PlatformExt.isDesktop)
          MenuItem(
            label: TranslationKey.openWithOtherApplications.tr,
            icon: Icons.open_in_new,
            onSelected: () async {
              await OpenFile.open(imgPath);
            },
          ),
        MenuItem(
          label: TranslationKey.openFilePos.tr,
          icon: Icons.folder_outlined,
          onSelected: () async {
            await OpenFile.open(File(imgPath).parent.path);
          },
        ),
        if (PlatformExt.isDesktop)
          MenuItem(
            label: TranslationKey.close.tr,
            icon: Icons.close,
            onSelected: () async {
              Navigator.pop(context);
            },
          ),
      ],
      position: position,
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
  }

  void _toggleZoom(Offset focalPoint) {
    if (isImageZoomed) {
      _controller.value = Matrix4.identity();
    } else {
      _controller.value = Matrix4.identity()
        //这里的系数=1-新的放大倍数
        ..translate(-1.5 * focalPoint.dx, -1.5 * focalPoint.dy)
        ..scale(2.5, 2.5);
    }
  }

  @override
  void dispose() {
    super.dispose();
    appConfig?.setSystemUIOverlayAutoStyle();
  }
}
