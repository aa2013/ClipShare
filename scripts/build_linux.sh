#!/bin/bash

set -e

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 读取版本号
VERSION=$(grep "version:" ${PROJECT_ROOT}/pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUMBER=$(grep "version:" ${PROJECT_ROOT}/pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f2)

# 构建 Flutter Linux Release 版本
BUILD_DIR="${PROJECT_ROOT}/build/linux/x64/release"
BUNDLE_DIR="${BUILD_DIR}/bundle"
build_flutter() {
    echo "========================================="
    echo "构建 Flutter Linux Release"
    echo "========================================="
    echo "项目目录: ${PROJECT_ROOT}"
    echo "版本: ${VERSION}+${BUILD_NUMBER}"
    echo ""

    cd ${PROJECT_ROOT}

    echo "获取 Flutter 依赖..."
    flutter pub get

    echo "构建 Flutter Linux Release..."
    flutter build linux --release

    echo ""
    echo "Flutter Linux Release 构建完成!"
    echo "输出目录: ${BUNDLE_DIR}"
    echo ""
}

pack_fastforge() {
    # https://fastforge.dev/zh/getting-started
    # 1. dart pub global activate fastforge # fastforge 配置环境变量
    # 2. appimage:
    # 2.1 sudo apt install locate
    # 2.2 wget -O appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    #      chmod +x appimagetool
    #      sudo mv appimagetool /usr/local/bin/
    # 3. rpm
    # 3.1 Debian/Ubuntu: apt install rpm patchelf
    # 3.2 Fedora: dnf install gcc rpm-build rpm-devel rpmlint make python bash coreutils diffutils patch rpmdevtools patchelf
    # 3.3 Arch: yay -S rpmdevtools patchelf or pamac install rpmdevtools patchelf
    cd "$PROJECT_ROOT" && fastforge package --platform linux --targets deb,appimage,rpm
}

# 打包为 AppImage，仅用于开发过程
# AppImage 配置目录
APPIMAGE_DIR="${SCRIPT_DIR}/quick-appimage"
# AppImage 输出目录
APPIMAGE_OUTPUT_DIR="${PROJECT_ROOT}/build/appimage"
mkdir -p ${APPIMAGE_OUTPUT_DIR}
pack_appimage() {
    echo "========================================="
    echo "打包 AppImage"
    echo "!!! 仅开发过程中的测试用途！！ 请不要将此方法打包出来的镜象投入使用"
    echo "========================================="
    echo "版本: ${VERSION}+${BUILD_NUMBER}"
    echo ""

    # 检查构建目录是否存在
    if [ ! -d "${BUNDLE_DIR}" ]; then
        echo "错误: 构建目录不存在: ${BUNDLE_DIR}"
        echo "请先运行: $0 build"
        exit 1
    fi

    # 检查可执行文件
    if [ ! -f "${BUNDLE_DIR}/clipshare" ]; then
        echo "错误: 可执行文件不存在: ${BUNDLE_DIR}/clipshare"
        exit 1
    fi

    # 下载 appimagetool（如果不存在）
    APPIAGETOOL="${APPIMAGE_OUTPUT_DIR}/appimagetool-x86_64.AppImage"
    if [ ! -f "$APPIAGETOOL" ]; then
        echo "下载 appimagetool..."
        wget --no-check-certificate --progress=bar -O "$APPIAGETOOL" \
            https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    fi
    # 确保 appimagetool 有执行权限
    chmod +x "$APPIAGETOOL"

    # 准备 AppDir
    APPDIR="${APPIMAGE_OUTPUT_DIR}/AppDir"
    rm -rf ${APPDIR}
    mkdir -p ${APPDIR}/usr/bin
    mkdir -p ${APPDIR}/usr/lib
    mkdir -p ${APPDIR}/usr/share/applications
    mkdir -p ${APPDIR}/usr/share/icons/hicolor/256x256/apps
    mkdir -p ${APPDIR}/usr/share/icons/hicolor/512x512/apps
    mkdir -p ${APPDIR}/usr/share/clipshare

    # 复制可执行文件
    echo "复制可执行文件..."
    cp ${BUNDLE_DIR}/clipshare ${APPDIR}/usr/bin/clipshare
    chmod +x ${APPDIR}/usr/bin/clipshare

    # 复制库文件（Flutter 期望库在相对于可执行文件的 lib/ 目录下）
    if [ -d "${BUNDLE_DIR}/lib" ]; then
        echo "复制库文件..."
        cp -r ${BUNDLE_DIR}/lib ${APPDIR}/usr/bin/
    fi

    # 复制数据目录（Flutter 期望数据在相对于可执行文件的 data/ 目录下）
    if [ -d "${BUNDLE_DIR}/data" ]; then
        echo "复制数据目录..."
        cp -r ${BUNDLE_DIR}/data ${APPDIR}/usr/bin/
    fi

    # 复制 files 目录（如果存在）
    if [ -d "${BUNDLE_DIR}/files" ]; then
        echo "复制 files 目录..."
        cp -r ${BUNDLE_DIR}/files ${APPDIR}/usr/bin/
    fi

    # 创建 AppRun 脚本
    echo "创建 AppRun 脚本..."
    if [ -f "${APPIMAGE_DIR}/AppRun" ]; then
        cp ${APPIMAGE_DIR}/AppRun ${APPDIR}/AppRun
    else
        printf '#!/bin/bash\nSELF=$(readlink -f "$0")\nHERE=${SELF%%/*}\nexport PATH="${HERE}/usr/bin:${PATH}"\nexport LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"\nexec "${HERE}/usr/bin/clipshare" "$@"\n' > ${APPDIR}/AppRun
    fi
    chmod +x ${APPDIR}/AppRun

    # 创建 .desktop 文件
    echo "创建 .desktop 文件..."
    if [ -f "${APPIMAGE_DIR}/ClipShare.desktop" ]; then
        cp ${APPIMAGE_DIR}/ClipShare.desktop ${APPDIR}/ClipShare.desktop
    else
        printf '[Desktop Entry]\nType=Application\nName=ClipShare\nName[zh_CN]=ClipShare 剪贴板同步\nComment=Cross-platform clipboard synchronization tool\nComment[zh_CN]=跨平台剪贴板同步工具\nExec=clipshare\nIcon=clipshare\nTerminal=false\nCategories=Utility;\nStartupNotify=true\nKeywords=clipboard;sync;share;transfer;\n' > ${APPDIR}/ClipShare.desktop
    fi

    # 复制图标
    echo "复制图标..."
    if [ -f "${PROJECT_ROOT}/assets/images/logo/logo.png" ]; then
        if command -v convert &> /dev/null; then
            convert ${PROJECT_ROOT}/assets/images/logo/logo.png -resize 256x256 ${APPDIR}/clipshare.png
            convert ${PROJECT_ROOT}/assets/images/logo/logo.png -resize 256x256 ${APPDIR}/ClipShare.png
            convert ${PROJECT_ROOT}/assets/images/logo/logo.png -resize 256x256 ${APPDIR}/.DirIcon
            convert ${PROJECT_ROOT}/assets/images/logo/logo.png -resize 256x256 ${APPDIR}/usr/share/icons/hicolor/256x256/apps/clipshare.png
            convert ${PROJECT_ROOT}/assets/images/logo/logo.png -resize 512x512 ${APPDIR}/usr/share/icons/hicolor/512x512/apps/clipshare.png
        else
            cp ${PROJECT_ROOT}/assets/images/logo/logo.png ${APPDIR}/clipshare.png
            cp ${PROJECT_ROOT}/assets/images/logo/logo.png ${APPDIR}/ClipShare.png
            cp ${PROJECT_ROOT}/assets/images/logo/logo.png ${APPDIR}/.DirIcon
            cp ${PROJECT_ROOT}/assets/images/logo/logo.png ${APPDIR}/usr/share/icons/hicolor/256x256/apps/clipshare.png
        fi
    else
        echo "警告: 未找到图标文件"
    fi

    # 创建 AppImage
    echo ""
    echo "创建 AppImage..."
    OUTPUT_FILE="${APPIMAGE_OUTPUT_DIR}/ClipShare-${VERSION}.AppImage"
    ARCH=$(uname -m)

    ${APPIAGETOOL} ${APPDIR} ${OUTPUT_FILE}

    if [ -f "${OUTPUT_FILE}" ]; then
        echo ""
        echo "========================================="
        echo "AppImage 打包成功!"
        echo "========================================="
        echo "输出文件: ${OUTPUT_FILE}"
        echo "文件大小: $(du -h ${OUTPUT_FILE} | cut -f1)"
        echo ""
        echo "如何使用:"
        echo "  1. 给文件添加执行权限:"
        echo "     chmod +x ${OUTPUT_FILE}"
        echo ""
        echo "  2. 运行 AppImage:"
        echo "     ./${OUTPUT_FILE}"
        echo ""
    else
        echo "错误: AppImage 创建失败"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "ClipShare Linux 构建和打包脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 build            - 构建 Flutter Linux Release 版本"
    echo "  $0 pack             - 打包deb,appimage,rpm"
    echo "  $0 pack_appimage    - 打包appimage，用于开发过程快速打包"
    echo "  $0 help             - 显示此帮助信息"
    echo ""
    echo "版本: ${VERSION}+${BUILD_NUMBER}"
}

# 主函数
main() {
    case "${1:-help}" in
        build)
            build_flutter
            ;;
        pack)
            pack_fastforge
            ;;
        pack_appimage)
            pack_appimage
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
