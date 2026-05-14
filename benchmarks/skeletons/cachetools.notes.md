# Skeleton notes — cachetools

> 给 Phase 1.E 评审 + Phase 1.H 决策报告参考。

## 项目简介

`cachetools` v5.5 是一个纯 Python 的 memoizing 库，提供 6 个 cache eviction 策略（FIFO/LFU/LRU/MRU/RR/TTL）+ 4 个 key 函数（hashkey/methodkey 及 typed 变体）。它**没有 pipeline 结构** —— 是个"函数库"。

## Commit0 stripped 函数清单

| 文件 | 顶层 stripped 函数 | 签名 |
|---|---|---|
| `keys.py` | hashkey | `*args, **kwargs` |
| `keys.py` | methodkey | `self, *args, **kwargs` |
| `keys.py` | typedkey | `*args, **kwargs` |
| `keys.py` | typedmethodkey | `self, *args, **kwargs` |
| `func.py` | fifo_cache | `maxsize=128, typed=False` |
| `func.py` | lfu_cache | `maxsize=128, typed=False` |
| `func.py` | lru_cache | `maxsize=128, typed=False` |
| `func.py` | mru_cache | `maxsize=128, typed=False` |
| `func.py` | rr_cache | `maxsize=128, choice=random.choice, typed=False` |
| `func.py` | ttl_cache | `maxsize=128, ttl=600, timer=time.monotonic, typed=False` |

共 10 个顶层函数（`__init__.py` 里的 `cache_clear` 是 nested in `cached` decorator，不算）。

## 分解决策

**为什么没有真正的 pipeline**：cachetools 是个函数库（library），不是数据处理流水线。每个 cache 装饰器和 key 函数都是独立的 public API。

**用了什么 agent-lang 结构**：
1. 1 个 top-level `flow cachetools_lib` — purely organizational
2. 2 个 group `flow`s (`keys_group` + `caches_group`) — 给 LLM 一个"先填一类再填另一类"的提示
3. 10 个 `code` 节点 — 一一对应 stripped 函数

`steps:` 列在 group flow 里不参与 runtime（实证 pipeline B 不调 flow_root；pytest 直接测每个函数）。但 group 结构是给 **LLM implementer 的 prompt 提示** —— 让它认识到 keys 一类、caches 一类，每类内部有共享 pattern。

**为什么不用 agent 节点**：cachetools 是确定性算法（LRU eviction 之类），没有"输入输出形状多变"特性。code 节点足以。

**为什么不用 set 节点**：没有跨多个 agent 共享的工具集。

## 给 LLM implementer 的关键提示

| 函数 | LLM 需要知道的关键信息 |
|---|---|
| `hashkey` | 返回 hashable tuple；不 sort kwargs，保留 insertion order（实际实现是 args + tuple of (k, v) tuples） |
| `methodkey` | 第一个 self 参数被丢弃，剩下走 hashkey 逻辑 |
| `typedkey` | 在 hashkey 基础上 append `(type(a) for a in args)` —— 区分 `1` vs `1.0` |
| `typedmethodkey` | typedkey 的 method 变体 |
| `*_cache` 装饰器 | 都遵循 `_cache(<Cache>(maxsize), maxsize, typed)` 通用 pattern；维护 `cache_parameters` 元数据 |
| `rr_cache` | 多一个 `choice=random.choice` 参数传给 RRCache |
| `ttl_cache` | 多 `ttl` 和 `timer` 参数；用 `_UnboundTTLCache` 当 maxsize=None |

这些细节在 `func.py` 的 `_cache` helper（**没被 stripped**）已经暴露了 pattern —— LLM 只需 mimic 这个 helper 的用法。

## 风险

- LLM 可能误用 `sorted(kwargs.items())` 替代 insertion-preserve order — 这在 hashkey doctest 里会失败
- `cache_parameters` 元数据容易遗漏（functools.lru_cache 兼容性要求）
- `rr_cache` 的 `choice` 参数容易和 `choice=random.choice` 默认值搞混

## 一致性约束

骨架名 = Python 函数名（一一对应）。Phase 1.G runner 用 function name 在原 repo 中查找并替换 stripped body。
