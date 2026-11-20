import 'package:claude_usage_widget/domain/models/accent_choice.dart';

/// The actions the settings view can trigger.
///
/// The view depends on this narrow interface rather than on the whole cubit,
/// so it cannot reach state or behaviour it has no business with.
abstract interface class SettingsActions {
  /// Closes the settings view.
  Future<void> closeMenu();

  /// Registers or removes the bridge as the status line command.
  Future<void> toggleStatusLine();

  /// Keeps the widget above other windows, or lets them cover it.
  Future<void> toggleAlwaysOnTop();

  /// Turns launch at login on or off.
  Future<void> toggleStartup();

  /// Turns automatic update checks and installs on or off.
  Future<void> toggleAutoUpdate();

  /// Shows or hides lean-ctx's savings.
  Future<void> toggleLeanCtx();

  /// Installs the available update now.
  Future<void> installUpdate();

  /// Previews a new glass strength while the slider moves.
  void setOpacity(double value);

  /// Persists the current glass strength.
  Future<void> saveOpacity();

  /// Switches to and saves the accent colour [choice].
  Future<void> setAccent(AccentChoice choice);

  /// Shows or hides the window.
  Future<void> toggleVisibility();

  /// Quits the app.
  Future<void> quit();
}
