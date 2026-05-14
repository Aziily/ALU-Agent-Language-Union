# Skeleton notes — voluptuous

## 项目简介

`voluptuous` 是 Python 的 schema validation 库。核心抽象 = "validator" — 一个可调用对象，接受候选值并返回经过校验/转换的值（或抛 Invalid）。可组合性强：dict / list / typed value / 自定义都能作 schema。

## Commit0 stripped 函数清单

共 **26 个顶层 stripped 函数**，跨 4 个模块：

| 文件 | 数量 | 函数 |
|---|---|---|
| `schema_builder.py` | 9 | Extra, _compile_scalar, _compile_itemsort, _iterate_mapping_candidates, _iterate_object, message, _args_to_dict, _merge_args_with_kwargs, validate |
| `validators.py` | 11 | truth, IsTrue, IsFalse, Boolean, Email, FqdnUrl, Url, IsFile, IsDir, PathExists, Maybe |
| `util.py` | 5 | Lower, Upper, Capitalize, Title, Strip |
| `humanize.py` | 1 | humanize_error |

## 分解决策

4 个 group flow 反映模块结构：

- `schema_builder_group` — schema 编译核心；最复杂，依赖最深
- `validators_group` — 用户常调的内置 validator
- `util_group` — 简单字符串变换
- `humanize_group` — error formatting

按 group 排序的暗示给 LLM："先填 util 类（最简单 + 没依赖），再填 validators（用 util 的 String），再 schema_builder（最复杂），最后 humanize（孤立）"。

不过实际上 LLM 不一定按顺序，可以乱序。

## PascalCase 节点名

voluptuous 大量使用 PascalCase 函数名（`Email` 既是函数也是 conceptually 一个 validator class）。这触发了 spec § 4.3 升级（在 commit `f1b08ed` 完成）—— 节点名现在接受 `[A-Za-z_][A-Za-z0-9_]*`，向后兼容。

## 给 LLM implementer 的关键提示

| 类别 | 实现思路 |
|---|---|
| String util (`Lower` 等) | 简单：`str.lower()` / `str.upper()` 等；遇到非 str 类型应抛 Invalid 或 TypeError |
| Truthy validators (`IsTrue` / `IsFalse`) | `bool(v) == True` / `== False`；返回 v 不变 |
| `Boolean(v)` | 字符串映射表：truthy = `{y,yes,true,t,1,on,enabled}`，falsy = 类似；大小写不敏感；bool/int 直接转 |
| `Email` / `Url` / `FqdnUrl` | regex 验证；fqdn 多一个"域有 dot 且不是 IP" 检查 |
| Path validators | `os.path.exists / isdir / isfile`；返回 v 原值 |
| `Maybe(validator)` | wrapper：`v is None or validator(v)` |
| `truth(f)` | decorator：把 `f(v) -> bool` 转 validator（false 时抛 Invalid） |
| `message(default, cls)` | decorator factory：给 validator 加默认 error message |
| `validate(*a, **kw)` | decorator：用 Schema 包裹 函数参数；既支持 `@validate(schema)` 也支持 `@validate(x=...)` |
| `_compile_scalar(schema)` | scalar 的 validator：if schema is type → isinstance；else == |
| `_compile_itemsort()` | 返回 sort key 函数，让具体 key 排在 Marker key（如 Extra）前面 |
| `_iterate_mapping_candidates(schema)` | 用 `_compile_itemsort` 排序 schema dict 的 items |
| `_iterate_object(obj)` | yield (name, value) 对；处理 `__slots__` 和 `__dict__` |
| `_args_to_dict(func, args)` | `inspect.signature(func).parameters` zip with args |
| `_merge_args_with_kwargs(args_dict, kwargs_dict)` | dict union, kwargs 覆盖 args |
| `humanize_error` | 格式化 Invalid 异常的 path + value + message |

## 风险

- `Boolean` 接受字符串列表不全可能让 doctest 失败（spec/docstring 给定列表必须严格 match）
- `_iterate_mapping_candidates` 的排序细节（Marker 类相对优先级）容易写错
- `Maybe` 不应该把 None 当作 "validate failed and substitute None"，而是 short-circuit pass
- `humanize_error` 的递归 sub-error 处理是出错点

## 一致性约束

骨架节点名 = Python 函数名（PascalCase 函数 → PascalCase 节点名）。Phase 1.G runner 用 function name match 注入。
