import 'dart:async';

import 'package:claude_usage_widget/config/app_constants.dart';
import 'package:claude_usage_widget/ui/core/glass_theme.dart';
import 'package:claude_usage_widget/ui/core/widgets/glass_tile.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/cubit/usage_widget_state.dart';
import 'package:claude_usage_widget/ui/features/usage_widget/settings_actions.dart';
import 'package:flutter/cupertino.dart';

/// Settings, shown on right-click: grouped rows with switches and a slider.
class MenuView extends StatelessWidget {
  /// Creates the settings for [state]; actions are sent to [actions].
  const MenuView({required this.state, required this.actions, super.key});

  /// Current state, used for values.
  final UsageWidgetState state;

  /// Receives the actions.
  final SettingsActions actions;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final error = state.errorMessage;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: AppText.style(
                  15,
                  color: glass.label,
                  weight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _TextAction(label: 'Done', onTap: actions.closeMenu),
            ],
          ),
          const SizedBox(height: 10),
          // Dragging inside the groups belongs to the controls, not the window.
          GestureDetector(
            onPanStart: (_) {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Group(
                  rows: [
                    _MenuRow(
                      label: 'Status Line',
                      trailing: _Toggle(
                        value: state.statusLineInstalled,
                        onChanged: actions.toggleStatusLine,
                      ),
                    ),
                    _MenuRow(
                      label: 'Always on Top',
                      trailing: _Toggle(
                        value: state.alwaysOnTop,
                        onChanged: actions.toggleAlwaysOnTop,
                      ),
                    ),
                    _MenuRow(
                      label: 'Open at Login',
                      trailing: _Toggle(
                        value: state.startupEnabled,
                        onChanged: actions.toggleStartup,
                      ),
                    ),
                    _MenuRow(
                      label: 'Auto-update',
                      trailing: _Toggle(
                        value: state.autoUpdate,
                        onChanged: actions.toggleAutoUpdate,
                      ),
                    ),
                    _MenuRow(
                      label: 'Opacity',
                      trailing: _OpacitySlider(
                        value: state.opacity,
                        onChanged: actions.setOpacity,
                        onChangeEnd: actions.saveOpacity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Group(
                  rows: [
                    if (state.availableUpdate case final version?)
                      _MenuRow(
                        label: 'Update to $version',
                        accent: true,
                        onTap: actions.installUpdate,
                      ),
                    if (state.trayAvailable)
                      _MenuRow(
                        label: 'Hide to Tray',
                        onTap: actions.toggleVisibility,
                      ),
                    _MenuRow(
                      label: 'Quit',
                      destructive: true,
                      onTap: actions.quit,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            error ?? '${AppConstants.appName} ${AppConstants.version}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(
              10,
              color: error == null ? glass.tertiary : glass.danger,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rows in one inset panel, separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final separator = Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 12),
      color: GlassTheme.of(context).separator,
    );
    return GlassTile(
      radius: 13,
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) separator,
            row,
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.label,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.accent = false,
  });

  final String label;
  final Widget? trailing;
  final Future<void> Function()? onTap;
  final bool destructive;
  final bool accent;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.of(context);
    final onTap = widget.onTap;
    final highlight = onTap == null
        ? 0.0
        : _pressed
        ? 0.12
        : _hovered
        ? 0.06
        : 0.0;
    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: glass.label.withValues(alpha: highlight),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              style: AppText.style(
                13,
                color: widget.destructive
                    ? glass.danger
                    : widget.accent
                    ? glass.accent
                    : glass.label,
              ),
            ),
          ),
          ?widget.trailing,
        ],
      ),
    );
    if (onTap == null) return row;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () => unawaited(onTap()),
        child: row,
      ),
    );
  }
}

/// A compact iOS-style switch.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 38,
    height: 23,
    child: FittedBox(
      child: CupertinoSwitch(
        value: value,
        activeTrackColor: GlassTheme.of(context).ok,
        onChanged: (_) => unawaited(onChanged()),
      ),
    ),
  );
}

/// A compact iOS-style slider for the glass strength.
class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final Future<void> Function() onChangeEnd;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 124,
    height: 31,
    child: FittedBox(
      child: CupertinoSlider(
        value: value.clamp(AppConstants.minOpacity, 1.0).toDouble(),
        min: AppConstants.minOpacity,
        activeColor: GlassTheme.of(context).accent,
        onChanged: onChanged,
        onChangeEnd: (_) => unawaited(onChangeEnd()),
      ),
    ),
  );
}

/// A tinted text button, as in a navigation bar.
class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => unawaited(onTap()),
    child: Padding(
      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      child: Text(
        label,
        style: AppText.style(
          13,
          color: GlassTheme.of(context).accent,
          weight: FontWeight.w600,
        ),
      ),
    ),
  );
}
