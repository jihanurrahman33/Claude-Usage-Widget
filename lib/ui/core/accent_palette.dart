import 'package:claude_usage_widget/domain/models/accent_choice.dart';
import 'package:flutter/painting.dart';

/// Concrete colours for each [AccentChoice].
///
/// The light variants are darker so they keep contrast on white glass; the
/// dark variants are lighter for smoked glass.
abstract final class AccentPalette {
  /// The colour of [choice] for the light or dark appearance.
  static Color of(AccentChoice choice, {required bool dark}) =>
      switch (choice) {
        AccentChoice.claude =>
          dark ? const Color(0xFFF0906E) : const Color(0xFFD2603F),
        AccentChoice.ubuntu =>
          dark ? const Color(0xFFFF7A45) : const Color(0xFFE95420),
        AccentChoice.blue =>
          dark ? const Color(0xFF78AEED) : const Color(0xFF3584E4),
        AccentChoice.purple =>
          dark ? const Color(0xFFC061CB) : const Color(0xFF9141AC),
        AccentChoice.green =>
          dark ? const Color(0xFF57E389) : const Color(0xFF26A269),
      };
}
