# Skeleton notes — wcwidth

## 项目简介

`wcwidth` 是 Unicode 字符显示宽度库。给定一个 char (or string)，返回它在终端里占几格（0 / 1 / 2 / -1）。核心逻辑是查 Unicode 数据表 + 二分搜索。

## Commit0 stripped 函数清单

| 文件 | 顶层函数 | 用途 |
|---|---|---|
| `wcwidth.py` | `_bisearch` (private) | 二分搜索 (start, stop) 区间表 |
| `wcwidth.py` | `wcwidth` (public) | 单字符显示宽度 |
| `wcwidth.py` | `wcswidth` (public) | 字符串显示宽度（带可选长度限制） |
| `wcwidth.py` | `_wcversion_value` (private) | "6.2.0" → (6, 2, 0) |
| `wcwidth.py` | `_wcmatch_version` (private) | Unicode 版本号 fallback |
| `unicode_versions.py` | `list_versions` | 枚举支持的 Unicode 版本 |

共 6 个顶层函数。其中 `_bisearch` 被 wcwidth/wcswidth 调用（依赖关系）；`_wcversion_value` 被 `_wcmatch_version` 调用。

## 分解决策

3 个 group flow 反映函数职责分类：

- `helpers` — 内部工具（`_bisearch`），被 public API 复用
- `public_api` — 用户直接调用（wcwidth / wcswidth）
- `version_api` — Unicode 版本管理

为什么分组：给 LLM "这是一个 binary-search-table 库" 的 mental model。`_bisearch` 是核心 helper，wcwidth/wcswidth 调它。LLM 看到 helpers 在前，会先填好 helper 再填 public。

## 给 LLM implementer 的关键提示

| 函数 | 实现要点 |
|---|---|
| `_bisearch` | 标准二分；table 是 `[(lo1, hi1), (lo2, hi2), ...]`，sorted by lo；ucs >= lo and ucs <= hi 算命中 |
| `wcwidth` | 控制字符返回 -1；查 `ZERO_WIDTH[ver]` 表 → 0；查 `WIDE_EASTASIAN[ver]` 表 → 2；其他返回 1 |
| `wcswidth` | 遍历字符串前 n 个，sum wcwidth；遇到 -1 立即返回 -1 |
| `list_versions` | 直接读 `_UNICODE_VERSIONS` module 常量并 sort |
| `_wcversion_value` | `tuple(int(x) for x in ver_string.split("."))` |
| `_wcmatch_version` | "auto"/"latest" → 最新；exact match → 用；否则找 ≥ given 的最早 supported（fuzzy fallback） |

## 风险

- LLM 可能写 `int(c)` 而不是 `ord(c)` —— Python 里取 code point 用 ord
- `wcswidth` 的 `n=None` semantics: None = "整个字符串"，不是 "0 chars"
- `_wcmatch_version` 的 fallback 顺序：spec 说 "next-greatest" — 这是 fuzzy match，容易写错

## 一致性约束

骨架名 = Python 函数名（一一对应）。
