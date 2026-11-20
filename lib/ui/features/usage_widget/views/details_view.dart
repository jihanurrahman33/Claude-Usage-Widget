import 'package:claude_usage_widget/config/app_constants.dart';
import 'package:claude_usage_widget/domain/models/lean_ctx_stats.dart';
import 'package:claude_usage_widget/domain/models/rate_limit.dart';
import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:claude_usage_widget/ui/core/formatters.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/widgets/glass_tile.dart';
import 'package:claude_usage_widget/ui/core/widgets/percent_text.dart';
import 'package:claude_usage_widget/ui/core/widgets/usage_ring.dart';
import 'package:material_ui/material_ui.dart';

/// Expanded view: a header and two tiles, one per limit or figure.
class DetailsView extends StatelessWidget {
  /// Creates the details for [snapshot] as of [now].
  const DetailsView({
    required this.snapshot,
    required this.now,
    this.leanCtx,
    super.key,
  });

  /// What to show.
  final UsageSnapshot snapshot;

  /// Time used for countdowns and freshness.
  final DateTime now;

  /// lean-ctx's savings, shown in a strip below the tiles when present.
  final LeanCtxStats? leanCtx;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: snapshot is ApiUsage ? 'CLAUDE · API' : 'CLAUDE',
          updatedAt: snapshot.updatedAt,
          now: now,
        ),
        const SizedBox(height: 12),
        Expanded(child: _body()),
        if (leanCtx case final stats?) ...[
          const SizedBox(height: 8),
          _LeanCtxStrip(stats: stats),
        ],
      ],
    ),
  );

  Widget _body() => switch (snapshot) {
    NoUsage() => const _EmptyTile(),
    SubscriptionUsage(:final fiveHour, :final sevenDay) => _Pair(
      left: _limitTile('5-Hour', fiveHour),
      right: _limitTile('7-Day', sevenDay),
    ),
    GatewayUsage(:final spend, :final usedUsd, :final limitUsd) => _Pair(
      left: _limitTile('Spend', spend),
      right: _FigureTile(
        title: 'Used',
        figure: usedUsd == null ? '—' : formatMoney(usedUsd),
        caption: limitUsd == null
            ? 'Limit set by your organization'
            : 'of ${formatMoney(limitUsd, 0)} limit',
      ),
    ),
    ApiUsage(
      :final sessionCostUsd,
      :final todayCostUsd,
      :final contextPercent,
    ) =>
      _Pair(
        left: _RingTile(
          percent: contextPercent,
          title: 'Context',
          caption: 'window used',
        ),
        right: _FigureTile(
          title: 'Today',
          figure: formatMoney(todayCostUsd),
          caption: 'Session ${formatMoney(sessionCostUsd)}',
          footnote: 'List-price estimate',
        ),
      ),
  };

  Widget _limitTile(String title, RateLimit? limit) {
    final remaining = limit?.untilReset(now);
    return _RingTile(
      percent: limit?.percentAt(now),
      title: title,
      caption: switch ((limit, remaining)) {
        (null, _) => 'No data',
        (_, final Duration left) => 'Resets in ${formatDuration(left)}',
        (RateLimit(resetsAt: null), _) => 'of limit',
        _ => 'Reset',
      },
    );
  }
}

/// lean-ctx's savings: three small figures in one tile.
class _LeanCtxStrip extends StatelessWidget {
  const _LeanCtxStrip({required this.stats});

  final LeanCtxStats stats;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: GlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _StripFigure(
              figure: formatCount(stats.tokensSaved),
              label: 'Tokens saved',
            ),
          ),
          Expanded(
            child: _StripFigure(
              figure: '${stats.reductionPercent.round()}%',
              label: 'Reduced',
            ),
          ),
          Expanded(
            child: _StripFigure(
              figure: formatCount(stats.commands),
              label: 'Commands',
            ),
          ),
        ],
      ),
    ),
  );
}

class _StripFigure extends StatelessWidget {
  const _StripFigure({required this.figure, required this.label});

  final String figure;
  final String label;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            figure,
            maxLines: 1,
            style: AppText.style(
              14,
              color: glass.label,
              weight: FontWeight.w700,
              tabular: true,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: AppText.style(10, color: glass.tertiary),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.updatedAt,
    required this.now,
  });

  final String title;
  final DateTime? updatedAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final updated = updatedAt;
    final age = updated == null ? null : now.difference(updated);
    final live = age != null && age < AppConstants.staleAfter;
    return Row(
      children: [
        Text(
          title,
          style: AppText.style(
            11,
            color: glass.accent,
            weight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const Spacer(),
        if (live) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: glass.ok, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        if (age != null)
          Text(
            live ? 'Live' : 'Updated ${formatAge(age)}',
            style: AppText.style(
              11,
              color: live ? glass.secondary : glass.tertiary,
            ),
          ),
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: left),
      const SizedBox(width: 10),
      Expanded(child: right),
    ],
  );
}

/// A ring with its value in the centre, a title and a caption.
class _RingTile extends StatelessWidget {
  const _RingTile({
    required this.percent,
    required this.title,
    required this.caption,
  });

  final double? percent;
  final String title;
  final String caption;

  static const _ringDiameter = 66.0;
  static const _ringStroke = 7.5;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final value = percent;
    return GlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (value == null)
            UsageRing.placeholder(
              context: context,
              diameter: _ringDiameter,
              strokeWidth: _ringStroke,
              child: const PercentText(percent: null, size: 19),
            )
          else
            UsageRing(
              percent: value,
              diameter: _ringDiameter,
              strokeWidth: _ringStroke,
              child: PercentText(percent: value, size: 19),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            style: AppText.style(
              12,
              color: glass.label,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              caption,
              maxLines: 1,
              style: AppText.style(11, color: glass.secondary, tabular: true),
            ),
          ),
        ],
      ),
    );
  }
}

/// A large figure with a title above and captions below.
class _FigureTile extends StatelessWidget {
  const _FigureTile({
    required this.title,
    required this.figure,
    required this.caption,
    this.footnote,
  });

  final String title;
  final String figure;
  final String caption;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final note = footnote;
    return GlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.style(
              12,
              color: glass.secondary,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              figure,
              maxLines: 1,
              style: AppText.style(
                26,
                color: glass.label,
                weight: FontWeight.w700,
                tabular: true,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 2,
            style: AppText.style(11, color: glass.secondary),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                note,
                maxLines: 1,
                style: AppText.style(10, color: glass.tertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    return GlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UsageRing.placeholder(
            context: context,
            diameter: 30,
            strokeWidth: 4.5,
          ),
          const SizedBox(height: 9),
          Text(
            'No Data Yet',
            style: AppText.style(
              13,
              color: glass.label,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Turn on Status Line in Settings,\nthen send a message in Claude Code.',
            textAlign: TextAlign.center,
            style: AppText.style(11, color: glass.secondary),
          ),
        ],
      ),
    );
  }
}
