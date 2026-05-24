@echo off
set TARGET_PID=%1
set EXTRACT_DIR=%2
for %%i in ("%~dp0..\..\..\..") do set "EXEC_DIR=%%~fi"
echo Waiting for ClipShare main process (pid=%TARGET_PID%) to exit...

:loop
tasklist /fi "pid eq %TARGET_PID%" | find "%TARGET_PID%" >nul || goto :update
timeout /t 1 /nobreak >nul
goto :loop

:update
echo Process has exited, starting update...
xcopy /s /y  "%EXTRACT_DIR%\*" "%EXEC_DIR%\"

if errorlevel 1 (
    echo ERROR: Update failed! Unable to copy files.
    echo Please check the update package and try again.
    pause
    exit \b 1
) else (
    echo Update completed successfully!
    explorer "%EXEC_DIR%\clipshare.exe"
    echo The update program will exit in 1 seconds
    timeout /t 1 /nobreak >nul
    exit
)