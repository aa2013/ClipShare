// GENERATED CODE - DO NOT MODIFY BY HAND.
// 修改 src/ 内 Lua 源文件后运行 dart run tools/generate_lua_templates.dart。

/// 内置 Lua 模板，来源：template_rule.lua。
//language=lua
const String luaTemplateRule = r'''
-- 内容
local content = params.content
-- 返回结果
return {
  -- 通知的标题(仅当类型为通知时有效)
  title = params.title,
  -- 内容/通知的内容
  content = content,
  -- 提取出的内容
  extractedContent = params.extractedContent,
  -- 标签
  tags = params.tags or {},
  -- 是否阻止同步
  isSyncDisabled = params.isSyncDisabled or false,
  -- 是否丢弃
  isDropped = false,
  -- 是否最终规则
  isFinalRule = false,
}
''';

