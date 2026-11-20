// Renders the real widget view in every state and both themes to PNG, for
// visual review without a screen:
//   PREVIEW_OUT=/tmp flutter test tool/preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:claude_usage_widget/domain/models/accent_choice.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/motion.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_cubit.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/views/usage_widget_view.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/widget_layout.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/ui/support.dart';

/// Stand-ins for what might be behind the widget.
const _backdrops = <String, List<Color>>{
  'wallpaper': [Color(0xFF2B5C8A), Color(0xFF9B4A7A), Color(0xFFE39A4C)],
  'bright': [Color(0xFFF4F5F7), Color(0xFFE2E6EC)],
  'dim': [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
  // Transparent, for compositing screenshots (see tool/make_screenshots.py).
  'clear': [Color(0x00000000), Color(0x00000000)],
};

void main() {
  final out = Platform.environment['PREVIEW_OUT'] ?? '/tmp';
  const scale = 2.0;

  final cases = <String, UsageWidgetState>{
    'pill': UsageWidgetState(now: testNow, snapshot: subscription()),
    'pill_high': UsageWidgetState(
      now: testNow,
      snapshot: subscription(five: 93, seven: 72),
    ),
    'pill_api': UsageWidgetState(now: testNow, snapshot: apiUsage),
    'pill_empty': UsageWidgetState(now: testNow),
    'details': UsageWidgetState(
      now: testNow,
      snapshot: subscription(),
      viewMode: ViewMode.details,
    ),
    'details_api': UsageWidgetState(
      now: testNow,
      snapshot: apiUsage,
      viewMode: ViewMode.details,
    ),
    'details_empty': UsageWidgetState(now: testNow, viewMode: ViewMode.details),
    'menu': UsageWidgetState(
      now: testNow,
      snapshot: subscription(),
      viewMode: ViewMode.menu,
      statusLineInstalled: true,
      trayAvailable: true,
    ),
    'menu_accent': UsageWidgetState(
      now: testNow,
      snapshot: subscription(),
      viewMode: ViewMode.menu,
      statusLineInstalled: true,
      trayAvailable: true,
      accentPickerAvailable: true,
      accent: AccentChoice.blue,
    ),
    'details_accent': UsageWidgetState(
      now: testNow,
      snapshot: subscription(),
      viewMode: ViewMode.details,
      accentPickerAvailable: true,
      accent: AccentChoice.blue,
    ),
  };

  setUpAll(loadAppFont);

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: backdrop, value: colors) in _backdrops.entries) {
      for (final MapEntry(key: name, value: state) in cases.entries) {
        testWidgets('$name ${brightness.name} $backdrop', (tester) async {
          final cubit = _PreviewCubit();
          whenListen(
            cubit,
            const Stream<UsageWidgetState>.empty(),
            initialState: state,
          );
          final size = WidgetLayout.windowSize(state);
          tester.view
            ..physicalSize = size * scale
            ..devicePixelRatio = scale;
          addTearDown(tester.view.reset);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: BlocProvider<UsageWidgetCubit>.value(
                  value: cubit,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: buildAppTheme(brightness),
                    color: const Color(0x00000000),
                    home: const UsageWidgetView(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(AppMotion.value);
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: scale);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$out/${name}_${brightness.name}_$backdrop.png')
                .writeAsBytesSync(data!.buffer.asUint8List());
          });
        });
      }
    }
  }
}

class _PreviewCubit extends MockCubit<UsageWidgetState>
    implements UsageWidgetCubit {}
