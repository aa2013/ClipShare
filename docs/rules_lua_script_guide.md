# ClipShare 规则 Lua 脚本指南

本文档用于说明 ClipShare 规则管理中的 Lua 脚本怎么写、能用什么、不能用什么，以及脚本的输入输出格式。

这套脚本环境不是完整 Lua 5.4 运行环境，而是经过沙盒限制后的执行环境。写脚本时请以本文档为准，不要默认所有 Lua 标准库都可用。

## 1. 适用场景

当正则规则不够用，需要更复杂的判断逻辑时，可以使用 Lua 脚本规则。

典型场景：

- 根据内容做多条件判断
- 提取内容后再二次加工
- 动态生成标签
- 根据内容类型决定是否阻止同步
- 根据通知标题、来源、标签等上下文做组合判断

## 2. 执行方式

每条脚本规则在触发时会执行一个 Lua 函数，函数接收一个参数 `params`。

你需要返回一个 Lua table 作为处理结果。

如果脚本执行失败，规则不会得到有效结果。

> 重要：`params` 是隐式可用的

虽然底层执行时固定会传入一个 `params` 参数，但在你编写脚本时，`params` 已经直接可用，不需要你自己再声明函数入口。

也就是说，你应该直接写脚本逻辑，例如：

```lua
local content = params.content or ""

return {
  title = params.title,
  content = content,
  extractedContent = params.extractedContent,
  tags = params.tags or {},
  isSyncDisabled = params.isSyncDisabled or false,
  isDropped = false,
  isFinalRule = false,
}
```

不要写成下面这样：

```lua
function main(params)
  ...
end
```

也不要写成：

```lua
return function(params)
  ...
end
```

你只需要直接编写脚本体，并在最后返回结果 table。

## 3. 输入参数 `params`

脚本固定接收一个参数：

```lua
params
```

可用字段如下：

| 字段 | 类型 | 说明 |
|---|---|---|
| `params.type` | `string` | 内容类型，可能是 `text`、`image`、`sms`、`notification` |
| `params.source` | `string?` | 内容来源，可能是本地路径，也可能是 App 包名 |
| `params.title` | `string?` | 通知标题，仅通知类型通常有值 |
| `params.content` | `string` | 原始内容 |
| `params.extractedContent` | `string?` | 已提取内容 |
| `params.tags` | `table?` | 现有标签列表 |
| `params.isSyncDisabled` | `bool?` | 当前是否已被标记为阻止同步 |

> 重要：类型后面的 `?` 表示可空

如果一个字段类型后面带了 `?`，表示这个字段可能是 `nil`，也就是“可能没有值”。

这类字段在使用前建议先做空处理，否则可能出现脚本异常。

常见处理方式有两种：

1. 显式判断是否为空

```lua
if params.title ~= nil then
  print(params.title)
end
```

2. 使用 `or` 提供默认值

```lua
local title = params.title or ""
local tags = params.tags or {}
local isSyncDisabled = params.isSyncDisabled or false
```

如果你不确定某个字段会不会为空，优先使用 `or` 给一个默认值。

## 4. 返回结果

脚本必须返回一个 table，建议始终返回完整结构：

```lua
return {
  title = params.title,
  content = params.content,
  extractedContent = params.extractedContent,
  tags = params.tags or {},
  isSyncDisabled = params.isSyncDisabled or false,
  isDropped = false,
  isFinalRule = false,
}
```

字段说明：

| 字段 | 类型 | 说明 |
|---|---|---|
| `title` | `string?` | 返回后的标题，主要用于通知类内容 |
| `content` | `string` | 返回后的内容 |
| `extractedContent` | `string?` | 返回后的提取内容 |
| `tags` | `table` | 返回后的标签列表 |
| `isSyncDisabled` | `bool` | 是否阻止同步 |
| `isDropped` | `bool` | 是否丢弃本次内容 |
| `isFinalRule` | `bool` | 是否终止后续规则 |

## 5. ClipShare 全局函数和对象

以下内容不是 Lua 标准库的一部分，而是 ClipShare 在规则脚本运行时注入到 Lua 沙盒环境中的全局函数和对象。

你可以把它们理解为 ClipShare 专门提供给规则脚本使用的辅助能力。

它们主要用于：

- 读取 ClipShare 提供的运行时信息
- 输出调试日志
- 发送通知
- 调用部分平台相关能力
- 做常见编码、解码和摘要计算

如果你要实现自定义规则逻辑，通常会同时用到 Lua 基础语法和这里提供的全局函数、对象。

### 5.1 `log` 调试日志

用于输出调试日志：

```lua
log.debug("message")
log.info("message")
log.warn("message")
log.error("message")
```

参数说明：

| 函数 | 参数 | 作用 |
|---|---|---|
| `log.debug(message)` | `message: string` | 输出调试日志 |
| `log.info(message)` | `message: string` | 输出信息日志 |
| `log.warn(message)` | `message: string` | 输出警告日志 |
| `log.error(message)` | `message: string` | 输出错误日志 |

### 5.2 `print` 快捷调试输出

这是一个快捷调试函数，等同于输出调试日志。

等同于：

```lua
log.debug(...)
```

适合快速调试。

### 5.3 `json` JSON 编解码

用于 JSON 编码和解码。

```lua
json.encode(value)
json.decode(text)
```

参数说明：

| 函数 | 参数 | 返回值 | 作用 |
|---|---|---|---|
| `json.encode(value)` | `value: table` | `string` | 将 Lua table 编码为 JSON 字符串 |
| `json.decode(text)` | `text: string` | `table` | 将 JSON 字符串解析为 Lua table |

### 5.4 `notify` 发送通知

用于从脚本中主动发送一条应用通知。

发送通知：

```lua
notify(title, content)
```

参数说明：

| 函数 | 参数 | 作用 |
|---|---|---|
| `notify(title, content)` | `title: string`, `content: string` | 发送一条应用通知 |

### 5.5 `ContentType` 内容类型

表示当前内容的类型。

可用枚举值：

```lua
ContentType.text
ContentType.image
ContentType.sms
ContentType.notification
```

值说明：

| 值                       | 说明 |
| ------------------------ | ---- |
| ContentType.text         | 文本 |
| ContentType.image        | 图片 |
| ContentType.sms          | 短信 |
| ContentType.notification | 通知 |

### 5.6 `Platform` 平台信息

表示当前脚本运行所在的平台信息。

平台信息：

```lua
Platform.isAndroid
Platform.isIOS
Platform.isWindows
Platform.isMacOS
Platform.isLinux
```

值说明：

| 值                 | 说明           |
| ------------------ | -------------- |
| Platform.isAndroid | 是否是 Android |
| Platform.isIOS     | 是否是 iOS     |
| Platform.isWindows | 是否是 Windows |
| Platform.isMacOS   | 是否是 MacOS   |
| Platform.isLinux   | 是否是 Linux   |

### 5.7 `self` 当前设备信息

表示当前设备自身的信息。

当前设备信息：

```lua
self.devId
self.devName
```

值说明:

| 值      | 说明         |
| ------- | ------------ |
| devId   | 本机设备id   |
| devName | 本机设备名称 |

### 5.8 `app` 应用版本信息

表示当前 ClipShare 应用自身的版本信息。

应用版本信息：

```lua
app.versionName
app.versionNumber
```

值说明:

| 值            | 说明                        |
| ------------- | --------------------------- |
| versionName   | ClipShare 版本名称，如1.4.3 |
| versionNumber | ClipShare版本号，如 25      |

### 5.9 `android` Android 扩展能力

表示 Android 平台下可用的扩展能力。

Android 平台专用能力：

```lua
android.notifyMediaScan(imagePath)
android.toast(content)
android.sendHistoryChangedBroadcast(type, content, from_dev_id, from_dev_name)
```

参数说明：

| 函数 | 参数 | 作用 |
|---|---|---|
| `android.notifyMediaScan(imagePath)` | `imagePath: string` | 通知 Android 媒体库扫描指定文件，通常用于图片或媒体文件 |
| `android.toast(content)` | `content: string` | 在 Android 上弹出一条 Toast 提示 |
| `android.sendHistoryChangedBroadcast(type, content, from_dev_id, from_dev_name)` | `type: ContentType`, `content: string`, `from_dev_id: string`, `from_dev_name: string` | 发送历史记录变更广播 |

### 5.10 `crypto` 摘要计算

用于计算常见摘要值。

```lua
crypto.calcMD5(content)
crypto.calcSHA1(content)
crypto.calcSHA256(content)
```

参数说明：

| 函数 | 参数 | 返回值 | 作用 |
|---|---|---|---|
| `crypto.calcMD5(content)` | `content: string` | `string` | 计算 MD5 |
| `crypto.calcSHA1(content)` | `content: string` | `string` | 计算 SHA-1 |
| `crypto.calcSHA256(content)` | `content: string` | `string` | 计算 SHA-256 |

### 5.11 `base64` Base64 编解码

用于 Base64 编码和解码。

```lua
base64.encode(content)
base64.decode(content)
```

参数说明：

| 函数 | 参数 | 返回值 | 作用 |
|---|---|---|---|
| `base64.encode(content)` | `content: string` | `string` | 将字符串编码为 Base64 |
| `base64.decode(content)` | `content: string` | `string` | 将 Base64 字符串解码 |

### 5.12 `regex` 正则表达式

> 说明：Lua 自带的是模式匹配（`string.match/find` 的 Lua Pattern），并非常见“标准正则”。
> 如果你需要标准正则能力，请使用这里注入的 `regex`。

用于进行正则匹配。

```lua
regex.match(content, pattern, caseSensitive, multiLines, dotAll)
regex.matchGroups(content, pattern, caseSensitive, multiLines, dotAll)
```

参数：

| 参数 | 类型 | 作用 |
|---|---|---|
| `content` | `string` | 要匹配的原始文本 |
| `pattern` | `string` | 正则表达式模式 |
| `caseSensitive` | `bool` | 是否区分大小写 |
| `multiLines` | `bool` | 是否启用多行模式（起止锚点按行匹配） |
| `dotAll` | `bool` | 是否让 `.` 匹配换行符 |

函数返回：

| 函数 | 返回值 | 说明 |
|---|---|---|
| `regex.match(content, pattern, caseSensitive, multiLines, dotAll)` | `table` | 返回所有完整匹配（group 0）的列表，索引从 1 开始；无匹配时返回空表 |
| `regex.matchGroups(content, pattern, caseSensitive, multiLines, dotAll)` | `table` | 返回所有匹配项的捕获组二维列表（仅 group 1..N，不包含 group 0）；无匹配时返回空表 |

返回值示例：

```lua
-- regex.match(...)
{ "abc123", "xyz456" }

-- regex.matchGroups(...)
{
  { "abc", "123" },
  { "xyz", "456" }
}
```

## 6. Lua 版本与沙盒限制

当前规则脚本运行时基于 Lua `5.4.8`。

可以默认认为常见的基础语法、流程控制、局部变量、函数、以及大部分常见标准库能力仍然可用，但这里不是完整、无约束的 Lua 环境。

重点不是“有哪些能用”，而是“哪些不能用、哪些被限制了”。

### 6.1 `os` 的限制

当前 `os` 不是完整库，只保留了安全子集：

- `os.clock`
- `os.date`
- `os.time`
- `os.difftime`

除此之外，不要假设其他 `os.*` 可用。

## 7. 不可用的函数

以下函数或相关能力不要使用，也不要让 AI 生成这些内容：

- `load`
- `loadfile`
- `loadstring`
- `dofile`
- `require`
- `module`
- `package`
- `debug`
- `coroutine`
- `getmetatable`
- `setmetatable`
- `rawget`
- `rawset`
- `rawequal`
- `collectgarbage`
- `io`
- 任何文件读写能力
- 任何执行系统命令的能力

即使 AI 给出了这些内容，也不要直接照抄。

## 8. 编写建议

- 优先保留返回结构完整
- 逻辑复杂时，先把中间结果写入局部变量
- 用 `log.debug` 或 `print` 辅助调试
- 尽量不要修改不存在于本文档中的全局变量
- 不要依赖本文未明确说明的危险能力

## 9. 示例：提取短信/文本中的验证码并打标签

下面是一个常见例子：先判断内容里是否包含“验证码”关键字，如果包含，再提取第一组 4 到 6 位的连续数字，并增加标签 `验证码`。

这里要注意，Lua 使用的是自己的模式匹配语法，不是常见正则，示例脚本里面使用注入的 `regex` 标准正则。

示例内容：

```text
【某服务】您的验证码是 123456，5 分钟内有效，请勿泄露给他人。
```

示例脚本：

```lua
-- 读取原始内容
local content = params.content or ""

-- 先判断内容中是否包含“验证码”关键字（使用 regex.match）
local keywordMatches = regex.match(content, "验证码.*", true, false, false)
local hasCodeKeyword = #keywordMatches > 0

-- 只有命中“验证码”关键字时，才提取第一组 4 到 6 位数字
local code = nil
if hasCodeKeyword then
  -- 直接正则匹配 4 到 6 位数字，取第一个结果
  local codeMatches = regex.match(content, "\\d{4,6}", true, false, false)
  code = codeMatches[1]
end

-- 复制一份标签列表，避免直接依赖 nil
local tags = params.tags or {}

-- 只有在命中关键字且成功提取到验证码时，才加标签
if hasCodeKeyword and code then
  table.insert(tags, "验证码")
end

-- 返回规则处理结果
return {
  -- 通知标题通常直接沿用原值
  title = params.title,

  -- 原始内容不变
  content = content,

  -- 将提取到的验证码作为 extractedContent 返回
  extractedContent = code,

  -- 返回新的标签列表
  tags = tags,

  -- 不阻止同步
  isSyncDisabled = params.isSyncDisabled or false,

  -- 不丢弃
  isDropped = false,

  -- 不终止后续规则
  isFinalRule = false,
}
```

## 10. 适合向 AI 提问的方式

建议你向 AI 提供这几类信息：

- 触发内容示例
- 你想提取什么
- 你希望标签怎么加
- 是否要阻止同步
- 是否要终止后续规则

例如：

```text
请帮我为 ClipShare 的规则系统写一个 Lua 脚本。
注意：我这里的脚本环境中 params 在脚本体里直接可用，不要再声明 function main(params) 或 return function(params)。
注意：字段类型如果带 ?，表示该字段可能为 nil，请做好空处理，可以先判断是否为空，或者使用 or 提供默认值。

输入内容示例是：
【某服务】您的验证码是 123456，5 分钟内有效，请勿泄露给他人。

要求：
1. 从内容中提取第一组数字作为验证码
2. 把提取结果写入 extractedContent
3. 给 tags 增加“验证码”
4. 不阻止同步
5. 不终止后续规则
6. 只返回脚本代码，并加上必要注释
```

如果你要直接复制给 AI，建议使用配套文件：

`docs/rules_lua_script_prompt.md`-