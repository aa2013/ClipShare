import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../../../../tools/generate_lua_templates.dart' as generator;

void main() {
  group('Lua template generator', () {
    test('expands shared snippets and restores runtime parameters', () {
      final result = generator.expandTemplate('wrapper', {
        'wrapper': 'function run()\n  -- @include env\nend\n',
        'env': 'local enabled = __TPL_isTest__\n',
      });
      expect(result, 'function run()\n  local enabled = {{isTest}}\n\nend\n');
    });

    test('rejects missing includes', () {
      expect(
        () => generator.expandTemplate('wrapper', {'wrapper': '-- @include missing'}),
        throwsStateError,
      );
    });

    test('rejects circular includes', () {
      expect(
        () => generator.expandTemplate('a', {
          'a': '-- @include b',
          'b': '-- @include a',
        }),
        throwsStateError,
      );
    });

    test('checked in outputs match Lua sources', () {
      final directory = Directory(generator.luaDirectory);
      final outputs = generator.generateTemplates(directory);
      for (final output in outputs.entries) {
        expect(
          File('${directory.path}/${output.key}').readAsStringSync().replaceAll('\r\n', '\n'),
          output.value,
          reason: 'Regenerate ${output.key}',
        );
      }
    });
  });
}
