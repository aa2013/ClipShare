import 'dart:io';

const luaDirectory = 'lib/core/services/rules/lua';
const templateGroups = <String, Map<String, String>>{
  'global_function.dart': {'luaGlobalFun': 'global_function.lua'},
  'sandbox.dart': {
    'luaSandboxEnv': 'sandbox_env.lua',
    'luaSandboxWrapper': 'sandbox_wrapper.lua',
  },
  'modules.dart': {
    'luaCustomModules': 'custom_modules.lua',
    'luaModuleSandboxWrapper': 'module_sandbox_wrapper.lua',
    'luaModuleCompileWrapper': 'module_compile_wrapper.lua',
  },
  'template.dart': {'luaTemplateRule': 'template_rule.lua'},
};

/// 从项目目录生成模板；--check 仅检查产物是否与源文件一致。
void main(List<String> args) {
  if (args.any((arg) => arg != '--check')) {
    stderr.writeln('Usage: dart run tools/generate_lua_templates.dart [--check]');
    exitCode = 64;
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final directory = Directory('${root.path}/$luaDirectory');
  final outputs = generateTemplates(directory);
  var stale = false;
  for (final entry in outputs.entries) {
    final file = File('${directory.path}/${entry.key}');
    final matches = file.existsSync() &&
        file.readAsStringSync().replaceAll('\r\n', '\n') == entry.value;
    if (matches) {
      continue;
    }
    if (args.contains('--check')) {
      stderr.writeln('Outdated Lua template: ${entry.key}');
      stale = true;
    } else {
      file.writeAsStringSync(entry.value);
      stdout.writeln('Generated ${entry.key}');
    }
  }
  if (stale) {
    exitCode = 1;
  }
}

/// 读取目录内固定的模板清单，展开引用后生成四个 Dart 文件。
Map<String, String> generateTemplates(Directory directory) {
  final sources = <String, String>{};
  for (final group in templateGroups.values) {
    for (final entry in group.entries) {
      sources[entry.key] = File('${directory.path}/src/${entry.value}')
          .readAsStringSync().replaceAll('\r\n', '\n');
    }
  }
  return {
    for (final group in templateGroups.entries)
      group.key: '// GENERATED CODE - DO NOT MODIFY BY HAND.\n'
          '// 修改 src/ 内 Lua 源文件后运行 dart run tools/generate_lua_templates.dart。\n\n'
          '${group.value.entries.map((entry) {
            final source = expandTemplate(entry.key, sources);
            // language=lua 是 IDE 语言注入标记，编辑器据此对多行字符串按 Lua 语法高亮。
            return '/// 内置 Lua 模板，来源：${entry.value}。\n'
                '//language=lua\n'
                'const String ${entry.key} = ${encodeLuaSource(source)};\n';
          }).join('\n\n')}\n',
  };
}

/// 将 Lua 源码整体编码为 raw 三引号多行字符串，Lua 内容顶到行首保持原行结构。
/// raw 形态使源码中的反斜杠与美元符原样保留，无需逐字符转义；
/// 多行字符串紧跟开头的单个换行不计入字面量值，由它把内容行推回行首实现逐字节一致。
String encodeLuaSource(String source) {
  if (source.isEmpty) {
    return "''";
  }
  // 三引号序列会提前终止多行字符串，且 raw 形态无法转义，出现即无法安全编码。
  if (source.contains("'''")) {
    throw StateError("Lua source contains ''' and cannot be encoded as a raw multiline string");
  }
  return "r'''\n$source'''";
}

/// 展开注释包含点并还原运行时参数；引用链用于拒绝循环包含。
String expandTemplate(String name, Map<String, String> sources, [List<String> chain = const []]) {
  if (chain.contains(name)) {
    throw StateError('Circular Lua include: ${[...chain, name].join(' -> ')}');
  }
  final source = sources[name];
  if (source == null) {
    throw StateError('Unknown Lua include: $name');
  }
  final expanded = source.replaceAllMapped(
    RegExp(r'-- @include ([A-Za-z][A-Za-z0-9_]*)'),
    (match) => expandTemplate(match.group(1)!, sources, [...chain, name]),
  );
  return expanded.replaceAllMapped(
    RegExp(r'\b__TPL_([A-Za-z][A-Za-z0-9_]*)__\b'),
    (match) => '{{${match.group(1)}}}',
  );
}
