import 'dart:async';
import 'dart:io';

import 'package:claude_usage_widget/config/logger.dart';
import 'package:claude_usage_widget/data/models/lean_ctx_stats_mapper.dart';
import 'package:claude_usage_widget/data/services/process_runner.dart';
import 'package:claude_usage_widget/domain/models/lean_ctx_stats.dart';
import 'package:path/path.dart' as p;

/// Reads lean-ctx's savings from the local `lean-ctx` command.
///
/// Nothing here goes online: it runs a program on this machine and reads its
/// output.
abstract interface class LeanCtxService {
  /// Whether lean-ctx is installed.
  Future<bool> isInstalled();

  /// The current figures, or null if they cannot be read right now.
  Future<LeanCtxStats?> read();
}

/// A [LeanCtxService] that runs `lean-ctx gain --json`.
class CliLeanCtxService implements LeanCtxService {
  /// Creates a service that looks for `lean-ctx` in [searchDirs].
  ///
  /// An app started from Finder or a launcher does not inherit the shell's
  /// PATH, so [searchDirs] should list where lean-ctx is usually installed as
  /// well as the PATH entries.
  CliLeanCtxService({
    required this.searchDirs,
    this._run = runProcess,
    bool Function(String path)? exists,
    this.timeout = const Duration(seconds: 15),
  }) : _exists = exists ?? ((path) => File(path).existsSync());

  /// Directories searched for the executable, in order.
  final List<String> searchDirs;

  /// How long one run may take.
  final Duration timeout;

  final ProcessRunner _run;
  final bool Function(String path) _exists;
  String? _executable;

  /// The usual places, then every PATH entry.
  static List<String> defaultSearchDirs(Map<String, String> env) {
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '.';
    final separator = Platform.isWindows ? ';' : ':';
    return [
      ...(env['PATH'] ?? '').split(separator).where((d) => d.isNotEmpty),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      p.join(home, '.local', 'bin'),
      p.join(home, '.cargo', 'bin'),
      '/usr/bin',
    ];
  }

  String? _find() {
    final cached = _executable;
    if (cached != null && _exists(cached)) return cached;
    final name = Platform.isWindows ? 'lean-ctx.exe' : 'lean-ctx';
    for (final dir in searchDirs) {
      final candidate = p.join(dir, name);
      if (_exists(candidate)) return _executable = candidate;
    }
    return _executable = null;
  }

  @override
  Future<bool> isInstalled() async => _find() != null;

  @override
  Future<LeanCtxStats?> read() async {
    final executable = _find();
    if (executable == null) return null;
    try {
      final result = await _run(executable, const [
        'gain',
        '--json',
      ]).timeout(timeout);
      if (result.exitCode != 0) {
        logWarning('lean-ctx gain exited with ${result.exitCode}');
        return null;
      }
      final stats = mapLeanCtxGain('${result.stdout}');
      if (stats == null) logWarning('lean-ctx gain output not recognised');
      return stats;
    } on ProcessException catch (e) {
      logWarning('Could not run lean-ctx', e);
      return null;
    } on TimeoutException catch (e) {
      logWarning('lean-ctx gain timed out', e);
      return null;
    }
  }
}
