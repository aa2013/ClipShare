<p align="center">
  <a href="./README.md">简体中文</a> |
  <span>English</span>
</p>

# ClipShare

ClipShare is a cross-platform clipboard synchronization tool based on Flutter, supporting synchronization of text, images, files, SMS, and other content across multiple devices.

- Official website: [https://clipshare.coclyun.top](https://clipshare.coclyun.top)
- Related repositories
  + Relay service: [ForwardServer](https://github.com/aa2013/ClipShareForwardServer)
  + Clipboard listener plugin: [ClipboardListener](https://github.com/aa2013/ClipboardListener)

## Project Origin

This project started because I wanted a clipboard synchronization tool on Android, but basically none could provide seamless background sync on Android 10+ and in public network environments (I am a bit lazy), so I decided to build it myself.

Currently, all platforms except iOS have been released. The iOS version is still in testing. If you want to participate in iOS testing and development, please pull the corresponding branch code:

+ ClipShare: [ClipShare-ios-dev](https://github.com/aa2013/ClipShare/tree/ios-support-dev)
+ Clipboard plugin: [ClipboardListener-ios](https://github.com/aa2013/ClipboardListener/tree/ios) 。

The iOS version can currently also be downloaded as an unsigned installation package in [issue#6](https://github.com/aa2013/ClipShare/issues/6)

## Current Tech Status and Plan

### Current Tech Stack

- Flutter + Dart (cross-platform UI and business layer)
- Native platform capabilities (Android / Windows / Linux / macOS)
- State management: currently mainly `GetX`, with a later plan to gradually migrate state management from `GetX` to `Riverpod`.

## Core Capabilities

- Multi-device clipboard synchronization (text, images, files, SMS)
- LAN device discovery and direct synchronization
- Public network relay synchronization (Forward Server)
- WebDAV / S3 object storage relay
- History management (search, filtering, tags, statistics, Excel export)
- File drag-and-drop sending and sync progress tracking
- Security capabilities: app password, re-authentication, encryption key configuration, etc.
+ Rule management (currently pure regex matching; version 1.5.0 will support custom scripts and content extraction)

## Sync Schemes

ClipShare currently supports three synchronization schemes:

+ Intranet:
  + Devices in the same subnet are auto-discovered and synchronized via Socket communication.
+ Public network:
  + Relay service: data forwarding through a relay service.
  + WebDAV / S3 as storage relay, with a notification service to trigger change notifications.

> Note: WebDAV/S3 storage relay is still an experimental feature

Relay service repository: [ForwardServer](https://github.com/aa2013/ClipShareForwardServer)

## Android Clipboard Listening Notes

There are currently two main listening paths on Android:

1. System log method: available on most systems, but in some ROMs (such as some OriginOS), usable logs may not be available.
2. System hidden API method: hidden APIs are invoked via reflection in shell/root processes. Compatibility is broader, but it may still be limited on deeply customized systems.

## Supported Platforms

| Platform | Status | Notes |
| --- | --- | --- |
| Android | ✅ | Supported |
| Windows | ✅ | Supported |
| Linux | ✅ | Supported |
| macOS | ✅ | Supported |
| iOS | ⚠️ | The repository includes an iOS project, but the current release workflow does not include iOS, and it is still in testing |

## Project Structure

### Top-level Directories

```text
assets/      # Static resources (images, built-in markdown, scripts, etc.)
docs/        # Documentation resources
go/          # Go service (notification service)
lib/         # Flutter main code, usually all development is under this directory
scripts/     # Local build and packaging scripts
android/     # Native Android project, usually modified only when native mixed development is needed
windows/     # Native Windows project, usually modified only when native mixed development is needed
macos/       # Native macOS project, usually modified only when native mixed development is needed
linux/       # Native Linux project, usually modified only when native mixed development is needed
ios/         # Native iOS project, usually modified only when native mixed development is needed
```

### Flutter Core Directory (`lib/app`)

```
lib/app/
  data/          # Data models, enums, repositories, database entities, and DAO
  exceptions/    # Custom exceptions
  handlers/      # Business handlers (sync, storage, backup, Socket, guide, etc.)
  listeners/     # Event listeners (device status, history changes, window events, etc.)
  modules/       # Page modules (each module usually includes page/controller/bindings)
  routes/        # Route definitions
  services/      # Global services (config, database, devices, tray, transport, tags, etc.)
  theme/         # Theme configuration
  translations/  # Internationalization translations
  utils/         # Utility classes and extensions
  widgets/       # Reusable UI components
  utils/         # Utility classes and a series of extension methods; all constants in the project are in `utils/Constants.dart`
```

### Main Page Module Notes

| Module | Purpose |
| --- | --- |
| `home_module` | Main page entry and navigation |
| `history_module` | History display and operations |
| `device_module` | Device discovery, pairing, and connection management |
| `search_module` | History search and filtering |
| `settings_module` | Application settings page |
| `statistics_module` | Statistical charts and data analysis |
| `sync_file_module` | File sync related pages |
| `authentication_module` | App authentication and password protection |
| `log_module` | Log viewing and troubleshooting |
| `clean_data_module` | Data cleanup |
| `db_editor_module` | Database debugging and SQL execution |
| `update_log_module` | Update log display |
| `about_module` | About page |
| `user_guide_module` | First-time user guide |
| `qr_code_scanner_module` | QR code scanner page |
| `working_mode_selection_module` | Android working mode selection (e.g., Shizuku/Root/Ignore) |
| `debug_module` | Debug capability entry |

### Additional Notes for the services Module (Text Version)

`services/` is the core runtime support layer, mainly responsible for:

- Configuration read/write (`config_service.dart`)
- Database lifecycle (`db_service.dart`)
- Device state maintenance (`device_service.dart`)
- Clipboard and source recording (`clipboard_service.dart`, `clipboard_source_service.dart`)
- Sync and connection management (`transport/`)
- Tray and window behaviors (`tray_service.dart`, `window_service.dart`, `window_control_service.dart`)
- File sync management (`history_sync_progress_service.dart`, `syncing_file_progress_service.dart`, `pending_file_service.dart`)

## Internationalization (i18n) Notes

Project i18n uses the `TranslationKey` enum to centrally manage translation keys. To add a new language, the recommended steps are:

1. Add keys in `lib/app/data/enums/translation_key.dart`.
2. Add the corresponding translation file under `lib/app/translations/`.
3. Register the language mapping in `app_translations.dart`.
4. Add the new language in the settings page language options.

This ensures a consistent key space across all languages, making missing-key checks and maintenance easier.

## Development Environment Requirements

- Flutter `3.35.x` (CI uses `3.35.3`)
- Dart SDK `>=3.8.0 <4.0.0`
- JDK 17 is required for Android builds
- Linux desktop builds require GTK and related dependencies (see `.github/workflows/build-linux.yml`)

## Run Locally

```bash
flutter pub get
flutter run
```

## Scripts

The project provides related scripts (located in `scripts/`):

### Build and Package

> Windows, Linux, and macOS require [Fastforge](https://fastforge.dev/getting-started)

- Android APK: `scripts/build_apk.bat`
- Windows Release (portable): `scripts/build_windows.bat`
- Windows EXE packaging (Fastforge): `scripts/build_windows_exe.bat`
- Linux packaging (Fastforge, deb/appimage/rpm): `scripts/build_linux.sh pack`
- macOS DMG packaging (Fastforge): `scripts/build_macos.sh`

GitHub Actions also provides corresponding platform pipelines, see `.github/workflows/`:

- `build-all.yml`
- `build-android.yml`
- `build-windows.yml`
- `build-linux.yml`
- `build-macos.yml`
- `build-notify-docker-image.yml`

### Code Generation

- Database code generation: `scripts/db_gen.bat`
- App icon generation: `scripts/icon_gen.bat`

## Database Code Generation

This project is based on `sqlite` and uses the [floor](https://pub.dev/packages/floor) framework.

The database framework may also be migrated in the future.

Steps:
+ If you need to add a new table
  + Add a new entity class in `lib/app/data/repository/entity/tables` and mark it with annotations
  + Then add a new DAO interface in `lib/app/data/repository/dao` and mark it with annotations
  + Then add the entity class to `tables` in `lib/app/services/db_service.dart`
  + Then add the corresponding DAO getter field in `_AppDb` in `lib/app/services/db_service.dart`
+ Modify SQL
  + Modify the SQL on the corresponding DAO interface methods
+ Modify version number
  + If modifications are complete and you are preparing a release or PR, please update the version number in the `@Database` annotation on `_AppDb` in `lib/app/data/repository/db_service.dart`, usually by incrementing it
  + Then add a version migration method in the `init` method in `lib/app/data/repository/db_service.dart`; note that DDL should be compatible with downgrade-then-upgrade cases, for example by using `IF NOT EXISTS` syntax or checking field existence
+ Finally, run `cd scripts` to enter the script directory, then execute `db_gen.bat` for code generation


## Optional: Self-host Notification Service (for Object Storage Relay)

The repository includes a Go implementation of the notification service: `go/notification`.

- Default listening port: `8083`
- Docker Compose example: `go/notification/docker-compose.yml`

Start (local Go):

```bash
cd go/notification
go run . -port 8083
```

## License

This project is licensed under [GPL-3.0](./LICENSE).
