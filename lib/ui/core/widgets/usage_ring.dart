import 'dart:math' as math;

import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/motion.dart';
import 'package:material_ui/material_ui.dart';

/// A circular gauge in the style of an activity ring: a rounded arc over a
/// dimmed track of the same hue, springing to each new value.
class UsageRing extends StatelessWidget {
  /// Creates a ring filled to [percent] (0 to 100).
  const UsageRing({
    required this.percent,
    required this.diameter,
    required this.strokeWidth,
    this.color,
    this.trackColor,
    this.child,
    super.key,
  });

  /// A ring with nothing to show yet: just a quiet track.
  UsageRing.placeholder({
    required BuildContext context,
    required this.diameter,
    required this.strokeWidth,
    this.child,
    super.key,
  }) : percent = 0,
       color = null,
       trackColor = GlassTheme.of(context).placeholder;

  /// How full the ring is, 0 to 100.
  final double percent;

  /// Outer diameter.
  final double diameter;

  /// Thickness of the ring.
  final double strokeWidth;

  /// Ring colour; defaults to the theme's colour for [percent].
  final Color? color;

  /// Track colour; defaults to a dimmed version of the ring colour.
  final Color? trackColor;

  /// Optional content centred inside the ring.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? GlassTheme.of(context).forPercent(percent);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: (percent / 100).clamp(0.0, 1.0)),
      duration: AppMotion.value,
      curve: AppMotion.spring,
      builder: (context, fraction, child) => CustomPaint(
        painter: _RingPainter(
          fraction: fraction,
          color: ringColor,
          trackColor:
              trackColor ?? ringColor.withValues(alpha: ringColor.a * 0.22),
          strokeWidth: strokeWidth,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: diameter,
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, stroke..color = trackColor);
    // The spring may overshoot; a ring cannot be more than full or less
    // than empty.
    final sweep = fraction.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      stroke
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
