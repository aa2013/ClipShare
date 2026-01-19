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
cd ../ && fastforge package --platform linux --targets deb,appimage,rpm