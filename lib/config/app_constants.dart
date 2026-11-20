/// Fixed values shared across the app: timings and thresholds.
abstract final class AppConstants {
  /// Human readable app name.
  static const appName = 'Claude Usage Widget';

  /// Shown in the menu. The release workflow rewrites this to the version
  /// being published, so it must stay a plain `X.Y.Z` string literal.
  static const version = '0.1.0';

  /// The GitHub repository releases are published to.
  static const repository = 'jihanurrahman33/Claude-Usage-Widget';

  /// Where releases are listed.
  static const releasesPage = 'https://github.com/$repository/releases/latest';

  /// The installer that also performs updates on macOS and Linux.
  static const installScriptUrl =
      'https://raw.githubusercontent.com/$repository/main/install.sh';

  /// How often lean-ctx's savings are re-read.
  static const leanCtxRefreshInterval = Duration(minutes: 1);

  /// How often the app looks for a newer release.
  static const updateCheckInterval = Duration(hours: 6);

  /// How often the data folder is polled in addition to file watching.
  static const pollInterval = Duration(seconds: 2);

  /// How often countdowns and "updated X ago" labels are redrawn.
  static const redrawInterval = Duration(seconds: 10);

  /// Data older than this is labelled as stale.
  static const staleAfter = Duration(minutes: 5);

  /// Seconds between status line runs requested from Claude Code.
  static const statusLineRefreshSeconds = 5;

  /// Usage percent at which the widget turns amber.
  static const warnPercent = 70.0;

  /// Usage percent at which the widget turns red.
  static const dangerPercent = 90.0;

  /// Usage percents that trigger a desktop notification, ascending.
  static const alertPercents = [80.0, 95.0];

  /// Lowest glass strength the slider allows.
  static const minOpacity = 0.5;

  /// Default strength of the glass fill: the clearest setting.
  static const defaultOpacity = minOpacity;
}
