// 一次性迁移脚本：解析旧项目 GetX 翻译 switch 文件，生成 Flutter gen-l10n ARB 文件。
// 运行方式：dart run scripts/gen_arb_from_getx.dart
// 输入：旧项目 en_us_translations.dart / zh_cn_translations.dart
// 输出：lib/l10n/arb/app_en.arb / app_zh.arb
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final oldProjectPath = args.isNotEmpty
      ? args[0]
      : r'G:\Study\Flutter\ClipShare';

  final srcRoot = Directory.current.path;
  final arbOutDir = Directory('$srcRoot${Platform.pathSeparator}lib${Platform.pathSeparator}l10n${Platform.pathSeparator}arb');
  if (!arbOutDir.existsSync()) {
    arbOutDir.createSync(recursive: true);
  }

  final sources = [
    _SourceSpec(
      dartPath: '$oldProjectPath${Platform.pathSeparator}lib${Platform.pathSeparator}app${Platform.pathSeparator}translations${Platform.pathSeparator}en_us_translations.dart',
      arbPath: '${arbOutDir.path}${Platform.pathSeparator}app_en.arb',
      locale: 'en',
      constants: const {
        'appName': 'ClipShare',
        'port': '42317',
        'kOnHistoryChangedBroadcastAction': r'${appPkg}.ACTION_ON_HISTORY_CHANGED',
      },
    ),
    _SourceSpec(
      dartPath: '$oldProjectPath${Platform.pathSeparator}lib${Platform.pathSeparator}app${Platform.pathSeparator}translations${Platform.pathSeparator}zh_cn_translations.dart',
      arbPath: '${arbOutDir.path}${Platform.pathSeparator}app_zh.arb',
      locale: 'zh',
      constants: const {
        'appName': 'ClipShare',
        'port': '42317',
        'kOnHistoryChangedBroadcastAction': r'${appPkg}.ACTION_ON_HISTORY_CHANGED',
      },
    ),
  ];

  for (final spec in sources) {
    final entries = _parseSwitch(spec.dartPath, spec.constants);
    _writeArb(spec.arbPath, spec.locale, entries);
    stdout.writeln('generated ${spec.arbPath}: ${entries.length} keys');
  }
}

class _SourceSpec {
  const _SourceSpec({
    required this.dartPath,
    required this.arbPath,
    required this.locale,
    required this.constants,
  });

  final String dartPath;
  final String arbPath;
  final String locale;
  final Map<String, String> constants;
}

class _Entry {
  _Entry(this.key, this.message, this.placeholders);

  final String key;
  final String message;
  final Map<String, _PlaceholderSpec> placeholders;
}

class _PlaceholderSpec {
  _PlaceholderSpec(this.name);

  final String name;
}

/// 解析 Dart switch 文件，提取 case 与对应文案。
List<_Entry> _parseSwitch(String filePath, Map<String, String> constants) {
  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('NOT FOUND: $filePath');
    return const [];
  }
  final lines = file.readAsLinesSync();
  final entries = <_Entry>[];
  var currentKey = '';
  var collected = <String>[]; // 收集到的字符串字面量片段（已解析转义）
  var inReturn = false;

  void flush() {
    if (currentKey.isEmpty) return;
    if (collected.isEmpty) return;
    // Dart 相邻字符串字面量直接拼接
    final raw = collected.join();
    final converted = _convertMessage(raw, constants, currentKey);
    // historyFloatCountTemplate 的 {count} 为原生保留字面量，不声明 placeholders
    final placeholders = currentKey == 'historyFloatCountTemplate'
        ? const <String, _PlaceholderSpec>{}
        : _extractPlaceholders(converted.message);
    entries.add(_Entry(currentKey, converted.message, placeholders));
    currentKey = '';
    collected = <String>[];
    inReturn = false;
  }

  for (final line in lines) {
    final trimmed = line.trim();
    final caseMatch = RegExp(r'^case TranslationKey\.([a-zA-Z0-9_]+):\s*$').firstMatch(trimmed);
    if (caseMatch != null) {
      flush();
      currentKey = caseMatch.group(1)!;
      continue;
    }
    if (currentKey.isEmpty) continue;

    // 处理 return 语句：收集引号字符串字面量直到分号
    if (!inReturn) {
      final retMatch = RegExp(r'^return\s+(.+?);?\s*$').firstMatch(trimmed);
      if (retMatch == null) continue;
      inReturn = true;
      final rest = retMatch.group(1)!;
      final res = _parseStringPieces(rest, trimmed);
      collected.addAll(res.pieces);
      if (res.terminated) {
        flush();
      }
      continue;
    }

    // 已进入 return，处理后续拼接行
    final res = _parseStringPieces(trimmed, trimmed);
    collected.addAll(res.pieces);
    if (res.terminated) {
      flush();
    }
  }
  flush(); // 文件末尾兜底

  // 按枚举顺序输出（switch 顺序即枚举声明顺序）
  return entries;
}

class _Pieces {
  _Pieces(this.pieces, this.terminated);

  final List<String> pieces;
  final bool terminated;
}

/// 解析一行中的字符串字面量序列，返回解析后的片段与是否以分号结束。
_Pieces _parseStringPieces(String text, String rawLine) {
  final pieces = <String>[];
  var i = 0;
  var terminated = false;

  while (i < text.length) {
    final ch = text[i];
    if (ch == ';') {
      terminated = true;
      i++;
      // 分号后可能有尾部内容（如注释），忽略
      break;
    }
    if (ch == '"' || ch == "'") {
      final res = _readStringLiteral(text, i);
      pieces.add(res.value);
      i = res.end;
      continue;
    }
    // 其他字符（如操作符 +、空白）跳过
    i++;
  }

  return _Pieces(pieces, terminated);
}

/// 从 [start] 开始的引号字符串字面量，返回解析后的值（含转义处理）与结束下标。
({String value, int end}) _readStringLiteral(String text, int start) {
  final quote = text[start];
  final buf = StringBuffer();
  var i = start + 1;
  while (i < text.length) {
    final ch = text[i];
    if (ch == quote) {
      return (value: buf.toString(), end: i + 1);
    }
    if (ch == r'\') {
      final next = i + 1 < text.length ? text[i + 1] : '';
      switch (next) {
        case 'n':
          buf.write('\n');
        case 't':
          buf.write('\t');
        case 'r':
          buf.write('\r');
        case r'\':
          buf.write(r'\');
        case "'":
          buf.write("'");
        case '"':
          buf.write('"');
        case r'$':
          buf.write(r'$');
        case '0':
          buf.write('\u0000');
        default:
          // 未知转义原样保留反斜杠
          buf.write('\\$next');
      }
      i += 2;
      continue;
    }
    // 保留 ${...} 插值的原始文本，后续统一转换
    if (ch == r'$' && i + 1 < text.length && text[i + 1] == '{') {
      // 复制到 }
      var j = i + 2;
      while (j < text.length && text[j] != '}') {
        j++;
      }
      buf.write(text.substring(i, j + 1 > text.length ? text.length : j + 1));
      i = j + 1;
      continue;
    }
    buf.write(ch);
    i++;
  }
  // 未闭合（理论上不会发生），返回已收集内容
  return (value: buf.toString(), end: text.length);
}

class _Converted {
  _Converted(this.message, this.usedConstants);

  final String message;
  final Set<String> usedConstants;
}

/// 将 GetX 文案转换为 ARB 消息：
/// - @param -> {param}
/// - ${Constants.xxx} -> {placeholderName}
/// - {count} 保留字面量（传给原生端）
/// - 修复 @minCode} 笔误
_Converted _convertMessage(String raw, Map<String, String> constants, String key) {
  var result = raw;
  final usedConstants = <String>{};

  // 1. ${Constants.xxx} 插值 -> {映射名}
  final constantRegex = RegExp(r'\$\{Constants\.([a-zA-Z0-9_]+)\}');
  result = result.replaceAllMapped(constantRegex, (m) {
    final name = m.group(1)!;
    usedConstants.add(name);
    return '{$name}';
  });

  // 2. @param -> {param}
  //    注意排除已形成的 {xxx}（上一步产生的 {appName} 等），先转换 @ 形式
  final atRegex = RegExp(r'@([a-zA-Z][a-zA-Z0-9_]*)');
  result = result.replaceAllMapped(atRegex, (m) {
    final name = m.group(1)!;
    return '{$name}';
  });

  // 3. 修复 @minCode} 笔误（转换成 {minCode}} -> 删除多余 }）
  //    此时文本应为 "{minName}({minCode})\n" 形式，若出现 "{x}}" 则去掉一个 }
  final dupClose = RegExp(r'\{([a-zA-Z0-9_]+)\}\}');
  result = result.replaceAllMapped(dupClose, (m) => '{${m.group(1)}}');

  // 4. historyFloatCountTemplate 的 {count} 是传给原生端替换的字面量占位符，
  //    配合 l10n.yaml 的 use-escaping: true，用 ICU 单引号包裹使其原样输出。
  if (key == 'historyFloatCountTemplate') {
    result = result.replaceAll('{count}', "'{count}'");
  }

  // 5. use-escaping 模式下普通撇号需写成连续两个单引号（''）才会输出单个 '，
  //    否则会被当作转义块开始导致 ICU 解析失败。
  result = result.replaceAll("'", "''");

  // 6. 上一步会把第 4 步生成的 '{count}' 也改成 ''{count}''，
  //    需恢复为正确的字面转义块（一对单引号包裹 {count}）。
  if (key == 'historyFloatCountTemplate') {
    result = result.replaceAll("''{count}''", "'{count}'");
  }

  return _Converted(result, usedConstants);
}

/// 从消息中提取需要声明的 placeholders。
Map<String, _PlaceholderSpec> _extractPlaceholders(String message) {
  final placeholders = <String, _PlaceholderSpec>{};
  final regex = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}');
  for (final m in regex.allMatches(message)) {
    placeholders[m.group(1)!] = _PlaceholderSpec(m.group(1)!);
  }
  return placeholders;
}

/// 写出 ARB 文件。
void _writeArb(String arbPath, String locale, List<_Entry> entries) {
  final map = <String, dynamic>{
    '@@locale': locale,
  };
  for (final entry in entries) {
    map[entry.key] = entry.message;
    final meta = <String, dynamic>{
      'description': 'translated key: ${entry.key}',
    };
    if (entry.placeholders.isNotEmpty) {
      final ph = <String, dynamic>{};
      for (final p in entry.placeholders.values) {
        ph[p.name] = {
          'type': 'String',
        };
      }
      meta['placeholders'] = ph;
    }
    map['@${entry.key}'] = meta;
  }
  const encoder = JsonEncoder.withIndent('  ');
  File(arbPath).writeAsStringSync(encoder.convert(map));
}
