# 内置 Lua 模板

编辑 [src](src/) 子目录的 `.lua` 文件；当前目录的 `.dart` 文件由生成器维护，供业务代码同步读取。所有 Lua 源码和编辑器声明都位于 `src/`，不与 Dart 产物平铺。

```sh
dart run tools/generate_lua_templates.dart
dart run tools/generate_lua_templates.dart --check
```

生成器不依赖第三方包。产物提交到 Git，构建应用无需额外读取 Lua assets。修改源文件后须运行生成命令；`--check` 和生成器测试会检测未同步的产物。

## 模板约定

- `-- @include luaSandboxEnv` 和 `-- @include luaCustomModules` 在原位置展开公共片段；不要在普通注释或字符串中使用这些指令文本。
- 非字符串参数使用合法 Lua 标识符 `__TPL_参数名__`，生成时还原成 `{{参数名}}`。这些标识符属于生成器保留标记，不用于业务变量或普通文本。
- 字符串和长字符串内继续使用 `{{参数名}}`。Dart 执行前仍按原有方式替换参数。
- 包装器里的 `scope`、`log` 是包含片段声明的局部变量。编辑器不会执行包含指令，类型声明仅用于辅助分析。

## 编辑器支持

使用支持 Lua 的插件打开 `.lua` 源文件可获得语法高亮和检查；LuaLS / EmmyLua 可读取 `editor_types.lua` 中的声明。声明文件不参与生成或运行。跨文件包含关系不会被 Lua 语言服务器自动展开，因此补全不等于运行时验证。

模板拆分不改变现有参数转义和沙箱执行逻辑。完整运行验证仍需要应用的 Lua 运行环境。
