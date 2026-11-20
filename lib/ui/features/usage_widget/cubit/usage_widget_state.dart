import 'package:claude_usage_widget/config/app_constants.dart';
import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:equatable/equatable.dart';

/// Which of the three views the widget shows.
enum ViewMode {
  /// One-line summary.
  pill,

  /// Bars and reset times.
  details,

  /// Settings menu.
  menu,
}

/// Everything the widget UI renders, as one immutable value.
class UsageWidgetState extends Equatable {
  /// Creates a state; defaults describe a fresh start with no data.
  const UsageWidgetState({
    required this.now,
    this.snapshot = const NoUsage(),
    this.viewMode = ViewMode.pill,
    this.opacity = AppConstants.defaultOpacity,
    this.statusLineInstalled = false,
    this.startupEnabled = false,
    this.trayAvailable = false,
    this.windowVisible = true,
    this.alwaysOnTop = true,
    this.autoUpdate = true,
    this.availableUpdate,
    this.errorMessage,
  });

  /// Time used for countdowns; refreshed on a timer so the UI stays pure.
  final DateTime now;

  /// Current usage.
  final UsageSnapshot snapshot;

  /// Current view.
  final ViewMode viewMode;

  /// Card opacity from 0 to 1.
  final double opacity;

  /// Whether the bridge is registered as Claude Code's status line.
  final bool statusLineInstalled;

  /// Whether the app starts at login.
  final bool startupEnabled;

  /// Whether a tray icon exists.
  final bool trayAvailable;

  /// Whether the window is shown.
  final bool windowVisible;

  /// Whether the window stays above other windows.
  final bool alwaysOnTop;

  /// Whether the app checks for and installs new releases.
  final bool autoUpdate;

  /// Version of a newer release that is ready to install, or null.
  final String? availableUpdate;

  /// Last user-facing error, or null.
  final String? errorMessage;

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass [clearError] to drop the current [errorMessage].
  UsageWidgetState copyWith({
    DateTime? now,
    UsageSnapshot? snapshot,
    ViewMode? viewMode,
    double? opacity,
    bool? statusLineInstalled,
    bool? startupEnabled,
    bool? trayAvailable,
    bool? windowVisible,
    bool? alwaysOnTop,
    bool? autoUpdate,
    String? availableUpdate,
    String? errorMessage,
    bool clearError = false,
  }) => UsageWidgetState(
    now: now ?? this.now,
    snapshot: snapshot ?? this.snapshot,
    viewMode: viewMode ?? this.viewMode,
    opacity: opacity ?? this.opacity,
    statusLineInstalled: statusLineInstalled ?? this.statusLineInstalled,
    startupEnabled: startupEnabled ?? this.startupEnabled,
    trayAvailable: trayAvailable ?? this.trayAvailable,
    windowVisible: windowVisible ?? this.windowVisible,
    alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
    autoUpdate: autoUpdate ?? this.autoUpdate,
    availableUpdate: availableUpdate ?? this.availableUpdate,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    now,
    snapshot,
    viewMode,
    opacity,
    statusLineInstalled,
    startupEnabled,
    trayAvailable,
    windowVisible,
    alwaysOnTop,
    autoUpdate,
    availableUpdate,
    errorMessage,
  ];
}
