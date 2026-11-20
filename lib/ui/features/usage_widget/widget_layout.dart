import 'dart:math' as math;

import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:flutter/painting.dart';

/// Sizes of the card in each view, and of the window that holds it.
///
/// The window is larger than the card by [shadowMargin] so the card's soft
/// shadow has room and is never cut off at the window edge.
abstract final class WidgetLayout {
  /// Transparent space around the card for its shadow.
  static const shadowMargin = EdgeInsets.fromLTRB(16, 12, 16, 26);

  /// The collapsed pill.
  static const pill = Size(200, 54);

  /// The expanded view when there is data.
  static const details = Size(264, 186);

  /// The expanded view before any data has arrived.
  static const emptyDetails = Size(264, 164);

  /// Height of one settings row.
  static const menuRowHeight = 36.0;

  /// Settings, with the tray entry.
  static const menuWithTray = Size(264, 345);

  /// Settings, without the tray entry.
  static const menuWithoutTray = Size(264, 309);

  /// Size of the card for [state].
  static Size cardSize(UsageWidgetState state) => switch (state.viewMode) {
    ViewMode.pill => pill,
    ViewMode.menu => _menuSize(state),
    ViewMode.details => switch (state.snapshot) {
      NoUsage() => emptyDetails,
      SubscriptionUsage() || GatewayUsage() || ApiUsage() => details,
    },
  };

  /// Settings grow by one row when an update is waiting.
  static Size _menuSize(UsageWidgetState state) {
    final base = state.trayAvailable ? menuWithTray : menuWithoutTray;
    return state.availableUpdate == null
        ? base
        : Size(base.width, base.height + menuRowHeight);
  }

  /// Size of the window that holds a card of [card] size.
  static Size windowSizeFor(Size card) => Size(
    card.width + shadowMargin.horizontal,
    card.height + shadowMargin.vertical,
  );

  /// Size of the window for [state].
  static Size windowSize(UsageWidgetState state) =>
      windowSizeFor(cardSize(state));

  /// The smallest size that contains both [a] and [b].
  static Size union(Size a, Size b) =>
      Size(math.max(a.width, b.width), math.max(a.height, b.height));
}
