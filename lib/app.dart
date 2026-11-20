import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_cubit.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/views/usage_widget_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget: provides the cubit to the tree.
class UsageWidgetApp extends StatelessWidget {
  /// Creates the app around an already constructed [cubit].
  const UsageWidgetApp({
    required this.cubit,
    this.lightGlass = GlassTheme.light,
    super.key,
  });

  /// The state holder; closed when the app is disposed.
  final UsageWidgetCubit cubit;

  /// Palette for the light appearance on this platform.
  final GlassTheme lightGlass;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light, lightGlass: lightGlass),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      color: Colors.transparent,
      home: const UsageWidgetView(),
    ),
  );
}
