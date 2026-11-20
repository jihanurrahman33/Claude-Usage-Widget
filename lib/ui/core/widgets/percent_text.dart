import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A percentage set the way Apple sets units: a bold number with a smaller,
/// quieter percent sign.
class PercentText extends StatelessWidget {
  /// Creates the text for [percent]; null shows a placeholder.
  const PercentText({required this.percent, required this.size, super.key});

  /// Value to show, rounded to a whole number.
  final double? percent;

  /// Font size of the number.
  final double size;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final value = percent;
    return Text.rich(
      TextSpan(
        text: value == null ? '--' : '${value.round()}',
        style: AppText.style(
          size,
          color: value == null ? glass.tertiary : glass.label,
          weight: FontWeight.w700,
          tabular: true,
        ),
        children: [
          TextSpan(
            text: '%',
            style: AppText.style(
              size * 0.62,
              color: glass.secondary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}
