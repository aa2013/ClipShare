import 'package:clipshare/app/data/models/semantic_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemanticVersion', () {
    test('parses major minor and patch', () {
      final version = SemanticVersion.parse('1.1.0');

      expect(version.major, 1);
      expect(version.minor, 1);
      expect(version.patch, 0);
      expect(version.toString(), '1.1.0');
    });

    test('compares versions by major minor and patch', () {
      expect(
        SemanticVersion.parse('1.0.9') < SemanticVersion.parse('1.1.0'),
        isTrue,
      );
      expect(
        SemanticVersion.parse('1.1.0') == SemanticVersion.parse('1.1.0'),
        isTrue,
      );
      expect(
        SemanticVersion.parse('1.1.1') > SemanticVersion.parse('1.1.0'),
        isTrue,
      );
      expect(
        SemanticVersion.parse('1.10.0') > SemanticVersion.parse('1.1.0'),
        isTrue,
      );
    });
  });
}
