import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:material_ui/material_ui.dart';

/// An inset panel inside the glass card, used to group related content.
class GlassTile extends StatelessWidget {
  /// Creates a tile around [child].
  const GlassTile({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 16,
    super.key,
  });

  /// Content of the tile, clipped to its shape.
  final Widget child;

  /// Inset around [child].
  final EdgeInsets padding;

  /// Corner radius of the tile.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: glass.tile,
        shape: RoundedSuperellipseBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: glass.tileRim),
        ),
      ),
      child: ClipRSuperellipse(
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
