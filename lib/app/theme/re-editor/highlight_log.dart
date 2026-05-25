import 'package:re_highlight/re_highlight.dart';

// 日志高亮
final langLogHighlight = Mode(
  name: "Log",

  contains: [

    // =========================
    // 🔥 level（必须在行首或 | 后）
    // =========================
    Mode(
      className: 'log_debug',
      begin: r"(?<=^|\|\s)\[debug\]",
    ),
    Mode(
      className: 'log_info',
      begin: r"(?<=^|\|\s)\[info\]",
    ),
    Mode(
      className: 'log_warn',
      begin: r"(?<=^|\|\s)\[warn\]",
    ),
    Mode(
      className: 'log_error',
      begin: r"(?<=^|\|\s)\[error\]",
    ),

    // =========================
    // 🕒 时间（必须在 | 后）
    // =========================
    Mode(
      className: 'log_time',
      begin: r"(?<=\|\s)\d{2}:\d{2}:\d{2}",
    ),

    // =========================
    // 📦 tag（必须在时间后）
    // =========================
    Mode(
      className: 'log_tag',
      begin: r"(?<=\d{2}:\d{2}:\d{2} \| )\[[A-Za-z_]\w*\]",
      relevance: 0,
    ),

    // =========================
    // |
    // =========================
    Mode(
      className: 'log_sep',
      begin: r"\|",
    ),
  ],
);