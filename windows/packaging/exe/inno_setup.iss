[Setup]
AppId={{APP_ID}}
AppVersion={{APP_VERSION}}
AppName={{DISPLAY_NAME}}
AppPublisher={{PUBLISHER_NAME}}
AppPublisherURL={{PUBLISHER_URL}}
AppSupportURL={{PUBLISHER_URL}}
AppUpdatesURL={{PUBLISHER_URL}}
DefaultDirName={{INSTALL_DIR_NAME}}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename={{OUTPUT_BASE_FILENAME}}
Compression=lzma
SolidCompression=yes
SetupIconFile={{SETUP_ICON_FILE}}
UninstallDisplayIcon={app}\{{EXECUTABLE_NAME}}
WizardStyle=modern
PrivilegesRequired={{PRIVILEGES_REQUIRED}}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
{% for locale in LOCALES %}
{% if locale == 'en' %}Name: "english"; MessagesFile: "compiler:Default.isl"{% endif %}
{% if locale == 'hy' %}Name: "armenian"; MessagesFile: "compiler:Languages\\Armenian.isl"{% endif %}
{% if locale == 'bg' %}Name: "bulgarian"; MessagesFile: "compiler:Languages\\Bulgarian.isl"{% endif %}
{% if locale == 'ca' %}Name: "catalan"; MessagesFile: "compiler:Languages\\Catalan.isl"{% endif %}
{% if locale == 'zh' %}Name: "chinesesimplified"; MessagesFile: "compiler:Languages\\ChineseSimplified.isl"{% endif %}
{% if locale == 'co' %}Name: "corsican"; MessagesFile: "compiler:Languages\\Corsican.isl"{% endif %}
{% if locale == 'cs' %}Name: "czech"; MessagesFile: "compiler:Languages\\Czech.isl"{% endif %}
{% if locale == 'da' %}Name: "danish"; MessagesFile: "compiler:Languages\\Danish.isl"{% endif %}
{% if locale == 'nl' %}Name: "dutch"; MessagesFile: "compiler:Languages\\Dutch.isl"{% endif %}
{% if locale == 'fi' %}Name: "finnish"; MessagesFile: "compiler:Languages\\Finnish.isl"{% endif %}
{% if locale == 'fr' %}Name: "french"; MessagesFile: "compiler:Languages\\French.isl"{% endif %}
{% if locale == 'de' %}Name: "german"; MessagesFile: "compiler:Languages\\German.isl"{% endif %}
{% if locale == 'he' %}Name: "hebrew"; MessagesFile: "compiler:Languages\\Hebrew.isl"{% endif %}
{% if locale == 'is' %}Name: "icelandic"; MessagesFile: "compiler:Languages\\Icelandic.isl"{% endif %}
{% if locale == 'it' %}Name: "italian"; MessagesFile: "compiler:Languages\\Italian.isl"{% endif %}
{% if locale == 'ja' %}Name: "japanese"; MessagesFile: "compiler:Languages\\Japanese.isl"{% endif %}
{% if locale == 'no' %}Name: "norwegian"; MessagesFile: "compiler:Languages\\Norwegian.isl"{% endif %}
{% if locale == 'pl' %}Name: "polish"; MessagesFile: "compiler:Languages\\Polish.isl"{% endif %}
{% if locale == 'pt' %}Name: "portuguese"; MessagesFile: "compiler:Languages\\Portuguese.isl"{% endif %}
{% if locale == 'ru' %}Name: "russian"; MessagesFile: "compiler:Languages\\Russian.isl"{% endif %}
{% if locale == 'sk' %}Name: "slovak"; MessagesFile: "compiler:Languages\\Slovak.isl"{% endif %}
{% if locale == 'sl' %}Name: "slovenian"; MessagesFile: "compiler:Languages\\Slovenian.isl"{% endif %}
{% if locale == 'es' %}Name: "spanish"; MessagesFile: "compiler:Languages\\Spanish.isl"{% endif %}
{% if locale == 'tr' %}Name: "turkish"; MessagesFile: "compiler:Languages\\Turkish.isl"{% endif %}
{% if locale == 'uk' %}Name: "ukrainian"; MessagesFile: "compiler:Languages\\Ukrainian.isl"{% endif %}
{% endfor %}

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: {% if CREATE_DESKTOP_ICON != true %}unchecked{% else %}checkedonce{% endif %}
[Files]
Source: "{{SOURCE_DIR}}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

#define MyAppUserModelID "top.coclyun.clipshare"
#define MyToastIconPath "data\\flutter_assets\\assets\\images\\logo\\logo.ico"

[Icons]
; Windows Toast 通过开始菜单快捷方式的 AppUserModelID 绑定应用身份和通知图标。
Name: "{autoprograms}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"; WorkingDir: "{app}"; IconFilename: "{app}\\{#MyToastIconPath}"; AppUserModelID: "{#MyAppUserModelID}"
Name: "{autodesktop}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"; WorkingDir: "{app}"; IconFilename: "{app}\\{#MyToastIconPath}"; AppUserModelID: "{#MyAppUserModelID}"; Tasks: desktopicon
[Run]
Filename: "{app}\\{{EXECUTABLE_NAME}}"; Description: "{cm:LaunchProgram,{{DISPLAY_NAME}}}"; Flags: {% if PRIVILEGES_REQUIRED == 'admin' %}runascurrentuser{% endif %} nowait postinstall skipifsilent

[Code]
#define MyAppExeName "{{EXECUTABLE_NAME}}"
#define ExplorerAdvancedRegPath "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
#define DisabledHotkeysValueName "DisabledHotkeys"

function RemoveWinVDisabledHotkey(Value: String): String;
var
    Index: Integer;
begin
    Result := Value;
    // 从后向前移除 V，避免删除字符后影响后续下标。
    for Index := Length(Result) downto 1 do
    begin
        if Uppercase(Copy(Result, Index, 1)) = 'V' then
        begin
            Delete(Result, Index, 1);
        end;
    end;
end;

function RestoreWinVHotkey(): Boolean;
var
    DisabledHotkeys: String;
    RestoredHotkeys: String;
begin
    Result := False;
    // 只读取并修改 DisabledHotkeys，保留其他被禁用的系统快捷键字符。
    if not RegQueryStringValue(HKCU, '{#ExplorerAdvancedRegPath}', '{#DisabledHotkeysValueName}', DisabledHotkeys) then
    begin
        exit;
    end;
    if Pos('V', Uppercase(DisabledHotkeys)) <= 0 then
    begin
        exit;
    end;
    RestoredHotkeys := RemoveWinVDisabledHotkey(DisabledHotkeys);
    if RestoredHotkeys = '' then
    begin
        RegDeleteValue(HKCU, '{#ExplorerAdvancedRegPath}', '{#DisabledHotkeysValueName}');
    end
    else
    begin
        RegWriteStringValue(HKCU, '{#ExplorerAdvancedRegPath}', '{#DisabledHotkeysValueName}', RestoredHotkeys);
    end;
    Result := True;
end;

procedure RestartExplorer();
var
    ResultCode: Integer;
    ExplorerPath: String;
begin
    // DisabledHotkeys 由 Explorer 读取，重启后才能立即恢复 Win+V。
    Exec('taskkill', '/F /IM explorer.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(1000);
    ExplorerPath := ExpandConstant('{win}\explorer.exe');
    if not Exec(ExplorerPath, '', ExpandConstant('{win}'), SW_SHOWNORMAL, ewNoWait, ResultCode) then
    begin
        Log('未能重启资源管理器');
    end;
end;

procedure TerminateAppProcess();
var
    ResultCode: Integer;
begin
    // 安装和卸载前都先结束正在运行的主程序，释放全局快捷键和安装目录文件句柄。
    if not Exec('taskkill', '/F /IM {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
        Log('未能终止进程，可能进程未运行');
    end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
    // 仅在开始安装时执行（用户点击安装按钮后）
    if CurStep = ssInstall then
    begin
        TerminateAppProcess();
    end;
end;

function InitializeUninstall(): Boolean;
begin
    // 卸载向导启动后立即结束主程序，避免运行中的应用继续占用 Win+V。
    TerminateAppProcess();
    Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
    // 卸载时独立恢复 Win+V，避免安装器强制结束应用后跳过应用内退出恢复。
    if CurUninstallStep = usUninstall then
    begin
        TerminateAppProcess();
        if RestoreWinVHotkey() then
        begin
            RestartExplorer();
        end;
    end;
end;
