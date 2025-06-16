@echo off
setlocal enabledelayedexpansion

:: 1. 进入 APK 所在目录
cd /d "%~dp0..\build\app\outputs\apk\release"

:: 2. 查找 app-arm64-v8a 开头的 APK 文件
for %%f in (app-arm64-v8a*.apk) do (
    set "apk_file=%%f"
    goto :install
)

:: 3. 如果没有找到文件，报错并退出
echo Error: No APK file found matching 'app-arm64-v8a*.apk'
exit /b 1

:install
:: 4. 执行 adb install
echo Installing !apk_file! ...
rem 指定设备：adb -s R5CWA0FFS3D install ....
adb install -r -d "!apk_file!"

if !errorlevel! equ 0 (
    echo APK installed successfully.
) else (
    echo Failed to install APK.
)
endlocal