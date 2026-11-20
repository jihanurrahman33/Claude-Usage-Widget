import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the dependency rule: code may only depend inwards.
///
///   ui  ──►  data  ──►  domain  ──►  config
void main() {
  const package = 'package:claude_usage_widget';

  /// Imports in `lib/[layer]` that point at any of [forbidden].
  List<String> violations(String layer, List<String> forbidden) => [
    for (final file
        in Directory('lib/$layer')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
      for (final line in file.readAsLinesSync())
        if (line.startsWith('import ') &&
            forbidden.any((target) => line.contains("'$package/$target/")))
          '${file.path}: $line',
  ];

  test('domain depends on nothing but config', () {
    expect(violations('domain', ['data', 'ui']), isEmpty);
  });

  test('data does not depend on ui', () {
    expect(violations('data', ['ui']), isEmpty);
  });

  test('config depends on no other layer', () {
    expect(violations('config', ['domain', 'data', 'ui']), isEmpty);
  });

  test('domain stays free of Flutter UI and I/O', () {
    final offenders = [
      for (final file in Directory(
        'lib/domain',
      ).listSync(recursive: true).whereType<File>())
        for (final line in file.readAsLinesSync())
          if (line.startsWith('import ') &&
              (line.contains("'dart:io'") ||
                  line.contains('package:flutter/material.dart') ||
                  line.contains('package:material_ui/') ||
                  line.contains('package:cupertino_ui/') ||
                  line.contains('package:flutter/widgets.dart')))
            '${file.path}: $line',
    ];
    expect(offenders, isEmpty);
  });
}
