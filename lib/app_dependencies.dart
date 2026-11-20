import 'dart:io';

import 'package:claude_usage_widget/data/repositories/status_line_repository.dart';
import 'package:claude_usage_widget/data/repositories/usage_repository.dart';
import 'package:claude_usage_widget/data/services/autostart_service.dart';
import 'package:claude_usage_widget/data/services/claude_settings_service.dart';
import 'package:claude_usage_widget/data/services/lean_ctx_service.dart';
import 'package:claude_usage_widget/data/services/notification_service.dart';
import 'package:claude_usage_widget/data/services/preferences_service.dart';
import 'package:claude_usage_widget/data/services/tray_service.dart';
import 'package:claude_usage_widget/data/services/update_service.dart';
import 'package:claude_usage_widget/data/services/usage_file_service.dart';
import 'package:claude_usage_widget/data/services/window_service.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_cubit.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_bridge/bridge.dart' show claudeConfigDir, recordsDir;

/// The composition root: the one place that knows which concrete classes the
/// app is made of and which of them each operating system gets.
///
/// Everything else depends on interfaces, so supporting another platform or
/// swapping an implementation is a change here and nowhere else.
class AppDependencies {
  /// Bundles already built collaborators.
  AppDependencies({
    required this.preferences,
    required this.window,
    required this.cubit,
    this.lightGlass = GlassTheme.light,
  });

  /// User preferences.
  final PreferencesService preferences;

  /// The native window.
  final WindowService window;

  /// The widget's state holder.
  final UsageWidgetCubit cubit;

  /// Palette for the light appearance on this platform.
  final GlassTheme lightGlass;

  /// Builds the object graph for the current platform and [environment].
  static Future<AppDependencies> create({
    Map<String, String>? environment,
  }) async {
    final env = environment ?? Platform.environment;
    final configDir = claudeConfigDir(env);
    final preferences = PreferencesService(
      await SharedPreferences.getInstance(),
    );
    final window = DesktopWindowService();
    final cubit = UsageWidgetCubit(
      usage: UsageRepository(
        files: UsageFileService(directory: recordsDir(configDir)),
      ),
      statusLine: StatusLineRepository(
        settings: ClaudeSettingsService(configDir: configDir),
        bridgePath: _bridgePath(),
      ),
      autostart: _autostart(env),
      preferences: preferences,
      window: window,
      tray: SystemTrayService(),
      notifications: _notifications(),
      accentPicker: Platform.isLinux,
      updater: GitHubUpdateService(),
      leanCtx: CliLeanCtxService(
        searchDirs: CliLeanCtxService.defaultSearchDirs(env),
      ),
    );
    return AppDependencies(
      preferences: preferences,
      window: window,
      cubit: cubit,
      lightGlass: Platform.isLinux ? GlassTheme.linuxLight : GlassTheme.light,
    );
  }

  /// The bridge ships next to the app executable.
  static String _bridgePath() => p.join(
    p.dirname(Platform.resolvedExecutable),
    Platform.isWindows ? 'usage_bridge.exe' : 'usage_bridge',
  );

  static AutostartService _autostart(Map<String, String> env) {
    final executable = Platform.resolvedExecutable;
    final home = env['HOME'] ?? '.';
    if (Platform.isWindows) return WindowsAutostartService(executable);
    if (Platform.isMacOS) {
      return FileAutostartService.launchAgent(
        executable: executable,
        home: home,
      );
    }
    return FileAutostartService.xdg(
      executable: executable,
      configHome: env['XDG_CONFIG_HOME'] ?? p.join(home, '.config'),
    );
  }

  static NotificationService _notifications() {
    if (Platform.isLinux) return LinuxNotificationService();
    if (Platform.isMacOS) return MacNotificationService();
    if (Platform.isWindows) return WindowsNotificationService();
    return const SilentNotificationService();
  }
}
