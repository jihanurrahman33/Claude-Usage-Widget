import 'package:claude_usage_widget/app.dart';
import 'package:claude_usage_widget/app_dependencies.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/widget_layout.dart';
import 'package:flutter/widgets.dart';

/// Builds the dependencies, opens the window and starts the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.create();
  await dependencies.window.init(
    size: WidgetLayout.windowSizeFor(WidgetLayout.pill),
    alwaysOnTop: dependencies.preferences.alwaysOnTop,
    position: dependencies.preferences.windowPosition,
  );
  runApp(
    UsageWidgetApp(
      cubit: dependencies.cubit,
      lightGlass: dependencies.lightGlass,
    ),
  );
  await dependencies.cubit.start();
}
