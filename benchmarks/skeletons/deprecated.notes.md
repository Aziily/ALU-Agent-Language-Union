# Skeleton notes — deprecated

## 项目简介

`deprecated` 是一个提供 `@deprecated` 装饰器的小库，让用户标记函数 / 类 / 方法为 deprecated 并在调用时发 `DeprecationWarning`。还提供 `versionadded` / `versionchanged` 等 Sphinx 风格的 docstring 注入。

## Commit0 stripped 清单

| 文件 | 函数 | 类别 |
|---|---|---|
| `classic.py` | `deprecated` (top) | classic-style decorator |
| `classic.py` | `ClassicAdapter.get_deprecated_msg` (method) | 构造 warning message |
| `sphinx.py` | `versionadded` (top) | Sphinx docstring inject |
| `sphinx.py` | `versionchanged` (top) | Sphinx docstring inject |
| `sphinx.py` | `deprecated` (top) | Sphinx-style decorator (与 classic.deprecated 同名) |
| `sphinx.py` | `SphinxAdapter.get_deprecated_msg` (method) | 构造 warning message (无 Sphinx markup) |

**命名冲突**：`classic.py::deprecated` 和 `sphinx.py::deprecated` 同名。骨架用文件前缀消歧：`classic_deprecated` / `sphinx_deprecated`。Phase 1.G runner 按 (filename, function_name) 注入。

## 给 LLM implementer 的关键提示

| 节点 | 实现要点 |
|---|---|
| `classic_deprecated` | 主要 logic：`@wrapt.decorator` wrap + warn at call time；支持 `@deprecated`、`@deprecated()`、`@deprecated("reason")`、`@deprecated(version="x")` 多种调用形态 |
| `ClassicAdapter__get_deprecated_msg` | 拼接 "Call to deprecated function {name}." + 可选 reason / version |
| `sphinx_versionadded` / `versionchanged` | 修改 wrapped.\_\_doc\_\_ 加 ".. versionadded:: <ver>" 块；line_length 控制 wrap |
| `sphinx_deprecated` | 同上 + 也要在 call 时 warn（继承 ClassicAdapter） |
| `SphinxAdapter__get_deprecated_msg` | 类似 ClassicAdapter 但 strip Sphinx 交叉引用语法（`:class:` 等） |

## 风险

- 命名冲突的 inject 必须按文件区分 — 简单 name-only 替换会替换错
- wrapt 库的 `@decorator` pattern 是新手陷阱（与 @functools.wraps 不同）
- Sphinx 风格 directive 的精确换行 / indent 容易写错
