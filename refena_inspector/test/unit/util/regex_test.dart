import 'package:flutter_test/flutter_test.dart';
import 'package:refena_inspector/util/regex.dart';

void main() {
  group('versionRegex', () {
    test('Should parse 1.2.3', () {
      final match = versionRegex.firstMatch('version: 1.2.3');

      expect(match, isNotNull);
      expect(match!.group(1), '1.2.3');
    });

    test('Should ignore if there are leading spaces', () {
      final match = versionRegex.firstMatch('  version: 1.2.3');

      expect(match, isNull);
    });

    test('Should parse the correct line', () {
      final match = versionRegex.firstMatch('''
name: refena_inspector
description: Blala bla
version: 1.2.3

environment:
  sdk: ">=2.12.0 <3.0.0"
''');

      expect(match, isNotNull);
      expect(match!.group(1), '1.2.3');
    });

    test('Should parse the correct line with build number', () {
      final match = versionRegex.firstMatch('''
name: refena_inspector
description: Blala bla
version: 1.2.3+42

environment:
  sdk: ">=2.12.0 <3.0.0"
''');

      expect(match, isNotNull);
      expect(match!.group(1), '1.2.3+42');
    });
  });
}
