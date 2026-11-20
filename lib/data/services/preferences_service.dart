import 'dart:ui';

import 'package:claude_usage_widget/domain/models/accent_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's window position and opacity.
class PreferencesService {
  /// Creates a service over [_prefs].
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _x = 'window_x';
  static const _y = 'window_y';
  static const _opacity = 'opacity';
  static const _alwaysOnTop = 'always_on_top';
  static const _accent = 'accent';
  static const _autoUpdate = 'auto_update';
  static const _leanCtx = 'lean_ctx_stats';

  /// Last saved window position, or null on first run.
  Offset? get windowPosition {
    final x = _prefs.getDouble(_x);
    final y = _prefs.getDouble(_y);
    return x == null || y == null ? null : Offset(x, y);
  }

  /// Saves the window position.
  Future<void> saveWindowPosition(Offset position) async {
    await _prefs.setDouble(_x, position.dx);
    await _prefs.setDouble(_y, position.dy);
  }

  /// Saved card opacity, or null if never changed.
  double? get opacity => _prefs.getDouble(_opacity);

  /// Saves the card opacity.
  Future<void> saveOpacity(double value) => _prefs.setDouble(_opacity, value);

  /// Whether the widget stays above other windows; on unless turned off.
  bool get alwaysOnTop => _prefs.getBool(_alwaysOnTop) ?? true;

  /// Saves the always-on-top choice.
  Future<void> saveAlwaysOnTop({required bool value}) =>
      _prefs.setBool(_alwaysOnTop, value);

  /// Saved accent colour; Claude's own until changed.
  AccentChoice get accent => AccentChoice.fromName(_prefs.getString(_accent));

  /// Saves the accent colour.
  Future<void> saveAccent(AccentChoice value) =>
      _prefs.setString(_accent, value.name);

  /// Whether the app looks for and installs new releases; on unless turned off.
  bool get autoUpdate => _prefs.getBool(_autoUpdate) ?? true;

  /// Whether lean-ctx's savings are shown; on unless turned off.
  bool get leanCtx => _prefs.getBool(_leanCtx) ?? true;

  /// Saves the lean-ctx choice.
  Future<void> saveLeanCtx({required bool value}) =>
      _prefs.setBool(_leanCtx, value);

  /// Saves the auto-update choice.
  Future<void> saveAutoUpdate({required bool value}) =>
      _prefs.setBool(_autoUpdate, value);
}
