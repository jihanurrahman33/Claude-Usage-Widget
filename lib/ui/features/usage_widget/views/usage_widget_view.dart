import 'dart:async';

import 'package:claude_usage_widget/ui/core/accent_palette.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/motion.dart';
import 'package:claude_usage_widget/ui/core/widgets/glass_card.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_cubit.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/views/details_view.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/views/menu_view.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/views/pill_view.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/widget_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// The floating card. It springs between the shapes of the three views while
/// their content cross-fades, so the widget reads as one object changing
/// shape rather than three screens.
class UsageWidgetView extends StatelessWidget {
  /// Creates the view; the cubit comes from the surrounding [BlocProvider].
  const UsageWidgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsageWidgetCubit>();
    return Material(
      type: MaterialType.transparency,
      child: BlocBuilder<UsageWidgetCubit, UsageWidgetState>(
        builder: (context, state) {
          final cardSize = WidgetLayout.cardSize(state);
          return Padding(
            padding: WidgetLayout.shadowMargin,
            child: Align(
              alignment: Alignment.topLeft,
              child: TweenAnimationBuilder<Size?>(
                tween: SizeTween(end: cardSize),
                duration: AppMotion.morph,
                curve: AppMotion.spring,
                builder: (context, size, child) =>
                    SizedBox.fromSize(size: size, child: child),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => unawaited(cubit.startDrag()),
                  // In settings a stray click must not dismiss the panel.
                  onTap: state.viewMode == ViewMode.menu
                      ? null
                      : cubit.toggleDetails,
                  onSecondaryTap: cubit.toggleMenu,
                  child: _Accented(
                    state: state,
                    child: GlassCard(
                      opacity: state.opacity,
                      child: _Content(
                        state: state,
                        cubit: cubit,
                        size: cardSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lays each view out at its own final size, anchored top-left, so content
/// stays still while the card grows or shrinks around it.
class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.cubit,
    required this.size,
  });

  final UsageWidgetState state;
  final UsageWidgetCubit cubit;
  final Size size;

  @override
  Widget build(BuildContext context) => OverflowBox(
    alignment: Alignment.topLeft,
    minWidth: 0,
    minHeight: 0,
    maxWidth: double.infinity,
    maxHeight: double.infinity,
    child: AnimatedSwitcher(
      duration: AppMotion.content,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment.topLeft,
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: SizedBox.fromSize(
        key: ValueKey(state.viewMode),
        size: size,
        child: switch (state.viewMode) {
          ViewMode.pill => PillView(snapshot: state.snapshot, now: state.now),
          ViewMode.details => DetailsView(
            snapshot: state.snapshot,
            now: state.now,
            leanCtx: state.visibleLeanCtx,
          ),
          ViewMode.menu => MenuView(state: state, actions: cubit),
        },
      ),
    ),
  );
}

/// Applies the user's accent colour to the palette below it.
class _Accented extends StatelessWidget {
  const _Accented({required this.state, required this.child});

  final UsageWidgetState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!state.accentPickerAvailable) return child;
    final theme = Theme.of(context);
    final accent = AccentPalette.of(
      state.accent,
      dark: theme.brightness == Brightness.dark,
    );
    return Theme(
      data: theme.copyWith(
        // Healthy rings take the accent; high and critical usage keep their
        // warning colours. Text stays black or white.
        extensions: [
          GlassTheme.of(context).copyWith(accent: accent, ok: accent),
        ],
      ),
      child: child,
    );
  }
}
