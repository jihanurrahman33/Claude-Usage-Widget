import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:claude_usage_widget/config/app_constants.dart';
import 'package:claude_usage_widget/data/repositories/status_line_repository.dart';
import 'package:claude_usage_widget/data/repositories/usage_repository.dart';
import 'package:claude_usage_widget/data/services/autostart_service.dart';
import 'package:claude_usage_widget/data/services/lean_ctx_service.dart';
import 'package:claude_usage_widget/data/services/notification_service.dart';
import 'package:claude_usage_widget/data/services/preferences_service.dart';
import 'package:claude_usage_widget/data/services/tray_service.dart';
import 'package:claude_usage_widget/data/services/update_service.dart';
import 'package:claude_usage_widget/data/services/window_service.dart';
import 'package:claude_usage_widget/domain/models/accent_choice.dart';
import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:claude_usage_widget/domain/use_cases/alert_policy.dart';
import 'package:claude_usage_widget/ui/core/formatters.dart';
import 'package:claude_usage_widget/ui/core/motion.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/settings_actions.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/widget_layout.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/window_morpher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the widget's state and turns user actions and new usage data into
/// state changes.
///
/// It coordinates collaborators but leaves the work to them: [AlertPolicy]
/// decides what to notify, [WindowMorpher] sizes the window, and formatting
/// lives with the UI helpers.
class UsageWidgetCubit extends Cubit<UsageWidgetState>
    implements SettingsActions {
  /// Creates the cubit; all collaborators are injected so tests can fake them.
  UsageWidgetCubit({
    required this._usage,
    required this._statusLine,
    required this._autostart,
    required PreferencesService preferences,
    required this._window,
    required this._tray,
    required this._notifications,
    this._updater,
    this._leanCtx,
    AlertPolicy? alertPolicy,
    bool accentPicker = false,
    Duration morphDuration = AppMotion.morph,
    DateTime Function() clock = DateTime.now,
  }) : _preferences = preferences,
       _alerts = alertPolicy ?? AlertPolicy(),
       _clock = clock,
       _morpher = WindowMorpher(
         window: _window,
         initialSize: WidgetLayout.windowSizeFor(WidgetLayout.pill),
         duration: morphDuration,
       ),
       super(
         UsageWidgetState(
           now: clock(),
           opacity: preferences.opacity ?? AppConstants.defaultOpacity,
           alwaysOnTop: preferences.alwaysOnTop,
           accent: accentPicker ? preferences.accent : AccentChoice.claude,
           accentPickerAvailable: accentPicker,
           autoUpdate: preferences.autoUpdate,
           leanCtxEnabled: preferences.leanCtx,
         ),
       );

  final UsageRepository _usage;
  final StatusLineRepository _statusLine;
  final AutostartService _autostart;
  final PreferencesService _preferences;
  final WindowService _window;
  final TrayService _tray;
  final NotificationService _notifications;
  final UpdateService? _updater;
  final LeanCtxService? _leanCtx;
  final AlertPolicy _alerts;
  final WindowMorpher _morpher;
  final DateTime Function() _clock;

  StreamSubscription<UsageSnapshot>? _usageSub;
  StreamSubscription<Offset>? _moveSub;
  Timer? _redraw;
  Timer? _updateCheck;
  Timer? _leanCtxPoll;
  String? _installAttempted;

  /// Loads settings, starts the tray and begins listening for usage.
  Future<void> start() async {
    final trayAvailable = await _tray.start(
      TrayCallbacks(
        onToggleVisibility: () => unawaited(toggleVisibility()),
        onToggleStartup: () => unawaited(toggleStartup()),
        onQuit: () => unawaited(quit()),
      ),
    );
    emit(
      state.copyWith(
        trayAvailable: trayAvailable,
        statusLineInstalled: await _statusLine.isInstalled(),
        startupEnabled: await _autostart.isEnabled(),
      ),
    );
    await _refreshTrayMenu();
    _moveSub = _window.moved.listen(
      (position) => unawaited(_preferences.saveWindowPosition(position)),
    );
    _usageSub = _usage.watch().distinct().listen(_onSnapshot);
    _redraw = Timer.periodic(
      AppConstants.redrawInterval,
      (_) => emit(state.copyWith(now: _clock())),
    );
    _scheduleUpdateChecks();
    unawaited(_startLeanCtx());
  }

  Future<void> _startLeanCtx() async {
    final service = _leanCtx;
    if (service == null) return;
    final available = await service.isInstalled();
    if (isClosed) return;
    emit(state.copyWith(leanCtxAvailable: available));
    _scheduleLeanCtx();
  }

  void _scheduleLeanCtx() {
    _leanCtxPoll?.cancel();
    _leanCtxPoll = null;
    if (!state.leanCtxAvailable || !state.leanCtxEnabled) return;
    unawaited(refreshLeanCtx());
    _leanCtxPoll = Timer.periodic(
      AppConstants.leanCtxRefreshInterval,
      (_) => unawaited(refreshLeanCtx()),
    );
  }

  /// Re-reads lean-ctx's savings. A failed read keeps the last good figures.
  Future<void> refreshLeanCtx() async {
    final stats = await _leanCtx?.read();
    if (stats == null || isClosed) return;
    emit(state.copyWith(leanCtx: stats));
    unawaited(_fitWindow());
  }

  @override
  Future<void> toggleLeanCtx() async {
    final enabled = !state.leanCtxEnabled;
    emit(state.copyWith(leanCtxEnabled: enabled));
    await _preferences.saveLeanCtx(value: enabled);
    _scheduleLeanCtx();
    unawaited(_fitWindow());
  }

  void _scheduleUpdateChecks() {
    _updateCheck?.cancel();
    _updateCheck = null;
    if (_updater == null || !state.autoUpdate) return;
    unawaited(checkForUpdate());
    _updateCheck = Timer.periodic(
      AppConstants.updateCheckInterval,
      (_) => unawaited(checkForUpdate()),
    );
  }

  /// Looks for a newer release; installs it when the platform can do that
  /// unattended. A version is only attempted once per run, so a failing
  /// install cannot loop.
  Future<void> checkForUpdate() async {
    final updater = _updater;
    if (updater == null || isClosed) return;
    final version = await updater.newerVersion(AppConstants.version);
    if (version == null || isClosed) return;
    emit(state.copyWith(availableUpdate: version));
    if (updater.installsAutomatically &&
        state.autoUpdate &&
        _installAttempted != version) {
      _installAttempted = version;
      await updater.install();
    }
  }

  @override
  Future<void> installUpdate() async {
    final updater = _updater;
    if (updater == null || state.availableUpdate == null) return;
    await updater.install();
  }

  @override
  Future<void> toggleAutoUpdate() async {
    final enabled = !state.autoUpdate;
    emit(state.copyWith(autoUpdate: enabled));
    await _preferences.saveAutoUpdate(value: enabled);
    _scheduleUpdateChecks();
  }

  void _onSnapshot(UsageSnapshot snapshot) {
    final now = _clock();
    emit(state.copyWith(snapshot: snapshot, now: now));
    for (final alert in _alerts.evaluate(snapshot, now)) {
      unawaited(_notifications.show(alert.title, alert.message));
    }
    unawaited(_tray.setTooltip(formatSummary(snapshot, now)));
    unawaited(_fitWindow());
  }

  Future<void> _fitWindow() => _morpher.fit(WidgetLayout.windowSize(state));

  /// Starts a window drag.
  Future<void> startDrag() => _window.startDragging();

  /// Expands or collapses the details view.
  Future<void> toggleDetails() => _setMode(
    state.viewMode == ViewMode.pill ? ViewMode.details : ViewMode.pill,
  );

  /// Opens or closes the settings menu.
  Future<void> toggleMenu() =>
      _setMode(state.viewMode == ViewMode.menu ? ViewMode.pill : ViewMode.menu);

  @override
  Future<void> closeMenu() => _setMode(ViewMode.pill);

  Future<void> _setMode(ViewMode mode) async {
    if (mode == state.viewMode) return;
    final next = state.copyWith(viewMode: mode, clearError: true);
    await _morpher.morph(
      target: WidgetLayout.windowSize(next),
      apply: () {
        if (!isClosed) emit(next);
      },
      settledSize: () => WidgetLayout.windowSize(state),
    );
  }

  @override
  Future<void> toggleStatusLine() async {
    try {
      if (state.statusLineInstalled) {
        await _statusLine.uninstall();
      } else {
        await _statusLine.install();
      }
      emit(
        state.copyWith(
          statusLineInstalled: await _statusLine.isInstalled(),
          clearError: true,
        ),
      );
    } on FormatException catch (e) {
      emit(
        state.copyWith(errorMessage: 'settings.json is invalid: ${e.message}'),
      );
    } on FileSystemException catch (e) {
      emit(state.copyWith(errorMessage: 'Cannot write settings: ${e.message}'));
    }
  }

  @override
  Future<void> toggleAlwaysOnTop() async {
    final enabled = !state.alwaysOnTop;
    await _window.setAlwaysOnTop(enabled: enabled);
    emit(state.copyWith(alwaysOnTop: enabled));
    await _preferences.saveAlwaysOnTop(value: enabled);
  }

  @override
  Future<void> toggleStartup() async {
    await _autostart.setEnabled(enabled: !state.startupEnabled);
    emit(state.copyWith(startupEnabled: await _autostart.isEnabled()));
    await _refreshTrayMenu();
  }

  @override
  void setOpacity(double value) => emit(
    state.copyWith(
      opacity: value.clamp(AppConstants.minOpacity, 1.0).toDouble(),
    ),
  );

  @override
  Future<void> saveOpacity() => _preferences.saveOpacity(state.opacity);

  @override
  Future<void> setAccent(AccentChoice choice) async {
    emit(state.copyWith(accent: choice));
    await _preferences.saveAccent(choice);
  }

  @override
  Future<void> toggleVisibility() async {
    final visible = !state.windowVisible;
    // Hiding always returns to the pill, abandoning any morph in flight.
    _morpher.cancel();
    emit(state.copyWith(windowVisible: visible, viewMode: ViewMode.pill));
    await _window.setVisible(visible: visible);
    await _refreshTrayMenu();
    await _fitWindow();
  }

  @override
  Future<void> quit() => _window.close();

  Future<void> _refreshTrayMenu() async {
    if (!state.trayAvailable) return;
    await _tray.updateMenu(
      windowVisible: state.windowVisible,
      startupEnabled: state.startupEnabled,
    );
  }

  @override
  Future<void> close() async {
    _redraw?.cancel();
    _updateCheck?.cancel();
    _leanCtxPoll?.cancel();
    _morpher.cancel();
    await _usageSub?.cancel();
    await _moveSub?.cancel();
    await _tray.dispose();
    await _window.dispose();
    return super.close();
  }
}
