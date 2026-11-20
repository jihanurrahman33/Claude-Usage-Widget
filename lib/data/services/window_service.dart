import 'dart:async';

import 'package:claude_usage_widget/config/logger.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// The native window: frameless, always on top, draggable.
abstract interface class WindowService {
  /// Creates the window at [size], placing it at [position] if given.
  Future<void> init({
    required Size size,
    required bool alwaysOnTop,
    Offset? position,
  });

  /// Keeps the window above other windows, or lets it be covered.
  Future<void> setAlwaysOnTop({required bool enabled});

  /// Resizes the window.
  Future<void> setSize(Size size);

  /// Starts a native drag of the window.
  Future<void> startDragging();

  /// Shows or hides the window.
  Future<void> setVisible({required bool visible});

  /// Closes the app.
  Future<void> close();

  /// Emits the new position after each user move.
  Stream<Offset> get moved;

  /// Releases listeners.
  Future<void> dispose();
}

/// [WindowService] backed by the `window_manager` plugin.
class DesktopWindowService with WindowListener implements WindowService {
  final _moved = StreamController<Offset>.broadcast();

  @override
  Stream<Offset> get moved => _moved.stream;

  @override
  Future<void> init({
    required Size size,
    required bool alwaysOnTop,
    Offset? position,
  }) async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        alwaysOnTop: alwaysOnTop,
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
        backgroundColor: const Color(0x00000000),
      ),
      () async {
        if (position != null) await windowManager.setPosition(position);
        try {
          await windowManager.setHasShadow(false);
        } on MissingPluginException catch (e) {
          // Not implemented by window_manager on Linux; the runner already
          // strips the shadow in CSS.
          logWarning('setHasShadow unsupported', e);
        }
        await windowManager.show();
      },
    );
  }

  @override
  Future<void> setAlwaysOnTop({required bool enabled}) =>
      windowManager.setAlwaysOnTop(enabled);

  @override
  Future<void> setSize(Size size) => windowManager.setSize(size);

  @override
  Future<void> startDragging() => windowManager.startDragging();

  @override
  Future<void> setVisible({required bool visible}) =>
      visible ? windowManager.show() : windowManager.hide();

  @override
  Future<void> close() => windowManager.destroy();

  @override
  void onWindowMoved() {
    unawaited(
      windowManager
          .getPosition()
          .then(_moved.add)
          .catchError((Object e) => logWarning('Reading position failed', e)),
    );
  }

  @override
  Future<void> dispose() async {
    windowManager.removeListener(this);
    await _moved.close();
  }
}
