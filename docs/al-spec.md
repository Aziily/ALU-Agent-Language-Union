# Agent Language — Spec v0.7

> 当前版本。前序版本归档在 `docs/spec/history/`。
> v0.7 收紧两件事：① **input/output 必须是结构化 Python 类型注解**（自由英语单独出现 → parser reject），可选 `(description)` 后缀承载自然语言描述；② **新增多文件支持**——顶层 `import` / `from ... import ...` 把另一个 .al 的顶层定义引入当前作用域；③ **新增 `return:` 块头**用于 `steps:` 内的 flow 显式输出。
> v0.6 在 v0.5 基础上做了两件事：① **新增 `set` 节点**，作为 agent 的能力包（tools / skills / extensions / memory）；② **明确 host 语言锁死 Python**（移除关于"future host"的伸缩点）。

---

## 1. 产品定位

**Agent Language 是一个把 Python 代码、agent 调用、可复用 agent 装备包织进同一份可编辑文本的薄编排层。**

核心循环是 **edit-driven**：

> "Look at a flow → change it → see what changed."

用户最常走的路径：

1. 打开一个 flow（自己写的，或 agent 生成的）
2. 在 radial canvas 上读结构
3. 改 `intent`、换节点 kind、加子步骤、重生成实现
4. 信任 agent 在底下补完实现

监控、调试、replay 是次要的。UI 重心在编辑。

Agent Language **不是** 带编辑器的工作流引擎，**不是** 通用 LLM IDE，**不是** 无代码工具。**是** 一层薄而有主张的胶水，让 Python 开发者一脚踏进确定性代码、一脚踏进 agent 步骤，且让接缝可见。

---

## 2. 架构（v1 — 三件 Python 包 + 第三方 benchmark）

```
                ┌──────────────────────────────────┐
                │  src/al/cli.py            │
                │  parse · emit · run · check      │
                └─────────────────┬────────────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            ▼                     ▼                     ▼
   src/al/parser/   src/al/codegen/  src/al/runtime/
   source ⇄ AST            AST → Python            interpret AST
                                                   (orchestrator,
                                                   code/agent/set 执行)

                       ┌──────────────────┐
                       │  benchmarks/     │
                       │  harness · pipe  │
                       │  metrics         │
                       └────────┬─────────┘
                                ▼
                       thirdparty/commit0/
                       (git submodule, 不修改)
```

**复用而非重发明**（与 v0.5 一致）：

- `code` 节点 → 字面 Python，subprocess / exec 跑
- `agent` 节点 → 委托给 [goose](https://github.com/block/goose)
- Agent Language 是**胶水**——一个微型 grammar，把 Python 函数、agent 调用、流程控制和 agent 装备包系成一份可编辑文件

---

## 3. 四种节点

每个节点都恰是以下一种：

| Kind     | 颜色提示 | 是什么                                                 | 何时用                                                                     |
|----------|---------|--------------------------------------------------------|----------------------------------------------------------------------------|
| `flow`   | 中性    | 复合容器；有子节点；自身不执行                          | 一个步骤拆 ≥ 2 子步骤，或需要分支 / 并行                                    |
| `code`   | 蓝      | 字面 Python；叶节点                                     | 确定性、可重放、对性能敏感、对接外部系统                                     |
| `agent`  | 暖      | agent 调用（prompt + fallback）；可有子节点（agent 编排） | 输入输出形状多变；规则难列尽；能容忍偶发失败                                  |
| `set`    | 紫      | **agent 装备包**（tools / skills / extensions / memory）；自身不执行 | 多个 agent 共享同一组工具 / 技能 / MCP 服务 / 学习到的状态时                  |

**决策树**（add-node 对话框也展示这棵）：

```
此步骤是否有稳定 I/O 契约 + 清晰逻辑？
  yes  →  code
  no   →  能拆成 ≥ 2 子步骤吗？
            yes →  flow
            no  →  agent

此节点是不是"被多个 agent 引用、本身不执行的资源/能力"？
  yes  →  set
```

**Subtle rule**: 如果一个 `agent` 在多次跑里对同样输入稳定返回同样形状 → 候选**冻结**为 `code`（v2 特性）。

---

## 4. 语法 — Python/YAML 缩进风格

### 4.1 文件扩展名 + 编码

- 扩展名：`.al`
- 编码：UTF-8
- 行尾：LF (`\n`)
- 一个文件可包含多个顶层定义。

### 4.2 缩进规则

- **每层 2 个空格**。禁用 Tab。
- 缩进**严格**定义块结构。无大括号、无 `end`、无分号。
- 一个块在第一个缩进 ≤ 块头缩进的行处结束。

### 4.3 顶层声明符

恰好一个声明符开启一个定义。其后的名字是节点 ID。

```al
flow  <name>:
agent <name>:
code  <name>:
set   <name>:
preamble <name>:        # 模块级 Python 上下文（v0.7：第 5 个声明符）
```

名字遵循 Python identifier 规则：`[A-Za-z_][A-Za-z0-9_]*`（snake_case 推荐；PascalCase 在节点名上也被接受，用于桥接 PascalCase Python 风格的项目如 voluptuous）。

**`import` / `from` —— v0.7 多文件声明**（不是 Definition，而是 `Program.imports`）：

```al
import other_module
from utils import normalize, parse_date
```

语义对齐 Python `import`，但解析的是 `<project_root>/<module>.al`（不是 .py）。详见 §4.12。

### 4.4 字段语法

定义内部，字段取以下三种形态之一：

```al
# (a) inline value
intent: top news, deduped, summarized
schedule: daily 09:00

# (b) nested block
output:
  title: str
  body: str
  published_at: datetime

# (c) block scalar (multi-line text — | 标记同 YAML)
prompt: |
  Given the HTML below, return JSON with title, author,
  body, published_at.
  If page is a listing or paywall, return null.
```

Block scalar 按其 body 的最小公共缩进 dedent。`prompt:`（free text）和 `body:`（字面 Python）用它。

### 4.5 字段关键字

| 关键字       | 适用节点         | 含义                                                                                  |
|-------------|-----------------|---------------------------------------------------------------------------------------|
| `intent:`   | 全部             | 一行 plain-English 描述。**单一真源**——UI 编辑 intent 字段映射到这里                    |
| `schedule:` | flow             | 何时跑（如 `daily 09:00`、`cron 0 9 * * *`）                                           |
| `input:`    | flow / code / agent | 输入形状（v0.7：**Python 类型注解 + 可选 `(description)` 后缀**；或嵌套 FieldGroup）   |
| `output:`   | flow / code / agent | 输出形状（同上）                                                                       |
| `steps:`    | flow             | 有序子步骤引用列表 — flow 的 body                                                      |
| `prompt:`   | agent            | 给 agent 的自然语言指令的 block scalar                                                |
| `body:`     | code             | 字面 Python 源的 block scalar                                                          |
| `fallback:` | agent            | agent 失败时调用的节点引用                                                             |
| `use:`      | agent            | **新增** 引用一个或多个 `set` 节点，把其 tools/skills/extensions/memory 注入此 agent     |
| `tools:`    | set              | **新增** 工具引用列表（bare names 或 `mcp/<name>` 命名空间形式）                       |
| `skills:`   | set              | **新增** 可复用 skill 引用列表（bare names）                                           |
| `extensions:` | set            | **新增** MCP 服务器引用列表（约定用 `mcp/<server-name>` 命名空间）                      |
| `memory:`   | set              | **新增** block scalar 形式的结构化记忆数据（YAML 兼容）                                |

### 4.6 控制关键字（用在 `steps:` 内）

| 关键字           | 含义                                                          |
|-------------------|---------------------------------------------------------------|
| `parallel:`       | 嵌套列表中的项目并发执行                                        |
| `each <X>:`       | 嵌套列表中的项目按 X 的每个元素跑一次（map）                     |
| `if <cond>:`      | 条件。可配 `else:`                                              |
| `return <ref>`    | **v0.7：** flow 的显式输出。引用 `steps:` 内先前出现的节点名，标记其返回值作为本 flow 的 output。必须是 `steps:` 列表的最后一项，且**整个 flow 至多一个 `return`**。无 `return` 时 flow 输出 = `None`（与 v0.6 行为一致） |

这些是**块头**——`parallel:` / `each X:` / `if X:` 必须 `:` 结尾且后面接缩进的 `- ` 列表。`return <ref>` 是**单行项**，不带 `:`。

### 4.7 列表、注释、引用

```al
steps:
  - fetch_sources       # 节点引用（解析为顶层定义）
  - parallel:
      - clean_data
      - enrich_metadata
  - each article:
      - summarize_item
      - rank_item
  - if low_confidence:
      - human_review
    else:
      - auto_publish
  - deliver
```

- `-` 开列表项。项目要么是**裸名**（节点引用），要么是**块头**（`parallel:` / `each X:` / `if X:`）。
- `#` 到行尾——注释。
- `steps:`、`fallback:`、`use:`、`tools:`、`skills:`、`extensions:` 中的裸名都是引用，按作用域内的顶层定义解析。

### 4.8 `set` 的完整示例

```al
set scraping_kit:
  intent: reusable bundle for agents that read messy HTML

  tools:
    - fetch_url            # plain HTTP GET with throttling
    - readability_js       # mozilla/readability fallback
    - html_to_markdown

  skills:
    - extract_jsonld       # try JSON-LD first
    - normalize_dates      # parse "Posted 3 hours ago" etc.

  extensions:               # MCP servers
    - mcp/playwright       # for JS-heavy pages
    - mcp/serpapi          # search lookups when title is missing

  memory: |
    # learned per domain at runtime; persists across calls
    site_selectors:
      "nytimes.com":  { title: "h1.headline", body: "section.article-body" }
      "medium.com":   { title: "h1", body: "article" }
      "substack.com": { title: "h1.post-title", body: "div.body" }
    paywall_domains: ["wsj.com", "ft.com", "economist.com"]


agent extract_article:
  intent: pull title, author, body, published_at from raw HTML
  input: raw HTML
  output:
    title: str
    author: str
    body: str
    published_at: datetime

  use: scraping_kit          # ← 引用上面的 set

  prompt: |
    Given the HTML below, return JSON with the four fields.
    If the page is a listing or paywall, return null.

  fallback: readability_js
```

### 4.9 `set` 解析规则

| 规则 | 说明 |
|---|---|
| `set` 节点本身不参与执行流，不能出现在 `steps:` 中作为引用项 | 它是资源，不是步骤 |
| `tools` / `skills` / `extensions` 中的裸名分三类解析 | (1) 当前文件内同名 `code` / `agent` 节点 → 视作工具实现；(2) `mcp/<name>` 前缀 → MCP 服务器引用；(3) 其它 → 标准库 / runtime 内置工具表查询 |
| `memory:` 是 block scalar | runtime 在加载 set 时把它解析为 YAML 数据结构，注入 agent 上下文 |
| `agent.use:` 既支持单值又支持列表 | `use: scraping_kit` 与 `use:\n  - scraping_kit\n  - logging_kit` 都合法；列表合并按声明顺序，后面的 set 中的 key 覆盖前面 |
| 循环引用（agent ↔ set ↔ agent）禁止 | parser 阶段静态检测 |

### 4.10 v2 保留

- `reuse:` — 在语法里登记，v1 无 runtime 效果。v2 用来标记跨 flow 复用的 capsule。
- `freeze:` — agent 节点冻结为 code 节点的提示。

### 4.11 v0.6 相对 v0.5 的变更

- **新增** 顶层声明符 `set`
- **新增** agent 字段 `use:`
- **新增** set 字段 `tools:` / `skills:` / `extensions:` / `memory:`
- **明确** host 语言只支持 Python（去掉 v0.5 §1, §2 中关于"v1 host language"的措辞，直接说"host language"）
- **重申** parser / codegen / runtime 全部 Python 实现，不再有 TS/JS 部分

### 4.12 I/O 语法（v0.7 新规则）

`input:` 和 `output:` 字段的值有两种合法形态：

**(a) Inline 形式 — `TypedAnnotation`**

```bnf
io_value     := type_expr  ('(' description ')')?
type_expr    := <Python type annotation>
                # 例: str, int, list[str], dict[str, int],
                #     Optional[bytes], tuple[str, int]
description  := <任意字符直到匹配的 ')'，可含空格、英文、`,`、`->`>
```

例子：

```al
input: list[str]                          # 纯类型
input: list[str](article urls)            # 类型 + 描述
output: dict[str, str](title->body, English text)
output: bytes(raw HTML, UTF-8 or latin-1)
```

**(b) Nested FieldGroup — 多字段输出**

适合 output 是多键 record：

```al
output:
  title: str
  author: str
  body: str
  published_at: datetime
```

每个内部字段值也遵循 `type_expr ('(' description ')')?` 规则。

**v0.6 兼容性 — 破坏性变更**：v0.6 接受的自由英语（`input: raw HTML`、`output: list of articles`）在 v0.7 **被 parser reject**。迁移路径：
- `input: raw HTML` → `input: str(raw HTML)` 或 `input: bytes(raw HTML)`
- `output: list of articles` → `output: list[Article](articles)`（如果 `Article` 是 preamble 里的类型别名）

**为什么收紧？** v0.6 让 LLM 同时面对两种风格，输出 I/O 标注漂移（有时写自由英语、有时写类型）。强制结构化让模型有稳定先验，且 codegen / inject 可以用类型推断验证形状。

### 4.13 多文件 / `import`（v0.7 新规则）

#### 4.13.1 顶层 import 声明

合法形态（**必须出现在文件顶部**，先于任何 Definition）：

```al
import other_module
import other_module as om
from utils import normalize, parse_date
from data_models import Article, Source
```

语法 BNF：

```bnf
import_decl  := 'import' MODULE_PATH ('as' IDENT)?
              | 'from' MODULE_PATH 'import' NAMES
NAMES        := IDENT (',' IDENT)*
MODULE_PATH  := IDENT ('.' IDENT)*
```

#### 4.13.2 模块解析

- `import foo` → 加载 `<project_root>/foo.al`
- `import pkg.sub` → 加载 `<project_root>/pkg/sub.al`
- `from utils import x, y` → 加载 `<project_root>/utils.al` 并把 `x`、`y` 引入当前作用域

`project_root` 解析顺序：(1) 包含 `.al-project` 标记文件的最近祖先目录，否则 (2) 当前 .al 文件所在目录。

#### 4.13.3 名字解析

`steps:` / `fallback:` / `use:` / `tools:` 内的裸名按以下顺序解析：

1. 当前文件 Definition.name 命名空间
2. `import X` 引入的限定名（`X.name` 形式访问）
3. `from X import Y` 直接引入到当前作用域（裸名 `Y` 可用）

冲突规则：本地 Definition 永远优先；多个 `from X import Y` 冲突 → parser ParseError。

#### 4.13.4 循环 import 检测

Parser DFS 检测：A 文件 `import B` 且 B 文件 `import A` → `ImportCycleError`。这与 Python 不同（Python 用 lazy 解析容忍循环），但 AL 是 declarative 编排层，循环 import 几乎总是建模错误，因此早 fail。

#### 4.13.5 单文件子集（v0.6 兼容）

**无 import 的 .al 文件是合法的 v0.7 程序**，行为与 v0.6 完全一致。这保证：
- 16 个 benchmark skeleton 不需要立刻迁移到多文件
- v0.6 单文件示例 `examples/daily_news.al` 在 v0.7 解析器下仍然解析（只需 I/O 标注按 §4.12 迁移）

### 4.14 Targeted Body（v0.7.1 — Codex co-iter round 1）

`code` 节点新增**可选** `target:` 字段，格式 `<relpath>::<qualname>`：

```al
code LRUCache__get:
  intent: lookup key, return default on miss, refresh LRU order on hit
  target: cachetools/lru.py::LRUCache.get
  input: tuple[Any, Any](key, default=None)
  output: Any(stored value or default)
  body: |
    if key not in self._store:
        return default
    self._store.move_to_end(key)
    return self._store[key]
```

**语义**：

- `<relpath>` 是工程内 .py 文件的相对路径。
- `<qualname>` 是 Python `__qualname__` 风格的点分路径（`hashkey` / `LRUCache.get` / `Outer.Inner.method`）。
- 当 `body:` 内**不含** `def` 行时，inject pipeline 从 stripped .py 中查 target 函数的签名（含装饰器、默认参数、注解），把 `body:` 内容作为该函数的函数体插入。
- 当 `body:` 内含完整 `def name(...):` 时，`target:` 仅作为元数据保留（current behavior 不变）。
- `target:` 缺失时退回到原 v0.7 行为（`<Class>__<method>` dunder + `# inject-into:` 启发式）。

**为什么加这个字段**：

v0.7 pilot 显示 LLM 在 greenfield 模式下逐字抄写 stripped Python 里的 `def name(args):` 行 — 重复劳动，且默认值/decorator 复写出错会让整个函数失效。Targeted Body 让 LLM 只写**实现语句**（model writes strictly less than the Python baseline），把签名锁死在源文件里。这是 Codex round 0 评 6/10 时的 ranked-1 建议（见 [benchmarks/reports/codex-coiter-log.md](../benchmarks/reports/codex-coiter-log.md)）。

### 4.15 Uses Lint（v0.7.3 — Codex co-iter round 3）

`code` 节点新增**可选** `uses:` 字段，类型为 ReferenceList（裸名列表，与 `tools:`/`skills:` 语法一致）：

```al
code ttl_cache:
  target: src/cachetools/func.py::ttl_cache
  uses:
    - cached
    - TTLCache
    - _UnboundTTLCache
    - keys
    - RLock
  body: |
    if maxsize is None:
        cache = {}
    elif maxsize == 0:
        cache = None
    else:
        cache = _UnboundTTLCache(ttl, timer) if not maxsize else TTLCache(maxsize, ttl, timer)
    ...
```

**语义**：`al.parser.validate.validate_uses(program)` AST-walk 每个 `code` body 的 free Load names（不含本地变量 / 参数 / for-target / 嵌套定义 / Python builtins），逐个检查：

1. 在本节点 `uses:` 列表里 → ok
2. 在同文件内任一 `preamble` 的 `imports` / `constants` / `body:` 顶层名字空间里 → ok
3. 在 `Program.imports` （顶层 `from X import Y` / `import X`）里 → ok
4. 否则 → `ValidationIssue(code="uses-undeclared")`

警告级（warning-level），不阻塞 inject；通过 greenfield implementer 的 iter feedback 回传给 LLM 让它下一轮修。

**为什么加这个字段**：Round 2 Patch Mode 让 working bodies 不被擦掉；Round 3 Uses Lint 让 patch 进来的新 body 更难引入幻觉助手（cachetools pilot 历史上有 LLM 调用未定义 `_cache(...)` 的失败模式）。把「这个 body 的外部依赖」从隐式变成可声明 + 可校验。

### 4.16 v0.7 相对 v0.6 的变更

- **破坏性**：`input:` / `output:` 自由英语单独出现 → ParseError。必须用 `T(description)` 或嵌套 FieldGroup。详见 §4.12。
- **新增** 顶层 `import` / `from ... import ...` 声明 + 多文件解析 + 循环检测。详见 §4.13。
- **新增** `return <ref>` 控制项（用在 `steps:` 内尾部）。flow 显式输出。详见 §4.6。
- **不变** 其它 v0.6 语义、关键字、节点种类。

---

## 5. 端到端示例（与 v0.5 example 一致 + set）

见 `examples/daily_news.al`。覆盖全部 4 种节点 + 所有控制结构。

---

## 6. Capsule（概念 — v1 部分）

一个 **capsule** 是不可变单元 `{intent, body|prompt, io_schema, set_refs}`。每次 regenerate 创建新版本（rail 显示 `cap_xxxxxx` 签名）。

- **v1**：签名展示，version-history 占位，`reused_in` 字段在数据模型层携带
- **v2**：capsule 一等公民，按签名寻址，可被任意 flow 调用；registry / search；per-capsule 指标

---

## 7. v1 runtime 的限制（明确）

v1 是单用户原型。以下**有意**不做：

- 同一 flow 没有并发实例
- agent step 不可中断（无 mid-call cancel）
- 无卡死检测——用户从 trace 时间戳推断
- `fallback:` 之外没有重试
- 无多用户、无权限

---

## 8. v1 agent 后端

| 设置 | 值 |
|------|-----|
| Provider | [goose](https://github.com/block/goose)（Block 的 MCP-based agent） |
| Model    | 通过 goose 配置；默认 `gpt-5.4-nano` over yunwu |
| Transport | `src/al/runtime/agent_bridge.py` 起 goose subprocess（每次调用一次；daemon 复用是 [UPGRADE]） |

**host 语言**：Python（CPython 3.11+）。**没有"将来支持其他语言"的伸缩点**——这是有意的简化（详见 `docs/design/parser.md`）。

---

## 9. UI primitives（v1，从 v0.5 prototype 继承的设计意图）

> **v0.6 的 UI 实现待阶段 ④ 重写。**v0.5 的 React 原型已归档到 `archive/legacy-jsx-prototype/`，仅保留设计意图：

- Radial canvas — focused 节点居中，子节点在环上。双击子节点聚焦。
- Add-child `+` — 在最大空隙单插入槽。
- 右栏：capsule 头 + intent（始终可编辑）+ 三标签（code / trace / replay）。
- Resizable rail（可拖拽，记忆位置）。
- 左下 minimap，高亮当前 focus path。
- Tweaks panel（toggle 显示）。
- code editor — 双击块编辑；`Esc` 取消；`⌘Enter` 保存。

---

## 10. v0.7 changelog

vs v0.6：
- **I/O 收紧**：input/output 必须是 `T(description)` 或嵌套 FieldGroup；自由英语 reject。详见 §4.12。
- **多文件支持**：顶层 `import` / `from X import Y`，跨 .al 文件引用。详见 §4.13。
- **`return <ref>`**：flow 显式输出。详见 §4.6。
- **Pipeline C**：benchmark 新增 greenfield AL 写作 pipeline——给模型 stripped Python，要求它从零写 .al（可多文件）。Pipeline B（skeleton-based）保留做对照。详见 `docs/design/benchmark.md`。

## 11. v0.6 changelog（历史）

vs v0.5：
- **新增 4 类节点之一：`set`**（agent 装备槽：tools / skills / extensions / memory）
- **新增 agent 字段 `use:`**
- **host 语言锁定 Python**，移除"v1 host"的伸缩措辞
- **代码栈整体改 Python**（parser / codegen / runtime / cli / 编辑器后端）
- 文档结构搬到 `docs/spec/`，v0.5 归档到 `docs/spec/history/`

---

## 12. History

- **v0.2** — symbol-heavy（`-> ~ || ?>`）。已废弃。
- **v0.3** — 自然 English 短语。冗长。已废弃。
- **v0.4** — 单词关键字集，结构仍模糊。已废弃。
- **v0.5** — 正式 Python/YAML 缩进 grammar，Python 锁定为 host。已废弃，归档在 `history/`。
- **v0.6** — 加入 `set` 节点，全栈 Python 化。已废弃，归档在 `history/`。
- **v0.7** — I/O 收紧、多文件 import、flow `return`、greenfield benchmark pipeline。**当前。**
