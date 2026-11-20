import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:claude_usage_widget/data/repositories/status_line_repository.dart';
import 'package:claude_usage_widget/data/repositories/usage_repository.dart';
import 'package:claude_usage_widget/data/services/autostart_service.dart';
import 'package:claude_usage_widget/data/services/notification_service.dart';
import 'package:claude_usage_widget/data/services/preferences_service.dart';
import 'package:claude_usage_widget/data/services/tray_service.dart';
import 'package:claude_usage_widget/data/services/update_service.dart';
import 'package:claude_usage_widget/data/services/window_service.dart';
import 'package:claude_usage_widget/domain/models/accent_choice.dart';
import 'package:claude_usage_widget/domain/models/rate_limit.dart';
import 'package:claude_usage_widget/domain/models/usage_snapshot.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_cubit.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/widget_layout.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUsage extends Mock implements UsageRepository {}

class _MockStatusLine extends Mock implements StatusLineRepository {}

class _MockAutostart extends Mock implements AutostartService {}

class _MockWindow extends Mock implements WindowService {}

class _MockTray extends Mock implements TrayService {}

class _MockNotifications extends Mock implements NotificationService {}

class _FakeCallbacks extends Fake implements TrayCallbacks {}

void main() {
  late _MockUsage usage;
  late _MockStatusLine statusLine;
  late _MockAutostart autostart;
  late _MockWindow window;
  late _MockTray tray;
  late _MockNotifications notifications;
  late StreamController<UsageSnapshot> snapshots;
  late PreferencesService preferences;
  final now = DateTime(2026, 11, 13, 12);

  setUpAll(() {
    registerFallbackValue(_FakeCallbacks());
    registerFallbackValue(Size.zero);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
    usage = _MockUsage();
    statusLine = _MockStatusLine();
    autostart = _MockAutostart();
    window = _MockWindow();
    tray = _MockTray();
    notifications = _MockNotifications();
    snapshots = StreamController<UsageSnapshot>();
    when(() => usage.watch()).thenAnswer((_) => snapshots.stream);
    when(() => statusLine.isInstalled()).thenAnswer((_) async => false);
    when(() => autostart.isEnabled()).thenAnswer((_) async => false);
    when(() => window.moved).thenAnswer((_) => const Stream<Offset>.empty());
    when(() => window.setSize(any())).thenAnswer((_) async {});
    when(() => window.dispose()).thenAnswer((_) async {});
    when(() => window.setAlwaysOnTop(enabled: any(named: 'enabled')))
        .thenAnswer((_) async {});
    when(() => tray.start(any())).thenAnswer((_) async => true);
    when(
      () => tray.updateMenu(
        windowVisible: any(named: 'windowVisible'),
        startupEnabled: any(named: 'startupEnabled'),
      ),
    ).thenAnswer((_) async {});
    when(() => tray.setTooltip(any())).thenAnswer((_) async {});
    when(() => tray.dispose()).thenAnswer((_) async {});
    when(() => notifications.show(any(), any())).thenAnswer((_) async {});
  });

  // Not awaited: close() completes only once the cubit has cancelled its listener.
  tearDown(() => unawaited(snapshots.close()));

  UsageWidgetCubit make() => UsageWidgetCubit(
    usage: usage,
    statusLine: statusLine,
    autostart: autostart,
    preferences: preferences,
    window: window,
    tray: tray,
    notifications: notifications,
    morphDuration: Duration.zero,
    clock: () => now,
  );

  SubscriptionUsage subscription(double five) => SubscriptionUsage(
    fiveHour: RateLimit(
      usedPercent: five,
      resetsAt: now.add(const Duration(hours: 1)),
    ),
  );

  test('picked accent is applied, saved and restored', () async {
    UsageWidgetCubit withPicker() => UsageWidgetCubit(
      usage: usage,
      statusLine: statusLine,
      autostart: autostart,
      preferences: preferences,
      window: window,
      tray: tray,
      notifications: notifications,
      morphDuration: Duration.zero,
      clock: () => now,
      accentPicker: true,
    );
    final cubit = withPicker();
    expect(cubit.state.accent, AccentChoice.claude);
    await cubit.setAccent(AccentChoice.blue);
    expect(cubit.state.accent, AccentChoice.blue);
    await cubit.close();
    final restored = withPicker();
    expect(restored.state.accent, AccentChoice.blue);
    await restored.close();
    // Without the picker the saved choice is ignored.
    final plain = make();
    expect(plain.state.accent, AccentChoice.claude);
    await plain.close();
  });

  test('start loads settings and reports tray availability', () async {
    when(() => statusLine.isInstalled()).thenAnswer((_) async => true);
    final cubit = make();
    await cubit.start();
    expect(cubit.state.trayAvailable, isTrue);
    expect(cubit.state.statusLineInstalled, isTrue);
    await cubit.close();
  });

  test('new snapshots update state, tooltip and notify at 80%', () async {
    final cubit = make();
    await cubit.start();
    snapshots.add(subscription(85));
    await pumpEventQueue();
    expect(cubit.state.snapshot, isA<SubscriptionUsage>());
    verify(() => tray.setTooltip('Claude · 5h 85% · 7d --')).called(1);
    verify(() => notifications.show('Claude usage: 5-hour at 85%', any()))
        .called(1);
    await cubit.close();
  });

  blocTest<UsageWidgetCubit, UsageWidgetState>(
    'expanding grows the window first; collapsing shrinks it afterwards',
    build: make,
    act: (cubit) async {
      await cubit.toggleDetails();
      await cubit.toggleDetails();
    },
    expect: () => [
      isA<UsageWidgetState>().having(
        (s) => s.viewMode,
        'mode',
        ViewMode.details,
      ),
      isA<UsageWidgetState>().having((s) => s.viewMode, 'mode', ViewMode.pill),
    ],
    verify: (_) {
      final expanded = WidgetLayout.windowSizeFor(WidgetLayout.emptyDetails);
      final collapsed = WidgetLayout.windowSizeFor(WidgetLayout.pill);
      // Exactly two resizes: grow on expand, then shrink only after the
      // collapse has played.
      final sizes = verify(() => window.setSize(captureAny())).captured;
      expect(sizes, [expanded, collapsed]);
    },
  );

  test('a quick second tap wins: the window ends at the final view', () async {
    final cubit = UsageWidgetCubit(
      usage: usage,
      statusLine: statusLine,
      autostart: autostart,
      preferences: preferences,
      window: window,
      tray: tray,
      notifications: notifications,
      morphDuration: const Duration(milliseconds: 30),
      clock: () => now,
    );
    final first = cubit.toggleDetails();
    final second = cubit.toggleMenu();
    await Future.wait([first, second]);
    expect(cubit.state.viewMode, ViewMode.menu);
    final sizes = verify(() => window.setSize(captureAny())).captured;
    expect(sizes.last, WidgetLayout.windowSize(cubit.state));
    await cubit.close();
  });

  blocTest<UsageWidgetCubit, UsageWidgetState>(
    'the opacity slider previews while dragging and saves on release',
    build: make,
    act: (cubit) async {
      cubit
        ..setOpacity(0.7)
        ..setOpacity(0.2);
      await cubit.saveOpacity();
    },
    expect: () => [
      isA<UsageWidgetState>().having((s) => s.opacity, 'opacity', 0.7),
      // Clamped to the minimum, never invisible.
      isA<UsageWidgetState>().having((s) => s.opacity, 'opacity', 0.5),
    ],
    verify: (_) => expect(preferences.opacity, 0.5),
  );

  test(
    'always on top is on by default, toggles the window and is saved',
    () async {
      final cubit = make();
      expect(cubit.state.alwaysOnTop, isTrue);
      await cubit.toggleAlwaysOnTop();
      expect(cubit.state.alwaysOnTop, isFalse);
      verify(() => window.setAlwaysOnTop(enabled: false)).called(1);
      expect(preferences.alwaysOnTop, isFalse);
      await cubit.close();
    },
  );

  test('the glass starts at its clearest setting', () async {
    final cubit = make();
    expect(cubit.state.opacity, 0.5);
    await cubit.close();
  });

  blocTest<UsageWidgetCubit, UsageWidgetState>(
    'a failing settings write is shown as an error, not thrown',
    setUp: () =>
        when(() => statusLine.install())
            .thenThrow(const FormatException('bad json')),
    build: make,
    act: (cubit) => cubit.toggleStatusLine(),
    expect: () => [
      isA<UsageWidgetState>().having(
        (s) => s.errorMessage,
        'error',
        contains('bad json'),
      ),
    ],
  );

  blocTest<UsageWidgetCubit, UsageWidgetState>(
    'hiding to the tray hides the window and refreshes the tray menu',
    setUp: () =>
        when(() => window.setVisible(visible: any(named: 'visible')))
            .thenAnswer((_) async {}),
    build: make,
    act: (cubit) async {
      await cubit.start();
      await cubit.toggleVisibility();
    },
    verify: (_) {
      verify(() => window.setVisible(visible: false)).called(1);
    },
  );

  group('updates', () {
    late _MockUpdater updater;

    setUp(() {
      updater = _MockUpdater();
      when(() => updater.installsAutomatically).thenReturn(true);
      when(() => updater.install()).thenAnswer((_) async {});
    });

    UsageWidgetCubit makeWithUpdater() => UsageWidgetCubit(
      usage: usage,
      statusLine: statusLine,
      autostart: autostart,
      preferences: preferences,
      window: window,
      tray: tray,
      notifications: notifications,
      updater: updater,
      morphDuration: Duration.zero,
      clock: () => now,
    );

    test('a newer release is announced and installed once', () async {
      when(() => updater.newerVersion(any())).thenAnswer((_) async => '9.9.9');
      final cubit = makeWithUpdater();
      await cubit.start();
      await pumpEventQueue();
      expect(cubit.state.availableUpdate, '9.9.9');
      verify(() => updater.install()).called(1);

      await cubit.checkForUpdate();
      verifyNever(() => updater.install());
      await cubit.close();
    });

    test('nothing happens when no newer release exists', () async {
      when(() => updater.newerVersion(any())).thenAnswer((_) async => null);
      final cubit = makeWithUpdater();
      await cubit.start();
      await pumpEventQueue();
      expect(cubit.state.availableUpdate, isNull);
      verifyNever(() => updater.install());
      await cubit.close();
    });

    test('turned off, it never goes online', () async {
      await preferences.saveAutoUpdate(value: false);
      final cubit = makeWithUpdater();
      await cubit.start();
      await pumpEventQueue();
      verifyNever(() => updater.newerVersion(any()));
      await cubit.close();
    });

    test('the switch persists and starts checking when turned on', () async {
      await preferences.saveAutoUpdate(value: false);
      when(() => updater.newerVersion(any())).thenAnswer((_) async => null);
      final cubit = makeWithUpdater();
      await cubit.start();
      await cubit.toggleAutoUpdate();
      expect(cubit.state.autoUpdate, isTrue);
      expect(preferences.autoUpdate, isTrue);
      verify(() => updater.newerVersion(any())).called(1);
      await cubit.close();
    });

    test('where it cannot install itself it only announces', () async {
      when(() => updater.installsAutomatically).thenReturn(false);
      when(() => updater.newerVersion(any())).thenAnswer((_) async => '9.9.9');
      final cubit = makeWithUpdater();
      await cubit.start();
      await pumpEventQueue();
      expect(cubit.state.availableUpdate, '9.9.9');
      verifyNever(() => updater.install());

      await cubit.installUpdate();
      verify(() => updater.install()).called(1);
      await cubit.close();
    });
  });
}

class _MockUpdater extends Mock implements UpdateService {}
