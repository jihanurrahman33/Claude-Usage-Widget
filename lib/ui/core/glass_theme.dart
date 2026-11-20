import 'package:claude_usage_widget/config/app_constants.dart';
import 'package:material_ui/material_ui.dart';

/// The widget's palette, with a dark and a light variant.
///
/// Text and status colours follow Apple's system colours for each appearance.
/// Registered as a [ThemeExtension] so the tree follows the system brightness.
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  /// Creates a palette.
  const GlassTheme({
    required this.fillTop,
    required this.fillBottom,
    required this.tile,
    required this.tileRim,
    required this.rimBright,
    required this.rimDim,
    required this.innerGlow,
    required this.outline,
    required this.shadow,
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.separator,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.danger,
    this.bodyFloor = 0,
  });

  /// Dark appearance: smoked glass.
  static const dark = GlassTheme(
    fillTop: Color(0xE03A3A44),
    fillBottom: Color(0xF01C1C22),
    tile: Color(0x12FFFFFF),
    tileRim: Color(0x14FFFFFF),
    rimBright: Color(0x70FFFFFF),
    rimDim: Color(0x12FFFFFF),
    innerGlow: Color(0x42FFFFFF),
    outline: Color(0x40000000),
    shadow: Color(0x66000000),
    label: Color(0xFFFFFFFF),
    secondary: Color(0x99EBEBF5),
    tertiary: Color(0x66EBEBF5),
    separator: Color(0x1FFFFFFF),
    accent: Color(0xFFF0906E),
    ok: Color(0xFF30D158),
    warn: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
  );

  /// Light appearance: clear glass.
  static const light = GlassTheme(
    fillTop: Color(0xEBFFFFFF),
    fillBottom: Color(0xDBF2F2F7),
    tile: Color(0x8CFFFFFF),
    tileRim: Color(0x0F000000),
    rimBright: Color(0xF5FFFFFF),
    rimDim: Color(0x80FFFFFF),
    innerGlow: Color(0xE6FFFFFF),
    outline: Color(0x1A000000),
    shadow: Color(0x33000000),
    label: Color(0xFF000000),
    secondary: Color(0x993C3C43),
    tertiary: Color(0x663C3C43),
    separator: Color(0x1A000000),
    accent: Color(0xFFD2603F),
    ok: Color(0xFF34C759),
    warn: Color(0xFFFF9500),
    danger: Color(0xFFFF3B30),
  );

  /// Light appearance on Linux. With no desktop blur, white glass over a dark
  /// desktop turns muddy grey and the grey text loses contrast, so the glass
  /// never gets thinner than this floor.
  static final linuxLight = light.copyWith(bodyFloor: 0.7);

  /// Top of the glass body, at full strength.
  final Color fillTop;

  /// Bottom of the glass body, at full strength.
  final Color fillBottom;

  /// Fill of an inset tile.
  final Color tile;

  /// Hairline around an inset tile.
  final Color tileRim;

  /// Brightest part of the edge light.
  final Color rimBright;

  /// Dimmest part of the edge light.
  final Color rimDim;

  /// Soft light just inside the edge, giving the glass thickness.
  final Color innerGlow;

  /// Hairline just outside the glass, separating it from what is behind.
  final Color outline;

  /// Drop shadow under the glass.
  final Color shadow;

  /// Primary text.
  final Color label;

  /// Secondary text.
  final Color secondary;

  /// Tertiary text.
  final Color tertiary;

  /// Hairline between rows.
  final Color separator;

  /// Brand tint.
  final Color accent;

  /// Healthy usage.
  final Color ok;

  /// High usage.
  final Color warn;

  /// Critical usage.
  final Color danger;

  /// Weakest the glass body gets at the lowest opacity setting, in 0..1.
  final double bodyFloor;

  /// Strength of the glass body for the user's [opacity] setting.
  double bodyStrength(double opacity) {
    final o = opacity.clamp(0.0, 1.0);
    return bodyFloor + (1 - bodyFloor) * o;
  }

  /// Track of a ring that has no value to show.
  Color get placeholder => label.withValues(alpha: 0.14);

  /// The palette of the current theme.
  static GlassTheme of(BuildContext context) =>
      Theme.of(context).extension<GlassTheme>() ?? dark;

  /// Colour for a usage [percent], using the app's thresholds.
  Color forPercent(double percent) {
    if (percent >= AppConstants.dangerPercent) return danger;
    if (percent >= AppConstants.warnPercent) return warn;
    return ok;
  }

  @override
  GlassTheme copyWith({Color? accent, Color? ok, double? bodyFloor}) =>
      GlassTheme(
        fillTop: fillTop,
        fillBottom: fillBottom,
        tile: tile,
        tileRim: tileRim,
        rimBright: rimBright,
        rimDim: rimDim,
        innerGlow: innerGlow,
        outline: outline,
        shadow: shadow,
        label: label,
        secondary: secondary,
        tertiary: tertiary,
        separator: separator,
        accent: accent ?? this.accent,
        ok: ok ?? this.ok,
        warn: warn,
        danger: danger,
        bodyFloor: bodyFloor ?? this.bodyFloor,
      );

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GlassTheme(
      fillTop: mix(fillTop, other.fillTop),
      fillBottom: mix(fillBottom, other.fillBottom),
      tile: mix(tile, other.tile),
      tileRim: mix(tileRim, other.tileRim),
      rimBright: mix(rimBright, other.rimBright),
      rimDim: mix(rimDim, other.rimDim),
      innerGlow: mix(innerGlow, other.innerGlow),
      outline: mix(outline, other.outline),
      shadow: mix(shadow, other.shadow),
      label: mix(label, other.label),
      secondary: mix(secondary, other.secondary),
      tertiary: mix(tertiary, other.tertiary),
      separator: mix(separator, other.separator),
      accent: mix(accent, other.accent),
      ok: mix(ok, other.ok),
      warn: mix(warn, other.warn),
      danger: mix(danger, other.danger),
      bodyFloor: bodyFloor + (other.bodyFloor - bodyFloor) * t,
    );
  }
}

/// Text styles of the widget, set in Inter.
///
/// Sizes follow Apple's type scale (11, 13, 15, 17, 20+) and larger sizes are
/// tracked tighter.
abstract final class AppText {
  /// The bundled typeface.
  static const family = 'Inter';

  /// Builds a style of [size]; without [color] it inherits the surrounding
  /// default, which the glass card sets from the theme.
  ///
  /// Set [tabular] for values that change in place, so digits keep a fixed
  /// width and the text does not jitter. It is off by default because it also
  /// widens hyphens, which looks wrong in labels such as "5-Hour".
  static TextStyle style(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
    double? letterSpacing,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    color: color,
    fontWeight: weight,
    // Inter is a variable font: drive its weight and optical-size axes.
    fontVariations: [
      FontVariation.weight(weight.value.toDouble()),
      FontVariation.opticalSize(size.clamp(14, 32).toDouble()),
    ],
    letterSpacing: letterSpacing ?? _tracking(size),
    height: 1.2,
    leadingDistribution: TextLeadingDistribution.even,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    decoration: TextDecoration.none,
  );

  static double _tracking(double size) {
    if (size >= 20) return -0.5;
    if (size >= 15) return -0.25;
    if (size >= 12) return -0.08;
    return 0.06;
  }
}

/// The app's [ThemeData] for [brightness], carrying the matching [GlassTheme].
///
/// [lightGlass] replaces the light palette, for platform-specific tuning.
ThemeData buildAppTheme(
  Brightness brightness, {
  GlassTheme lightGlass = GlassTheme.light,
}) => ThemeData(
  brightness: brightness,
  useMaterial3: true,
  fontFamily: AppText.family,
  scaffoldBackgroundColor: Colors.transparent,
  canvasColor: Colors.transparent,
  extensions: [
    if (brightness == Brightness.dark) GlassTheme.dark else lightGlass,
  ],
);
