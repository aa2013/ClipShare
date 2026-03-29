import 'package:re_highlight/re_highlight.dart';

final _customModules = ['log'];
final _customGlobals = ['params'];
final langLuaHighlight = Mode(
  name: "Lua",

  // =========================
  // 🔁 可复用规则（注释等）
  // =========================
  refs: {
    // ---------- 单行注释 ----------
    '~comment_line': Mode(
      scope: 'comment',
      begin: r"--(?!\[=*?\[)", // -- 开头但不是多行注释
      end: r"$",
      contains: [
        // TODO / FIXME 高亮
        Mode(
          scope: 'doctag',
          begin: r"[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)",
          end: r"(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):",
          excludeBegin: true,
        ),
      ],
    ),

    // ---------- 多行注释 ----------
    '~comment_block': Mode(
      scope: 'comment',
      begin: r"--\[*=*?\[",
      end: r"\]=*?\]",
      contains: [
        Mode(self: true), // 支持嵌套
      ],
    ),
  },

  // =========================
  // 🔤 关键字（Lua 5.4）
  // =========================
  keywords: {
    r"$pattern": r"[a-zA-Z_]\w*",

    // 字面量
    "literal": "true false nil",

    // Lua 5.4 关键字
    "keyword": "and break do else elseif end for goto if in local not or repeat return then until while function",

    // 内置函数 + 标准库（增强版）
    "built_in": """
      assert collectgarbage dofile error getmetatable ipairs load loadfile next pairs pcall print rawequal rawget rawset require select setmetatable tonumber tostring type warn xpcall

      coroutine create resume running status wrap yield

      string byte char dump find format gmatch gsub len lower match pack packsize rep reverse sub upper unpack

      table concat insert move pack remove sort unpack

      math abs acos asin atan ceil cos deg exp floor fmod huge log max min modf pi rad random randomseed sin sqrt tan tointeger type ult

      io close flush input lines open output popen read tmpfile type write

      os clock date difftime execute exit getenv remove rename setlocale time tmpname

      utf8 char charpattern codepoint codes len offset
    """,
  },

  // =========================
  // 🧠 语法解析规则
  // =========================
  contains: [
    // ===== 注释 =====
    Mode(ref: '~comment_line'),
    Mode(ref: '~comment_block'),

    // ===== 函数定义 =====
    Mode(
      className: 'function',
      beginKeywords: "function",
      end: r"\)",

      contains: [
        // 函数名（支持 obj.method / obj:method）
        Mode(
          scope: 'title',
          begin: r"([_a-zA-Z]\w*\.)*([_a-zA-Z]\w*:)?[_a-zA-Z]\w*",
        ),

        // 参数
        Mode(
          className: 'params',
          begin: r"\(",
          endsWithParent: true,
          contains: [
            Mode(ref: '~comment_line'),
            Mode(ref: '~comment_block'),
          ],
        ),
      ],
    ),

    // ===== 冒号调用（Lua 特有✨）=====
    Mode(
      className: 'title.function.method',
      begin: r"(?<=[.:])[a-zA-Z_]\w*(?=\()",
    ),

    // ===== 函数调用（新增✨）=====
    Mode(
      className: 'title.function.invoke',
      begin: r"\b[a-zA-Z_]\w*(?=\()",
    ),

    // ===== namespace =====
    Mode(
      className: 'variable.namespace',
      begin: r"\b(" + _customModules.join('|') + r")(?=[.:])",
    ),

    // ===== 全局变量 =====
    Mode(
      className: 'variable.global',
      begin: r"\b(" + _customGlobals.join('|') + r")",
      relevance: 0, // 不影响关键字高亮
    ),

    // ===== table.key（新增✨）=====
    Mode(
      className: 'attr',
      begin: r"(?<=\.)[a-zA-Z_]\w*",
    ),

    // ===== 数字 =====
    C_NUMBER_MODE,

    // ===== 字符串 =====
    APOS_STRING_MODE, // 'abc'
    QUOTE_STRING_MODE, // "abc"
    // ===== Lua 长字符串 =====
    Mode(
      className: 'string',
      begin: r"\[=*?\[",
      end: r"\]=*?\]",
      contains: [Mode(self: true)],
    ),
  ],
);
