import 'package:bloc_test/bloc_test.dart';
import 'package:claude_usage_widget/domain/models/lean_ctx_stats.dart';
import 'package:claude_usage_widget/domain/models/rate_limit.dart';
import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:claude_usage_widget/ui/core/formatters.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/motion.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_cubit.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/views/usage_widget_view.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/widget_layout.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'support.dart';

void main() {
  late MockUsageWidgetCubit cubit;

  setUpAll(loadAppFont);

  setUp(() {
    cubit = MockUsageWidgetCubit();
    when(() => cubit.toggleDetails()).thenAnswer((_) async {});
    when(() => cubit.toggleMenu()).thenAnswer((_) async {});
    when(() => cubit.closeMenu()).thenAnswer((_) async {});
    when(() => cubit.toggleStatusLine()).thenAnswer((_) async {});
    when(() => cubit.startDrag()).thenAnswer((_) async {});
  });

  UsageWidgetState state({
    UsageSnapshot snapshot = const NoUsage(),
    ViewMode mode = ViewMode.pill,
    bool tray = true,
    String? error,
    LeanCtxStats? leanCtx,
    bool leanCtxAvailable = false,
    bool leanCtxEnabled = true,
    String? update,
  }) => UsageWidgetState(
    now: testNow,
    snapshot: snapshot,
    viewMode: mode,
    trayAvailable: tray,
    errorMessage: error,
    leanCtx: leanCtx,
    leanCtxAvailable: leanCtxAvailable,
    leanCtxEnabled: leanCtxEnabled,
    availableUpdate: update,
  );

  /// Shows the whole widget in a window of exactly the size the app gives it.
  Future<void> show(
    WidgetTester tester,
    UsageWidgetState state, {
    Brightness brightness = Brightness.dark,
  }) async {
    whenListen(
      cubit,
      const Stream<UsageWidgetState>.empty(),
      initialState: state,
    );
    tester.view
      ..physicalSize = WidgetLayout.windowSize(state)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<UsageWidgetCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: buildAppTheme(brightness),
          home: const UsageWidgetView(),
        ),
      ),
    );
    await tester.pump(AppMotion.value);
  }

  testWidgets('every view fits its window in both themes', (tester) async {
    final snapshots = <UsageSnapshot>[
      const NoUsage(),
      subscription(),
      subscription(five: 100, seven: 100),
      apiUsage,
      gatewayUsage,
      GatewayUsage(spend: RateLimit(usedPercent: 40, resetsAt: testNow)),
    ];
    for (final brightness in Brightness.values) {
      for (final snapshot in snapshots) {
        for (final mode in ViewMode.values) {
          for (final tray in [true, false]) {
            await show(
              tester,
              state(snapshot: snapshot, mode: mode, tray: tray),
              brightness: brightness,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$brightness ${snapshot.runtimeType} $mode tray=$tray',
            );
          }
        }
      }
    }
  });

  testWidgets('pill shows both limits', (tester) async {
    await show(tester, state(snapshot: subscription()));
    expect(find.text('24%'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('5h'), findsOneWidget);
    expect(find.text('7d'), findsOneWidget);
  });

  testWidgets('a window that has reset reads 0%', (tester) async {
    final expired = SubscriptionUsage(
      fiveHour: RateLimit(
        usedPercent: 90,
        resetsAt: testNow.subtract(const Duration(minutes: 1)),
      ),
    );
    await show(tester, state(snapshot: expired));
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('--%'), findsOneWidget);
  });

  testWidgets('details show reset countdowns and freshness', (tester) async {
    await show(tester, state(snapshot: subscription(), mode: ViewMode.details));
    expect(find.text('Resets in 2h 30m'), findsOneWidget);
    expect(find.text('Resets in 2d 21h'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('tapping the card toggles details', (tester) async {
    await show(tester, state(snapshot: subscription()));
    await tester.tap(find.text('24%'));
    await tester.pump(kDoubleTapTimeout);
    verify(() => cubit.toggleDetails()).called(1);
  });

  testWidgets('settings: switches act, and a stray tap does not dismiss', (
    tester,
  ) async {
    await show(tester, state(mode: ViewMode.menu));
    await tester.tap(find.byType(CupertinoSwitch).first);
    verify(() => cubit.toggleStatusLine()).called(1);

    await tester.tap(find.text('Opacity'));
    await tester.pump(kDoubleTapTimeout);
    verifyNever(() => cubit.toggleDetails());

    await tester.tap(find.text('Done'));
    verify(() => cubit.closeMenu()).called(1);
  });

  testWidgets('settings hide the tray row without a tray, and show errors', (
    tester,
  ) async {
    await show(
      tester,
      state(
        mode: ViewMode.menu,
        tray: false,
        error: 'settings.json is invalid',
      ),
    );
    expect(find.text('Hide to Tray'), findsNothing);
    expect(find.text('Always on Top'), findsOneWidget);
    expect(find.text('settings.json is invalid'), findsOneWidget);
  });

  group('formatters', () {
    test('durations', () {
      expect(formatDuration(const Duration(days: 2, hours: 21)), '2d 21h');
      expect(formatDuration(const Duration(hours: 2, minutes: 30)), '2h 30m');
      expect(formatDuration(const Duration(seconds: 20)), '1m');
    });

    test('summary per account type', () {
      expect(
        formatSummary(subscription(), testNow),
        'Claude · 5h 24% · 7d 78%',
      );
      expect(formatSummary(apiUsage, testNow), r'Claude · ~$4.20 today');
      expect(formatSummary(gatewayUsage, testNow), 'Claude · spend 40%');
      expect(formatSummary(const NoUsage(), testNow), 'Claude Usage');
    });

    test('ages and money', () {
      expect(formatAge(const Duration(minutes: 12)), '12m ago');
      expect(formatAge(const Duration(hours: 3, minutes: 5)), '3h ago');
      expect(formatMoney(4.2), r'$4.20');
      expect(formatMoney(50, 0), r'$50');
    });
  });

  test('the spring settles at exactly its end value', () {
    const spring = SpringCurve();
    expect(spring.transform(0), 0);
    expect(spring.transform(1), 1);
    // Close to rest well before the end, with only a slight overshoot.
    expect(spring.transform(0.7), closeTo(1, 0.02));
    final peak = [for (var t = 0.0; t <= 1; t += 0.01) spring.transform(t)]
        .reduce((a, b) => a > b ? a : b);
    expect(peak, lessThan(1.03));
  });

  const leanCtx = LeanCtxStats(
    tokensSaved: 288018,
    reductionPercent: 26.2,
    commands: 2175,
  );

  testWidgets('details show the lean-ctx strip and fit with it', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      for (final snapshot in [subscription(), apiUsage, gatewayUsage]) {
        await show(
          tester,
          state(snapshot: snapshot, mode: ViewMode.details, leanCtx: leanCtx),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull, reason: '$snapshot');
        expect(find.text('288K'), findsOneWidget);
        expect(find.text('26%'), findsOneWidget);
        expect(find.text('2.2K'), findsOneWidget);
        expect(find.text('Tokens saved'), findsOneWidget);
      }
    }
  });

  testWidgets('the strip is hidden when switched off or before any usage', (
    tester,
  ) async {
    await show(
      tester,
      state(
        snapshot: subscription(),
        mode: ViewMode.details,
        leanCtx: leanCtx,
        leanCtxEnabled: false,
      ),
    );
    expect(find.text('Tokens saved'), findsNothing);

    await show(tester, state(mode: ViewMode.details, leanCtx: leanCtx));
    expect(find.text('Tokens saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings fit with every optional row at once', (tester) async {
    for (final tray in [true, false]) {
      await show(
        tester,
        state(
          mode: ViewMode.menu,
          tray: tray,
          leanCtxAvailable: true,
          update: '9.9.9',
        ),
      );
      expect(tester.takeException(), isNull, reason: 'tray=$tray');
      expect(find.text('lean-ctx Stats'), findsOneWidget);
      expect(find.text('Update to 9.9.9'), findsOneWidget);
    }
  });

  testWidgets('the lean-ctx row is offered only when lean-ctx is installed', (
    tester,
  ) async {
    await show(tester, state(mode: ViewMode.menu));
    expect(find.text('lean-ctx Stats'), findsNothing);
  });

  test('formatCount shortens large numbers', () {
    expect(formatCount(0), '0');
    expect(formatCount(842), '842');
    expect(formatCount(1000), '1.0K');
    expect(formatCount(2175), '2.2K');
    expect(formatCount(12400), '12K');
    expect(formatCount(288018), '288K');
    expect(formatCount(1300000), '1.3M');
  });
}
