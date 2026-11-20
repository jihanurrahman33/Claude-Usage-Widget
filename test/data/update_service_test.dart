import 'dart:io';

import 'package:claude_usage_widget/data/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GitHubUpdateService service({
    required Future<String> Function(Uri) fetch,
    List<List<String>>? launched,
    bool installer = true,
  }) => GitHubUpdateService(
    fetch: fetch,
    launch: (exe, args) async => launched?.add([exe, ...args]),
    supportsInstaller: installer,
  );

  test('reports a newer release without its v prefix', () async {
    final s = service(fetch: (_) async => '{"tag_name": "v0.2.0"}');
    expect(await s.newerVersion('0.1.0'), '0.2.0');
  });

  test('reports nothing when already current or ahead', () async {
    final s = service(fetch: (_) async => '{"tag_name": "v0.1.0"}');
    expect(await s.newerVersion('0.1.0'), isNull);
    expect(await s.newerVersion('0.1.1'), isNull);
  });

  test('asks only for the latest release of this repository', () async {
    Uri? asked;
    final s = service(
      fetch: (url) async {
        asked = url;
        return '{"tag_name": "v0.1.0"}';
      },
    );
    await s.newerVersion('0.1.0');
    expect(asked?.host, 'api.github.com');
    expect(asked?.path, endsWith('/releases/latest'));
  });

  test('a failed or odd reply is no update, never an error', () async {
    for (final reply in [
      () async => throw const SocketException('offline'),
      () async => throw const HttpException('status 403'),
      () async => 'not json',
      () async => '[]',
      () async => '{"tag_name": 5}',
      () async => '{}',
    ]) {
      expect(
        await service(fetch: (_) => reply()).newerVersion('0.1.0'),
        isNull,
      );
    }
  });

  test('install pipes the checksum-verifying installer through bash', () async {
    final launched = <List<String>>[];
    await service(fetch: (_) async => '', launched: launched).install();
    expect(launched.single.first, '/bin/sh');
    expect(launched.single.last, contains('install.sh | bash'));
  });

  test('without an installer it opens the release page instead', () async {
    final launched = <List<String>>[];
    final s = service(
      fetch: (_) async => '',
      launched: launched,
      installer: false,
    );
    await s.install();
    expect(launched.single.last, contains('/releases/latest'));
    expect(s.installsAutomatically, isFalse);
  });
}
