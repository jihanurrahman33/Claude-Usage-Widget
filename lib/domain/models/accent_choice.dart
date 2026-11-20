/// The accent colours the user can pick for the widget.
///
/// Only names live here; the UI maps each one to concrete colours.
enum AccentChoice {
  /// Claude's own coral, the default.
  claude,

  /// Ubuntu orange.
  ubuntu,

  /// GNOME blue.
  blue,

  /// Purple.
  purple,

  /// Green.
  green;

  /// The choice saved under [name], or [claude] if it is unknown or null.
  static AccentChoice fromName(String? name) => AccentChoice.values.firstWhere(
    (choice) => choice.name == name,
    orElse: () => AccentChoice.claude,
  );
}
