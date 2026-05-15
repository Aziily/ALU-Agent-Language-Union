# Authoring agent-lang — 实用编写指南

> 给开发者和 LLM 的 **how-to** 指南。spec 答的是 "what is"；本文答 "how to write"。
> 配套：`docs/spec/agent-lang-spec.md` (规范) · `examples/daily_news.al` (实战示例)。

## 1. TL;DR

`agent-lang` 是一个 Python 上的薄编排层。把工程分解成 4 种节点，写成 `.al` 文件，经 codegen 自动转为合法 Python，由标准工具链运行：

- **`flow`** = 复合容器（含 `steps:`）。串、并、循环、分支。**自身不执行**。
- **`code`** = 字面 Python 函数。叶子节点。
- **`agent`** = LLM/agent 调用（含 `prompt:` + 可选 `fallback:`）。
- **`set`** = 一组**可复用工具/技能/扩展/记忆**，被 agent 通过 `use:` 引用。**自身不执行**。

> **2 空格缩进 / 禁用 Tab / LF 行尾 / 节点名 `[A-Za-z_][A-Za-z0-9_]*`**。Tab 会让 parser 直接报错。
> 节点名推荐 snake_case，但 PascalCase 也被接受（用于桥接现有 Python 项目，如 voluptuous 的 `Email` / `Boolean` 等 validator 命名）。

## 2. 节点选择决策树

```
此步骤是否有稳定 I/O 契约 + 清晰逻辑？
  yes  →  code      # 例：parse JSON, dedupe by URL, format date
  no   →  能拆成 ≥ 2 子步骤吗？
            yes →  flow    # 例：fetch → clean → summarize → deliver
            no  →  agent   # 例：从 HTML 提取标题作者

此节点是否"被多个 agent 引用、本身不执行的资源/能力"？
  yes  →  set
```

**实用经验**：

- 简单包 / 工具库（大部分 Commit0 项目）→ **几乎都是 code 节点**。flow 用来串起 public API。
- agent 节点适合输入输出形状多变、规则难穷尽、能容忍失败的场景。
- set **不要为了用而用** —— 真有 ≥ 2 个 agent 共享同一组工具时才引入。

## 3. 字段速查表

| 字段 | 适用节点 | 类型 | 用法 |
|---|---|---|---|
| `intent:` | 全部 | inline | **必填**。一行 plain-English 描述这个节点干啥 |
| `input:` | flow / code / agent | inline 或嵌套 | 输入形状（自由 English 或类型） |
| `output:` | flow / code / agent | inline 或嵌套 | 输出形状 |
| `body:` | code, **preamble** | block scalar `|` | 字面 Python 源 |
| `source:` | **preamble** | inline | 该 preamble 对应的源 `.py` 文件相对路径（hint） |
| `imports:` | **preamble** | block scalar `|` | 该 module 的所有 `import` / `from ... import ...` 行（H4 引入，单独 hoist 出来便于 LLM 把"导入"作为独立单元看待） |
| `constants:` | **preamble** | block scalar `|` | 该 module 的简单名字模块级赋值（`__all__ = (...)`, `PI = 3.14`, `X: int = 1`）；H5 引入，进一步从 `body:` 抽离 |
| `steps:` | flow | 列表 | flow 的有序子步骤；项可为 ref / parallel / each / if |
| `prompt:` | agent | block scalar `|` | 给 LLM 的自然语言指令 |
| `fallback:` | agent | bare name | agent 失败时调用的另一节点（**必须是 code/agent 节点名，不能是工具名**） |
| `use:` | agent | bare name 或列表 | 引用一或多个 set |
| `tools:` | set | 列表 | 工具引用 |
| `skills:` | set | 列表 | 可复用 skill 引用 |
| `extensions:` | set | 列表 | MCP 服务器引用，约定 `mcp_<name>` 前缀 |
| `memory:` | set | block scalar `|` | YAML 格式的结构化记忆 |
| `schedule:` | flow | inline | 顶层 flow 的调度声明（v1 仅记录） |

### `preamble` —— module-level Python 上下文（Phase 1.AL.2 新增）

`preamble` 是第 5 个 declarator，专门承载**函数体以外**的 Python：imports / class
定义 / module-level constants / type aliases / module docstring / `__all__`。
之前 agent-lang 只能表达"函数体级别"的代码 → LLM 看不到这些上下文 → 在 cachetools
里写 `hashkey` 时不知道 `_HashedTuple` 和 `_kwmark` 已经存在，硬是凭空发明 → 测试
fail。`preamble` 就是修这个的。

**关键语义**：preamble 块**只是给 LLM 看的上下文**，benchmark inject 阶段会 skip
它（因为 module-level 的代码已经在原始 stripped repo 里了）。所以 preamble 不会
"覆盖"或"注入"任何代码；它纯粹是 prompt-context。

**典型用法**（cachetools/keys.py）：
```al
preamble cachetools_keys:
  source: cachetools/keys.py
  imports: |
    import collections
    from . import keys
  constants: |
    __all__ = ('hashkey', 'methodkey', 'typedkey', 'typedmethodkey')
    _kwmark = (_HashedTuple,)
  body: |
    """Key functions for memoizing decorators."""
    class _HashedTuple(tuple):
        """Cached-hash tuple — hash() called at most once per element."""
        __hashvalue = None
        def __hash__(self, hash=tuple.__hash__):
            hashvalue = self.__hashvalue
            if hashvalue is None:
                self.__hashvalue = hashvalue = hash(self)
            return hashvalue


flow cachetools_keys_group:
  steps:
    - hashkey
    - typedkey

code hashkey:
  body: |
    def hashkey(*args, **kwargs):
        """Return a cache key for the specified hashable arguments."""
        if kwargs:
            return _HashedTuple(args + sum(sorted(kwargs.items()), _kwmark))
        return _HashedTuple(args)
```

LLM 写 `hashkey` body 时能直接引用 `_HashedTuple` / `_kwmark`，因为它们在
preamble 里可见。同样，`imports:` 块里的 `collections` 等也是 module-level 已经在 scope 内的——
LLM 写 code body 时无需在 body 里再重复 `import collections`。

> **`imports:` vs `body:` 在 preamble 里如何分**：所有以 `import X` 或
> `from X import Y` 开头的语句 → `imports:`；其余 module-level Python
> （class 定义、常量、`__all__`、module docstring、类型别名）→ `body:`。
> 即使是 `try: from X import Y\nexcept ImportError: from Z import Y` 这种
> "条件性导入"块，只要里面**全是** import 语句，也归入 `imports:`。
> 这条规则由 `benchmarks/skeletons/_autogen.py` 自动执行。

**何时该写 preamble**：源文件除了"被 strip 成 `pass` 的函数"以外还含有
以下任何一项时，就该写：
- 任何 `import` / `from ... import ...`
- 任何 module-level `class Foo:`
- 任何 module-level 常量 / 配置 / 类型别名（`PREVENT_EXTRA = 0`, `Schemable = Union[...]`）
- module docstring 或 `__all__`

**何时不需要 preamble**：源文件几乎全是函数，没有 module-level scaffolding。
此时所有 imports 在每个函数 body 内部局部 `import`，跳过 preamble 也行。

### 三种字段值形态

```al
# (a) inline value（一行）
intent: fetch news every morning

# (b) 嵌套 block（多 key:value）
output:
  title: str
  body: str
  published_at: datetime

# (c) block scalar（多行文本；用 `|` 标记）
prompt: |
  Given the HTML below, return JSON with title, author,
  body, published_at.
```

Block scalar 按 body 最小公共缩进 dedent。生成 `body:` 时**保持缩进一致**——否则 parser 会保留奇怪的前导空白。

## 4. Hello World

```al
flow root:
  intent: 把数字翻倍后加 1
  steps:
    - times_two
    - add_one


code times_two:
  intent: multiply input by 2
  input: int
  output: int
  body: |
    def times_two(x):
        return x * 2


code add_one:
  intent: add 1 to the input
  input: int
  output: int
  body: |
    def add_one(x):
        return x + 1
```

codegen 把它转成 Python，跑出来 `flow_root(input=5)` 返回 `11` `((5*2)+1)`。

I/O 串接默认语义：**上一步输出 = 下一步 input**。

## 5. 典型 Pattern 库

### 5.1 单 code 工具函数

直接用 code 节点。如果 Python 函数本身就 `def name(...)` 开头，body 保持原样：

```al
code parse_iso_date:
  intent: parse ISO 8601 timestamp string to datetime
  input: str
  output: datetime
  body: |
    from datetime import datetime

    def parse_iso_date(s):
        return datetime.fromisoformat(s)
```

### 5.2 顺序流水线

```al
flow process:
  intent: clean then aggregate
  steps:
    - clean
    - aggregate
    - format
```

### 5.3 并行子步骤

```al
flow fetch_sources:
  intent: fetch from RSS and web in parallel
  steps:
    - parallel:
        - read_feeds
        - scrape_html
    - merge_results
```

并行块的输出 = 子项按源顺序的 list；下一步 `merge_results` 收到 `[read_feeds_output, scrape_html_output]`。

### 5.4 对列表每元素处理（map）

```al
flow summarize_all:
  intent: summarize each article
  steps:
    - each article:
        - summarize_item
```

`each article:` 把当前 input（一个 list）的每个元素绑定到名为 `article` 的变量，对每个元素跑内部 steps。最终输出是 list（每元素一份 inner 结果）。

### 5.5 条件分支

```al
flow review_or_publish:
  intent: human review when confidence low, else auto publish
  steps:
    - check_confidence
    - if input < 0.7:
        - human_review
      else:
        - auto_publish
```

`if <cond>:` 把 `cond` 当 Python 表达式 eval，运行环境含 `input`（上一步输出）和当前 each 绑定的变量名。**支持白名单内置**（len/min/max/sum/abs/all/any/round/isinstance/int/float/str/bool/list/tuple/dict/set/True/False/None）；`__import__` / `open` / `exec` 被禁。

### 5.6 agent 调用 + fallback

```al
agent classify_topic:
  intent: classify article topic from title
  input: title str
  output: topic str
  prompt: |
    Given the article title, return one topic label:
    "tech" | "politics" | "sports" | "other".
  fallback: classify_topic_naive


code classify_topic_naive:
  intent: keyword fallback when LLM fails
  body: |
    def classify_topic_naive(title):
        t = title.lower()
        if "python" in t or "AI" in title: return "tech"
        return "other"
```

`fallback:` 必须是**同文件内 code 或 agent 节点名**。仅在 agent 抛 `AgentInvocationError` 时触发。

### 5.7 可复用工具包

```al
set scraping_kit:
  intent: reusable bundle for messy HTML
  tools:
    - fetch_url
    - readability_js
  skills:
    - extract_jsonld
  extensions:
    - mcp_playwright
  memory: |
    site_selectors:
      "nytimes.com": { title: "h1.headline" }


agent extract_article:
  intent: extract structured fields from HTML
  use: scraping_kit
  prompt: |
    Given the HTML, return JSON with title/author/body/published_at.
```

`set` **不能出现在 steps 中**。agent 通过 `use: <name>` 或 `use:\n  - name1\n  - name2` 引用。多个 set 的 memory 按声明顺序 deep-merge（后覆盖前）。

## 6. 从 Python 想 agent-lang（对照）

| Python 写法 | agent-lang 写法 |
|---|---|
| `def foo(x): return x + 1` | 一个 `code foo:` 节点，body 保留 verbatim |
| 顺序调用 `c = a(); d = b(c)` | `flow:` 含 `steps: [a, b]`（I/O 隐式串） |
| `results = [f(x) for x in items]` | `each item: [f]` |
| `if cond: do_x() else: do_y()` | `if cond: [do_x] else: [do_y]` |
| `with ThreadPool(): map(...)` | `parallel: [a, b, c]` |
| LLM 调用 + JSON 解析 | `agent`节点，prompt 在 `prompt:` 里 |

## 7. 常见错误清单（不要踩）

| 坑 | 表现 | 解法 |
|---|---|---|
| Tab 缩进 | `LexError: tab character not allowed` | 用 2 空格 |
| step 缩进 +2 而非 +4 | `ParseError: unexpected token` | `- ` 占 2 char，下一级再缩 2 空格 = 总 +4 |
| `fallback: <set_name>` | runtime 报 unresolved（v1 容错但不调） | fallback 必须是 code/agent 节点 |
| `agent` 写 `steps:` | parser 接受但 codegen 忽略（spec § 4.5 只允许 flow） | 想要子步骤请改用 `flow` |
| 多参数 code 函数（`def f(a, b)`） | runtime 调 `f(input)` 失败 TypeError | v1 code 函数应只接一个位置参数；多输入用 dict/tuple 包装 |
| `memory:` 写非法 YAML | runtime warn + memory=None | 用合法 YAML；或者保持极简 |
| `set` 出现在 `steps:` | RuntimeSemanticError | set 是资源不是步骤 |
| `body:` 缩进不一致 | parser 保留奇怪前导空白 | block scalar 按最小公共缩进 dedent；保持一致 |

## 8. codegen 输出长什么样

```al
code add_one:
  body: |
    def add_one(x):
        return x + 1


flow root:
  steps:
    - add_one
```

codegen 出来的 Python：

```python
from al.runtime import agent_call, flow_call, SetDefinition


# code: add_one
def add_one(x):
    return x + 1


# flow: root
def flow_root(input=None):
    return flow_call(
        name='root',
        intent='',
        schedule='',
        steps=[{'kind': 'ref', 'name': 'add_one'}],
        input=input,
    )
```

要点：

- code 节点的 body **原样**进入函数；导入语句也保留。
- flow 节点变成 `flow_<name>(input=None)` 包装函数；运行期由 orchestrator 解释 steps。
- agent 节点变成 `agent_<name>(input=None)` 包装函数 + `__al_output__` 元数据。
- set 节点变成 `<NAME_UPPER> = SetDefinition(...)` 字面量。

**实证 pipeline 注意**：对于 Commit0 这种"只跑 pytest" 的 benchmark，generated Python 直接被 pytest import 跑测试，**不经过 runtime**。所以 `flow_call` 在测试期间不会被调用——只有 code 节点的 body 决定 pass/fail。但若你的 code 节点之间互相依赖，**调用关系仍要 import 得到**（因为 codegen 把它们都 emit 到同一个模块）。

## 9. 实证写作 checklist（给 LLM 实现 body 时）

1. 每个 code 节点的 `body:` 必须是合法 Python，能被 `ast.parse` 通过。
2. 函数签名 `def <node_name>(...)` 必须能从同文件其他 code 节点 import 调用——保持函数名 = 节点名。
3. 用到的 Python 库 (`import X`) 必须在 commit0 项目的依赖里——优先用 stdlib，外部库要看 `requirements*.txt`。
4. 不要捏造 spec 没要求的辅助节点；按 skeleton 给的结构填，不擅自增删。
5. agent 节点的 `prompt:` 是给 LLM 的指令，不是给 Python 的——pipeline B 在跑 pytest 时这些不参与（除非 generated Python 显式调用 agent_call，本实证中通常不会）。

## 10. 不要做的事

- ❌ 不要用 v2 保留字 `reuse:` / `freeze:`（v1 无 runtime 效果，徒增噪音）
- ❌ 不要在 agent 节点里写 `steps:`（与 spec § 4.5 矛盾，v1 runtime 忽略）
- ❌ 不要给 set 节点写 `intent` 以外的字段顺序乱排（用 spec § 4.5 顺序）
- ❌ 不要在 code body 里 `from al.runtime import ...` 调 runtime API（除非你确定要这么干 — 通常只是干扰）
- ❌ 不要把 secret/API key 写进 `memory:` block scalar——它会进 codegen 出的 Python 字符串字面量
