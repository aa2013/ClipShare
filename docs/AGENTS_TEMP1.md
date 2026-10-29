# ClipShare 开发规范

面向 AI 代理与协作者的开发规范。规范描述「应达到的标准」，不描述现状。

## 环境与命令

- 版本：Flutter `3.41.9`、Dart SDK `>=3.10.0`、Android 构建需 JDK 17。
- 支持平台：Android / Windows / Linux / macOS / iOS。

| 目的 | 命令 |
| --- | --- |
| 安装依赖 | `flutter pub get` |
| 运行（桌面） | `flutter run -d windows` |
| 静态分析 | `flutter analyze` |
| 分层依赖校验 | `dart run scripts/check_dependency_direction.dart` |
| 单元测试 | `flutter test <path>` |
| 代码生成（drift + Riverpod） | `dart run build_runner build --delete-conflicting-outputs` |
| 国际化生成 | `flutter gen-l10n` |
| 平台打包 | `scripts/` 下对应构建脚本 |

## 架构与分层（强制）

代码分为三层，依赖方向严格单向：`features → core → shared`。

- `features/`：功能模块（页面、模块内 provider 与 widget）。可依赖 `core`、`shared`。
- `core/`：跨 feature 的核心能力（数据库、服务、平台通道、设置、运行时）。可依赖 `shared`，不可依赖 `features`。
- `shared/`：最底层通用件（常量、枚举、扩展、工具、通用 widget、异常、模型）。不依赖 `core`、`features`。

规则：

- 反向依赖一律禁止，由 `dependency_direction` 规则报 ERROR。
- 禁止 feature 之间相互 import；需共享的能力下沉到 `core` 或 `shared`。
- 改动前先理解符号与调用链，避免误判实际调用路径。

## 代码规范

### 命名

- 类型、枚举、扩展、typedef、mixin 用 UpperCamelCase。
- 变量、方法、参数、常量（含顶层/静态 `const`、`final`）用 lowerCamelCase；Dart 不使用 SCREAMING_CAPS。
- 私有成员加 `_` 前缀；文件名、库名用 snake_case。
- 缩写按单词处理：`HttpClient`、`deviceId`；不要 `HTTPClient`、`deviceID`。
- 布尔值用 `is` / `has` / `can` / `should` 前缀表达含义。
- 禁止匈牙利/前缀式命名（`strName`、`listItems`）；避免空泛名（`data`、`info`、`temp`）。

```dart
// ✅ 应该
final deviceId = '...';
bool get isConnected => _socket != null;

// ❌ 不要
final deviceID = '...';   // 缩写未按单词处理
bool connectedFlag;       // 布尔未表达含义
```

### 导入与文件组织

- import 顺序：`dart:` → `package:` → 相对导入，组内按字母序（`directives_ordering`）。
- `lib/` 内一律使用 `package:clipshare/...` 绝对导入，禁止 `../../` 跨目录相对导入。
- 同名符号冲突用 `show` / `hide` 收敛，不保留未使用的导入。
- 避免循环依赖；`part` 仅用于代码生成（如 `part '*.g.dart';`）。
- 一个文件保持单一职责，过长时按职责拆分。

```dart
// ✅ 应该
import 'dart:async';

import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';

// ❌ 不要
import '../../../shared/utils/log.dart'; // 跨目录相对导入
```

### 类型、空安全与不可变

- 所有函数/方法显式声明返回类型（`always_declare_return_types`）。
- 局部变量能 `final` 就 `final`；可 `const` 的构造与声明一律 `const`（`prefer_const_constructors`、`prefer_const_declarations`）。
- 避免 `dynamic`；确需任意类型用 `Object?`。
- 谨慎使用 `!`：先用局部变量做空提升，或用 `?.` / `??` 处理，避免非空断言掩盖空值。
- 用 `sealed` + `switch` 表达式/模式匹配建模状态，替代长 `if-else` 链。
- 组合与扩展优于继承；仅确需复用实现与多态时才继承。

```dart
// ✅ 应该
final name = user?.name ?? 'unknown';
if (name.isEmpty) {
  return;
}

// ❌ 不要
final name = user!.name; // 滥用非空断言
```

### 函数与 API 设计

- 函数短小、单一职责；优先纯函数，便于测试。
- 可选参数与布尔参数使用命名参数，提升调用点可读性。
- 避免过多位置参数（一般不超过 3 个）与输出参数（不要通过参数回传结果）。
- getter 不得有副作用；有副作用的操作使用普通方法。
- 公开 API 显式标注类型，并提供 `///` 文档注释。

### 异步与并发

- 无需等待的 Future 必须显式 `unawaited(...)`（来自 `dart:async`）；否则必须 `await`（`unawaited_futures`）。
- 并发用 `Future.wait`，不要串行 `await` 拖慢。
- 不在 `build` 中创建 Future 或发起 IO；重计算用 `compute` / isolate。
- 异步错误必须处理；禁止 fire-and-forget 丢弃异常。
- `async` 函数内 `return await` 仅在需要 `try/catch` 捕获时使用。

```dart
// ✅ 应该
unawaited(refreshCache());
final results = await Future.wait([loadA(), loadB()]);

// ❌ 不要
refreshCache(); // 隐式忽略，异常被丢弃
```

### Flutter 与 Widget

- 大 `build` 拆分为小 Widget（优先抽取 Widget 类，而非返回 Widget 的 helper 方法，以保证 `const` 与局部重建）。
- 可 `const` 的 Widget 一律 `const`。
- `build` 保持无副作用、无 IO、无昂贵计算。
- 长列表用 `ListView.builder` 等 lazy 构造。
- `State` 在 `dispose` 中释放 controller / subscription / timer / focus node / listener。
- 禁止 `print`，统一 `logger`。
- 控制重建：`ref.watch` 取最小粒度，善用 `const`，必要时用 `RepaintBoundary`。
- 可复用的列表项等组件正确使用 `Key`。

```dart
// ✅ 应该
const SizedBox(height: 8);

@override
void dispose() {
  _sub.cancel();
  super.dispose();
}

// ❌ 不要
print('debug'); // 应使用 logger
```

### 状态管理（Riverpod）

- `build` 内用 `ref.watch`，事件回调内用 `ref.read`；不要在非 build 方法里 `ref.watch`。
- provider 单一职责、粒度最小。
- `AsyncValue` 的 loading / error / data 分支必须全部处理。
- 不在 ref 生命周期之外持有或使用 `ref`。
- 合理选择 `autoDispose`（默认）与 `keepAlive`；长生命周期服务用 `keepAlive`，并在 `ref.onDispose` 释放资源。

```dart
// ✅ 应该
final data = ref.watch(someProvider);
return switch (data) {
  AsyncData(:final value) => Text('$value'),
  AsyncError(:final error) => Text('$error'),
  _ => const LoadingDots(),
};
```

### 错误处理与日志

- 自定义异常放 `shared/exceptions/`，继承 `Error` / `Exception` 并带清晰信息。
- 仅在边界（UI / 服务入口）统一捕获；精确 `catch` 类型，避免 `catch (_) {}` 吞异常。
- 捕获后必须处理或至少 `logger.error` 记录。
- 资源释放放 `finally`。
- 日志统一 `logger.info/debug/warn/error(tag, ...)`，`tag` 用 `static const` 常量。

```dart
// ✅ 应该
try {
  await sync();
} catch (err, stack) {
  logger.error(tag, 'sync failed: $err', stack);
}
```

### 常量与集合

- 业务字面量（数字、字符串、编码、状态值）一律提取命名常量；禁止重复的 Magic Number / String。
- 用枚举建模状态与有限选项，替代裸 int / String 或布尔组合。
- 集合优先字面量 + spread + collection-`if` / `for` 构造。
- 查找用 `firstWhere(orElse: ...)` 或 `firstOrNull`，不要手写索引循环。
- 优先不可变集合，避免共享可变状态。

### 注释与文档

- 新增或修改的代码必须添加适当注释，一行中文一行英文。
- 公开 API 用 `///` 文档注释；私有辅助方法说明用途与关键参数。
- 注释解释「为什么」、不变量、业务规则与边界条件，不解释「是什么」。
- 禁止变更历史式注释（"本次改为…""重构为…""原先是…"）与废话注释。
- 能通过更好的命名、结构或文案消除歧义时，优先改代码而非加注释。

```dart
// ✅ 应该
/// 同一内容在短时间内重复出现时去重，避免剪贴板抖动产生多条记录。
/// Deduplicates repeated content within a short window to avoid clipboard jitter.

// ❌ 不要
// 把 hash 加入集合
_hashSet.add(hash);
```

### 格式与排版

- 禁止执行 `dart format`（会对长代码产生难读的排版）。
- 链式调用逐行换行并对齐。
- 每个 `if` 块使用独立大括号换行，不与条件同行。
- 过长调用提前抽取为局部变量，避免一行内超长调用链。
- 尾随逗号（`require_trailing_commas`）、字符串单引号（`prefer_single_quotes`）。

```dart
// ✅ 应该
final result = originList.where((item) => item.ok)
                  .map((item) => item.value)
                  .toList();

if (success) {
  return;
}

// ❌ 不要
if (success) return;
final value = widget.someFunction().requireValue.field;
```

## 常见陷阱与注意事项

- 不要手改生成文件：`*.g.dart`、`lib/l10n/gen/` 等由代码生成，改动会在下次生成时丢失。
- 改动 `@Riverpod` 注解、drift 表/DAO 或 `.arb` 后必须重跑代码生成，否则编译或行为不一致。
- `flutter analyze` 在大项目下可能丢弃自定义插件诊断；分层依赖校验以 `dart run scripts/check_dependency_direction.dart` 为准。
- 异步：不等待的 Future 必须 `unawaited(...)`，否则 `await`；禁止隐式忽略。
- 资源释放：`StreamSubscription`、`Timer`、监听器必须在 `ref.onDispose` 或 `State.dispose` 中取消/释放。
- drift 迁移必须幂等：使用 `hasColumn` / `addColumnIfNotExists` / `IF NOT EXISTS`，兼容从任意旧版本直接升级；修改表结构需递增 `dbSchemaVersion`。
- 新增需 JSON 序列化的枚举时，在 `AppDriftValueSerializer` 登记序列化方式。
- UI：禁止 `DefaultTextStyle` / `AnimatedDefaultTextStyle` 直接传入原始 `TextStyle`（会丢失主题字体），改用 `DefaultTextStyle.merge` 或从 `Theme.textTheme` 派生（`default_text_style_font` 规则报 ERROR）。
- 文案不得硬编码：统一走 `TranslationKey.xxx.tr`，新增键需同步 `l10n/arb`（`app_en.arb`、`app_zh.arb`）。
- 路由不得使用魔法字符串：使用 `AppRoutes` 枚举 + 命名跳转。
- 平台相关代码归 `core/platform/`；`android/`、`windows/` 等原生工程仅在需要原生混合开发时改动。

## 开发原则

- 理解优先：修改前先理解现有实现、调用链与影响范围，不盲目大范围重构。
- 优先复用：复用已有接口、组件、扩展与工具，不重复造轮子。
- 配套完整：结合上下文分析影响范围，同步修改调用方、常量、测试、文档等配套内容。

## 测试规范

### 原则

- 测试以事实为准，如实反映行为。
- 最小必要：优先运行与改动范围相关的测试（`flutter test <path>`），不随意跑全量。
- 可测性优先：依赖应可注入，避免测试与真实网络/文件/时钟强耦合。

### 命名与结构

- 测试名描述「对象 - 场景 - 期望」，或 `should ... when ...`。
- 遵循 AAA（Arrange-Act-Assert）/ Given-When-Then。
- 一个测试聚焦一个行为，断言明确。

```dart
// ✅ 应该
test('history - 空列表 - 返回空结果', () {
  // Arrange
  final service = HistoryService(items: []);
  // Act
  final result = service.filter('');
  // Assert
  expect(result, isEmpty);
});
```

### 覆盖范围

- 覆盖正常路径、边界条件与异常/失败路径。
- 除必须由用户操作观测的功能外，每个功能都应有明确测试覆盖。

### 隔离与可测性

- 不依赖真实网络/文件/时间，使用 fake / mock 或注入替身。
- 若当前结构无法注入测试环境，明确说明原因并推动调整结构，不得为测试而绕过。

### 命令

- `flutter test <path>`

### 底线

- 不得跳过必要验证。
- 不得修改测试以掩盖真实缺陷。
- 不得为了通过测试在生产代码中写入测试白名单或专用测试分支。
- 不得为减少麻烦而忽略条件、降低覆盖。

## 完成定义（DoD）

改动完成前必须完成：

- `flutter analyze` 无新增问题。
- 涉及分层/导入改动时，运行 `dart run scripts/check_dependency_direction.dart` 无违规。
- 运行与改动相关的测试并通过。
- 若改动 `@Riverpod` 注解、drift 表/DAO 或 `.arb`，已重跑代码生成且结果纳入改动。
