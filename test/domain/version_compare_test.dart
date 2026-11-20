import 'package:claude_usage_widget/domain/use_cases/version_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewerVersion', () {
    test('compares each part numerically', () {
      expect(isNewerVersion('0.1.0', '0.1.1'), isTrue);
      expect(isNewerVersion('0.1.9', '0.1.10'), isTrue);
      expect(isNewerVersion('0.9.0', '1.0.0'), isTrue);
      expect(isNewerVersion('0.1.1', '0.1.0'), isFalse);
      expect(isNewerVersion('0.1.0', '0.1.0'), isFalse);
    });

    test('ignores a v prefix and build or pre-release suffixes', () {
      expect(isNewerVersion('0.1.0', 'v0.1.1'), isTrue);
      expect(isNewerVersion('0.1.0+4', '0.1.0'), isFalse);
      expect(isNewerVersion('0.1.0', '0.1.1-beta'), isTrue);
    });

    test('never reports an update for something that is not a version', () {
      expect(isNewerVersion('0.1.0', 'nightly'), isFalse);
      expect(isNewerVersion('0.1.0', '1.0'), isFalse);
      expect(isNewerVersion('0.1.0', ''), isFalse);
      expect(isNewerVersion('garbage', '0.1.1'), isFalse);
    });
  });
}
