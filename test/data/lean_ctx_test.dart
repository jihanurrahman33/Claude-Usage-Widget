import 'dart:async';
import 'dart:io';

import 'package:claude_usage_widget/data/models/lean_ctx_stats_mapper.dart';
import 'package:claude_usage_widget/data/services/lean_ctx_service.dart';
import 'package:claude_usage_widget/domain/models/lean_ctx_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _gain = '''
{
  "bridge": {"proxy_running": false},
  "summary": {
    "total_commands": 2175,
    "tokens_saved": 288018,
    "effective_compression_pct": 26.234429612510223
  }
}''';

void main() {
  group('mapLeanCtxGain', () {
    test('reads the figures lean-ctx gain reports', () {
      expect(
        mapLeanCtxGain(_gain),
        const LeanCtxStats(
          tokensSaved: 288018,
          reductionPercent: 26.234429612510223,
          commands: 2175,
        ),
      );
    });

    test('anything unexpected is no stats, never wrong numbers', () {
      for (final text in [
        '',
        'not json',
        '[]',
        '{}',
        '{"summary": 3}',
        '{"summary": {"tokens_saved": "x"}}',
        '{"summary": {"tokens_saved": 1, "total_commands": 1}}',
        '{"summary": {"tokens_saved": -1, "total_commands": 1,'
            ' "effective_compression_pct": 5}}',
      ]) {
        expect(mapLeanCtxGain(text), isNull, reason: text);
      }
    });

    test('clamps an out-of-range percentage', () {
      final stats = mapLeanCtxGain(
        '{"summary": {"tokens_saved": 1, "total_commands": 1,'
        ' "effective_compression_pct": 140}}',
      );
      expect(stats?.reductionPercent, 100);
    });
  });

  group('CliLeanCtxService', () {
    // The service looks for lean-ctx.exe on Windows, with that platform's
    // separators, so the expected path is built the same way.
    final binary = p.join(
      '/opt/homebrew/bin',
      Platform.isWindows ? 'lean-ctx.exe' : 'lean-ctx',
    );

    CliLeanCtxService service({
      required Future<ProcessResult> Function(String, List<String>) run,
      bool installed = true,
      Duration timeout = const Duration(seconds: 5),
    }) => CliLeanCtxService(
      searchDirs: const ['/nowhere', '/opt/homebrew/bin'],
      run: (exe, args, {environment}) => run(exe, args),
      exists: (path) => installed && path == binary,
      timeout: timeout,
    );

    ProcessResult ok(String out) => ProcessResult(1, 0, out, '');

    test('finds the binary outside the PATH it was started with', () async {
      final s = service(run: (_, _) async => ok(_gain));
      expect(await s.isInstalled(), isTrue);
    });

    test('is not installed when no search directory has it', () async {
      final s = service(run: (_, _) async => ok(_gain), installed: false);
      expect(await s.isInstalled(), isFalse);
      expect(await s.read(), isNull);
    });

    test('runs gain --json and maps the result', () async {
      List<String>? args;
      String? exe;
      final s = service(
        run: (e, a) async {
          exe = e;
          args = a;
          return ok(_gain);
        },
      );
      expect((await s.read())?.tokensSaved, 288018);
      expect(exe, binary);
      expect(args, ['gain', '--json']);
    });

    test('a failing, odd, missing or slow run is null, not an error', () async {
      final failures = <Future<ProcessResult> Function(String, List<String>)>[
        (_, _) async => ProcessResult(1, 2, '', 'boom'),
        (_, _) async => ok('garbage'),
        (_, _) => throw const ProcessException('lean-ctx', ['gain']),
        (_, _) => Completer<ProcessResult>().future,
      ];
      for (final run in failures) {
        final s = service(run: run, timeout: const Duration(milliseconds: 20));
        expect(await s.read(), isNull);
      }
    });
  });
}
