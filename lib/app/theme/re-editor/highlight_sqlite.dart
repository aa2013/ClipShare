// GENERATED STYLE (MODIFIED) - SAFE TO EDIT

import 'package:re_highlight/re_highlight.dart';

final langSqliteHighlight = Mode(
  name: "SQLite",
  caseInsensitive: true,
  // =========================
  // 🔁 可复用规则
  // =========================
  refs: {
    // ---------- 单行注释 ----------
    '~comment_line': Mode(
      scope: 'comment',
      begin: r"--",
      end: r"$",
      contains: [
        Mode(
          scope: 'doctag',
          begin: r"[ ]*(?=(TODO|FIXME|NOTE|BUG):)",
          end: r"(TODO|FIXME|NOTE|BUG):",
          excludeBegin: true,
        ),
      ],
    ),

    // ---------- 多行注释 ----------
    '~comment_block': Mode(
      scope: 'comment',
      begin: r"/\*",
      end: r"\*/",
      contains: [Mode(self: true)],
    ),
  },

  // =========================
  // 🔤 关键字（SQLite）
  // =========================
  keywords: {
    r"$pattern": r"[A-Za-z_]\w*",

    "literal": "true false null",

    "keyword": """
      SELECT INSERT UPDATE DELETE FROM WHERE GROUP BY ORDER HAVING LIMIT OFFSET
      AS DISTINCT ALL
      JOIN INNER LEFT RIGHT FULL OUTER CROSS
      ON USING
      UNION INTERSECT EXCEPT
      CREATE ALTER DROP TABLE INDEX VIEW TRIGGER
      PRIMARY KEY FOREIGN REFERENCES UNIQUE CHECK DEFAULT
      VALUES INTO
      AND OR NOT IN IS LIKE GLOB BETWEEN EXISTS
      CASE WHEN THEN ELSE END
      CAST COLLATE
      BEGIN COMMIT ROLLBACK SAVEPOINT RELEASE
      PRAGMA VACUUM ANALYZE ATTACH DETACH
      REINDEX
    """,

    // SQLite 内置函数（常见）
    "built_in": """
      COUNT SUM AVG MIN MAX
      ABS LENGTH LOWER UPPER ROUND RANDOM
      IFNULL COALESCE NULLIF
      DATE TIME DATETIME JULIANDAY STRFTIME
      LAST_INSERT_ROWID CHANGES TOTAL_CHANGES
    """
  },

  // =========================
  // 🧠 语法解析规则
  // =========================
  contains: [

    // ===== 注释 =====
    Mode(ref: '~comment_line'),
    Mode(ref: '~comment_block'),

    // ===== 字符串 =====
    Mode(
      className: 'string',
      begin: r"'",
      end: r"'",
      contains: [
        Mode(begin: r"''"), // 转义 ''
      ],
    ),

    // ===== 数字 =====
    C_NUMBER_MODE,

    // ===== 函数调用（COUNT(...) 等）=====
    Mode(
      className: 'title.function.invoke',
      begin: r"\b[A-Za-z_]\w*(?=\()",
    ),

    // ===== 表名.字段名 =====
    Mode(
      className: 'attr',
      begin: r"\.[A-Za-z_]\w*",
    ),

    // ===== 操作符 =====
    Mode(
      className: 'operator',
      begin: r"=|<>|!=|<|>|<=|>=",
    ),
  ],
);