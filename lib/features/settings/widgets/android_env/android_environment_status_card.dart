import 'package:clipshare/core/services/clipboard/android_environment_status_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/features/settings/utils/settings_text_styles.dart';
import 'package:clipshare/features/settings/widgets/environment_status_card.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Android 工作环境状态卡。
///
/// 只负责把 [AndroidEnvironmentStatus] 翻译成图标、配色与文案，
/// 卡片本体复用 [EnvironmentStatusCard]；检查逻辑与状态流转由 provider 承担。
class AndroidEnvironmentStatusCard extends ConsumerWidget {
  /// 环境状态图标尺寸
  static const double _iconSize = 40;

  /// 加载态图标尺寸
  static const double _loadingIconSize = 32;

  /// 状态色在卡片底色上的叠加透明度，深色主题下需要更明显的着色
  static const double _darkOverlayAlpha = 0.16;
  static const double _lightOverlayAlpha = 0.08;

  const AndroidEnvironmentStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // status 为 null 表示首轮检查未完成，按加载态展示
    final status = ref.watch(androidEnvironmentStatusProvider).value;
    final androidOsVersion = ref.watch(localDeviceInfoProvider).value?.androidOsVersion;
    return EnvironmentStatusCard(
      icon: _buildIcon(status),
      backgroundColor: _buildBackgroundColor(context, status),
      tipContent: _buildTipContent(context, status),
      tipDesc: _buildTipDesc(context, status, androidOsVersion),
      action: _buildAction(),
      onTap: () => ref.read(androidEnvironmentStatusProvider.notifier).recover(),
    );
  }

  /// 环境结论图标：就绪为对勾、缺失授权为警告、未选择工作模式为屏蔽
  Widget _buildIcon(AndroidEnvironmentStatus? status) {
    if (status == null) {
      return const Loading(width: _loadingIconSize);
    }
    return switch (status.health) {
      AndroidEnvironmentHealth.normal => const Icon(
        Icons.check_circle_outline_outlined,
        size: _iconSize,
        color: Colors.blue,
      ),
      AndroidEnvironmentHealth.warning => const Icon(
        Icons.warning,
        size: _iconSize,
      ),
      AndroidEnvironmentHealth.ignored => const Icon(
        Icons.block_outlined,
        size: _iconSize,
        color: Colors.blueGrey,
      ),
    };
  }

  /// 就绪态沿用卡片默认底色，其余状态叠加对应状态色
  Color? _buildBackgroundColor(BuildContext context, AndroidEnvironmentStatus? status) {
    if (status == null) {
      return null;
    }
    return switch (status.health) {
      AndroidEnvironmentHealth.normal => null,
      AndroidEnvironmentHealth.warning => _overlayToneColor(context, context.currentTheme.colorScheme.error),
      // AndroidEnvironmentHealth.ignored => _overlayToneColor(context, Colors.blueGrey),
      AndroidEnvironmentHealth.ignored => null,
    };
  }

  /// 在卡片底色上叠加一层低透明度状态色，保留卡片原有质感
  Color _overlayToneColor(BuildContext context, Color tone) {
    final theme = context.currentTheme;
    final base = theme.cardTheme.color ?? theme.colorScheme.surface;
    final alpha = theme.brightness == Brightness.dark ? _darkOverlayAlpha : _lightOverlayAlpha;
    return Color.alphaBlend(tone.withValues(alpha: alpha), base);
  }

  /// 状态标题：Shizuku 就绪时使用更醒目的字号，作为工作环境可用的正向反馈
  Widget _buildTipContent(BuildContext context, AndroidEnvironmentStatus? status) {
    final theme = context.currentTheme;
    if (status == null) {
      return Text(
        TranslationKey.envStatusLoadingText.tr,
        style: theme.textTheme.titleMedium,
      );
    }
    final emphasized = status.health == AndroidEnvironmentHealth.normal && status.workingMode == EnvironmentType.shizuku;
    return Text(
      _modeTitleKey(status).tr,
      style: emphasized
          ? theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey,
            )
          : theme.textTheme.titleMedium,
    );
  }

  /// 按工作模式取状态标题
  TranslationKey _modeTitleKey(AndroidEnvironmentStatus status) {
    return switch (status.workingMode) {
      EnvironmentType.shizuku => TranslationKey.shizukuModeStatusTitle,
      EnvironmentType.root => TranslationKey.rootModeStatusTitle,
      EnvironmentType.androidPre10 => TranslationKey.noSpecialPermissionRequired,
      EnvironmentType.none => TranslationKey.envPermissionIgnored,
    };
  }

  /// 状态描述：就绪态说明环境可用性，其余状态说明缺失授权或服务未运行
  Widget _buildTipDesc(
    BuildContext context,
    AndroidEnvironmentStatus? status,
    double? androidOsVersion,
  ) {
    if (status == null) {
      return const SizedBox.shrink();
    }
    final desc = switch (status.health) {
      AndroidEnvironmentHealth.normal => _normalDescText(status, androidOsVersion),
      AndroidEnvironmentHealth.warning => TranslationKey.serverNotRunningDesc.tr,
      AndroidEnvironmentHealth.ignored => TranslationKey.envPermissionIgnoredDesc.tr,
    };
    return Text(
      desc,
      style: SettingsTextStyles.overviewSubtitle(context),
    );
  }

  /// 就绪态描述文案
  String _normalDescText(AndroidEnvironmentStatus status, double? androidOsVersion) {
    return switch (status.workingMode) {
      EnvironmentType.shizuku => TranslationKey.shizukuModeRunningDesc.trParams({
        'version': status.shizukuVersion?.toString() ?? '',
      }),
      EnvironmentType.root => TranslationKey.rootModeRunningDesc.tr,
      EnvironmentType.androidPre10 => 'Android ${androidOsVersion ?? ''}',
      EnvironmentType.none => TranslationKey.envPermissionIgnoredDesc.tr,
    };
  }

  /// 切换工作模式入口。
  ///
  /// 工作模式选择尚未迁入当前架构，先保留入口占位，不做跳转。
  Widget _buildAction() {
    return IconButton(
      icon: const Icon(Icons.more_horiz_outlined),
      tooltip: TranslationKey.switchWorkingMode.tr,
      onPressed: () {},
    );
  }
}
