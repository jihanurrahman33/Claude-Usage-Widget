import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A floating liquid-glass surface with continuous (squircle) corners.
///
/// It is built from layers: a soft drop shadow, a translucent tinted body,
/// light gathering just inside the edge to give the glass thickness, and a
/// hairline edge light. The desktop behind a window cannot be blurred by an
/// app on every platform, so the body stays opaque enough to keep text
/// legible over any background.
class GlassCard extends StatelessWidget {
  /// Creates a card around [child]; [opacity] is the strength of the body.
  const GlassCard({required this.child, required this.opacity, super.key});

  /// Content of the card, clipped to its shape.
  final Widget child;

  /// Strength of the glass body, in 0..1.
  final double opacity;

  /// Corner radius; on the 54 px pill this makes a capsule.
  static const radius = 26.0;

  /// A soft halo in the opposite tone of the text, inherited by all text on
  /// the card. The clearer the glass, the stronger it gets, so text stays
  /// readable when whatever is behind the window shows through.
  List<Shadow>? _legibilityShadow(GlassTheme glass) {
    final strength = ((1 - glass.bodyStrength(opacity)) * 1.1).clamp(0.0, 0.55);
    if (strength <= 0) return null;
    final lightText = glass.label.computeLuminance() > 0.5;
    final tone = lightText ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    return [Shadow(color: tone.withValues(alpha: strength), blurRadius: 4)];
  }

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    return CustomPaint(
      painter: _GlassPainter(glass: glass, opacity: opacity),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: DefaultTextStyle(
          style: AppText.style(
            13,
            color: glass.secondary,
          ).copyWith(shadows: _legibilityShadow(glass)),
          child: child,
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.glass, required this.opacity});

  final GlassTheme glass;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RSuperellipse.fromRectAndRadius(
      rect,
      const Radius.circular(GlassCard.radius),
    );
    final strength = glass.bodyStrength(opacity);
    Color body(Color c) => c.withValues(alpha: c.a * strength);

    _paintShadow(canvas, rect, shape);

    // Body: a tinted gradient, lighter at the top.
    canvas.drawRSuperellipse(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [body(glass.fillTop), body(glass.fillBottom)],
        ).createShader(rect),
    );

    // Thickness: light pooled just inside the top-left edge, and a fainter
    // return along the bottom-right. Each is a blurred outline nudged
    // inwards, so only the near edge survives the clip.
    canvas
      ..save()
      ..clipRSuperellipse(shape);
    _paintInnerGlow(canvas, shape, const Offset(1.2, 1.7), glass.innerGlow);
    _paintInnerGlow(
      canvas,
      shape,
      const Offset(-1, -1.4),
      glass.innerGlow.withValues(alpha: glass.innerGlow.a * 0.4),
    );
    canvas.restore();

    // Edge light: a hairline that is brightest where light enters and exits.
    canvas
      ..drawRSuperellipse(
        shape.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glass.rimBright,
              glass.rimDim,
              glass.rimDim,
              glass.rimBright.withValues(alpha: glass.rimBright.a * 0.6),
            ],
            stops: const [0, 0.38, 0.62, 1],
          ).createShader(rect),
      )
      ..drawRSuperellipse(
        shape.inflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = glass.outline,
      );
  }

  /// Draws a tight contact shadow and a wide ambient one, only outside the
  /// glass so the body is not darkened from behind.
  void _paintShadow(Canvas canvas, Rect rect, RSuperellipse shape) {
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(40)),
      Path()..addRSuperellipse(shape),
    );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRSuperellipse(
        shape.shift(const Offset(0, 7)),
        Paint()
          ..color = glass.shadow.withValues(alpha: glass.shadow.a * 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      )
      ..drawRSuperellipse(
        shape.shift(const Offset(0, 1.5)),
        Paint()
          ..color = glass.shadow.withValues(alpha: glass.shadow.a * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      )
      ..restore();
  }

  void _paintInnerGlow(
    Canvas canvas,
    RSuperellipse shape,
    Offset nudge,
    Color color,
  ) {
    canvas.drawRSuperellipse(
      shape.shift(nudge),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.glass != glass || old.opacity != opacity;
}
