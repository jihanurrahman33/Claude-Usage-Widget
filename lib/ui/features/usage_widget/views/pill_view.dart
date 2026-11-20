import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:claude_usage_widget/ui/core/formatters.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/widgets/percent_text.dart';
import 'package:claude_usage_widget/ui/core/widgets/usage_ring.dart';
import 'package:material_ui/material_ui.dart';

/// Collapsed view: one or two small rings with their values.
class PillView extends StatelessWidget {
  /// Creates the pill for [snapshot] as of [now].
  const PillView({required this.snapshot, required this.now, super.key});

  /// What to show.
  final UsageSnapshot snapshot;

  /// Time used for reset logic.
  final DateTime now;

  @override
  Widget build(BuildContext context) => Padding(
    // The right inset is smaller because each half already ends in free space.
    padding: const EdgeInsets.only(left: 15, right: 4),
    child: switch (snapshot) {
      // Text needs the full inset on the right; ring pairs do not.
      NoUsage() => const Padding(
        padding: EdgeInsets.only(right: 11),
        child: _Waiting(),
      ),
      SubscriptionUsage(:final fiveHour, :final sevenDay) => Row(
        children: [
          Expanded(
            child: _RingMetric(percent: fiveHour?.percentAt(now), label: '5h'),
          ),
          Expanded(
            child: _RingMetric(percent: sevenDay?.percentAt(now), label: '7d'),
          ),
        ],
      ),
      GatewayUsage(:final spend, :final usedUsd, :final limitUsd) => Row(
        children: [
          Expanded(
            child: _RingMetric(percent: spend.percentAt(now), label: 'spend'),
          ),
          if (usedUsd != null)
            Expanded(
              child: _ValueMetric(
                value: formatMoney(usedUsd),
                label: limitUsd == null
                    ? 'used'
                    : 'of ${formatMoney(limitUsd, 0)}',
              ),
            ),
        ],
      ),
      ApiUsage(:final todayCostUsd, :final contextPercent) => Row(
        children: [
          Expanded(
            child: _RingMetric(percent: contextPercent, label: 'context'),
          ),
          Expanded(
            child: _ValueMetric(
              value: formatMoney(todayCostUsd),
              label: 'today',
            ),
          ),
        ],
      ),
    },
  );
}

const _ringDiameter = 30.0;
const _ringStroke = 4.5;

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    return Row(
      children: [
        UsageRing.placeholder(
          context: context,
          diameter: _ringDiameter,
          strokeWidth: _ringStroke,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Waiting for Claude Code',
              style: AppText.style(13, color: glass.secondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingMetric extends StatelessWidget {
  const _RingMetric({required this.percent, required this.label});

  final double? percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = percent;
    return Row(
      children: [
        if (value == null)
          UsageRing.placeholder(
            context: context,
            diameter: _ringDiameter,
            strokeWidth: _ringStroke,
          )
        else
          UsageRing(
            percent: value,
            diameter: _ringDiameter,
            strokeWidth: _ringStroke,
          ),
        const SizedBox(width: 9),
        Flexible(
          child: _Stacked(
            value: PercentText(percent: percent, size: 15),
            label: label,
          ),
        ),
      ],
    );
  }
}

class _ValueMetric extends StatelessWidget {
  const _ValueMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => _Stacked(
    value: Text(
      value,
      maxLines: 1,
      style: AppText.style(
        15,
        color: GlassTheme.of(context).label,
        weight: FontWeight.w700,
        tabular: true,
      ),
    ),
    label: label,
  );
}

/// A value with its caption underneath.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.value, required this.label});

  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(fit: BoxFit.scaleDown, child: value),
      Text(
        label,
        maxLines: 1,
        style: AppText.style(11, color: GlassTheme.of(context).secondary),
      ),
    ],
  );
}
