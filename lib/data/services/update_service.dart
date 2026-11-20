import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:claude_usage_widget/config/app_constants.dart';
import 'package:claude_usage_widget/config/logger.dart';
import 'package:claude_usage_widget/domain/use_cases/version_compare.dart';

/// Finds and installs newer releases.
///
/// This is the only code in the app that touches the network: one anonymous
/// request for the latest release's version number. It sends nothing about
/// the user, and the user can turn it off in Settings.
abstract interface class UpdateService {
  /// The newest released version if it is newer than [current], else null.
  ///
  /// Returns null, rather than throwing, when the check cannot complete.
  Future<String?> newerVersion(String current);

  /// Installs the latest release and restarts the app, or on a platform with
  /// no installer opens the release page.
  Future<void> install();

  /// Whether [install] replaces the app by itself, rather than opening a page.
  bool get installsAutomatically;
}

/// Fetches the body of a URL; injected so tests need no network.
typedef Fetch = Future<String> Function(Uri url);

/// Starts a detached command; injected so tests start no processes.
typedef Launch = Future<void> Function(String executable, List<String> args);

/// An [UpdateService] backed by GitHub Releases.
class GitHubUpdateService implements UpdateService {
  /// Creates a service; [fetch] and [launch] default to the real thing.
  GitHubUpdateService({Fetch? fetch, Launch? launch, bool? supportsInstaller})
    : _fetch = fetch ?? _httpGet,
      _launch = launch ?? _startDetached,
      _supportsInstaller =
          supportsInstaller ?? (Platform.isMacOS || Platform.isLinux);

  final Fetch _fetch;
  final Launch _launch;
  final bool _supportsInstaller;

  static final _latestRelease = Uri.https(
    'api.github.com',
    '/repos/${AppConstants.repository}/releases/latest',
  );

  @override
  Future<String?> newerVersion(String current) async {
    try {
      final body = await _fetch(_latestRelease);
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;
      final tag = json['tag_name'];
      if (tag is! String) return null;
      final version = tag.replaceFirst(RegExp('^v'), '');
      return isNewerVersion(current, version) ? version : null;
    } on Exception catch (e) {
      // Offline, rate limited or an unexpected reply: try again next time.
      logWarning('Update check failed', e);
      return null;
    }
  }

  @override
  Future<void> install() {
    if (!_supportsInstaller) {
      return _launch(
        Platform.isWindows ? 'cmd' : 'xdg-open',
        Platform.isWindows
            ? ['/c', 'start', '', AppConstants.releasesPage]
            : [AppConstants.releasesPage],
      );
    }
    // install.sh verifies the checksum, replaces the app and reopens it.
    return _launch('/bin/sh', [
      '-c',
      'curl -fsSL ${AppConstants.installScriptUrl} | bash',
    ]);
  }

  @override
  bool get installsAutomatically => _supportsInstaller;

  static Future<String> _httpGet(Uri url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..userAgent = 'claude-usage-widget';
    try {
      final request = await client.getUrl(url);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('status ${response.statusCode}', uri: url);
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _startDetached(String executable, List<String> args) =>
      Process.start(
        executable,
        args,
        mode: ProcessStartMode.detached,
      ).then((_) {});
}
