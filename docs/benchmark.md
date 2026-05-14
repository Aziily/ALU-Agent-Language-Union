# Benchmark 评测协议

> 基于 `docs/reports/benchmark-eval.md` 的结论，落地为可执行协议。

---

## 1. 度量目标

**核心问题**：把 Python 工程项目"翻译为 agent-lang，再 codegen 回 Python"这条往返路径，对工程项目的实现是**无损**的，甚至是**有益**的吗？

**核心指标**：

> **往返税** = 原生 Python baseline 的 pytest 通过率 − agent-lang pipeline 的 pytest 通过率

如果往返税接近 0（甚至为负），说明 agent-lang 表达力够、不丢信息；如果显著为正，说明 agent-lang 在表达 / 重建过程中丢失了关键语义。

---

## 2. Pipeline 定义

```mermaid
flowchart LR
    subgraph BASELINE[Baseline pipeline]
        B1[Commit0 起始 repo<br/>(空函数 + spec)]
        B2[实现器 agent<br/>(直接吃 Python skeleton)]
        B3[填好的 Python]
        B4[pytest]
        B1 --> B2 --> B3 --> B4
    end

    subgraph AGENTLANG[agent-lang pipeline]
        A1[Commit0 起始 repo<br/>(空函数 + spec)]
        A2[翻译器 agent<br/>(Python skeleton → .al)]
        A3[.al 中间表征]
        A4[实现器 agent<br/>(填 .al 中的 body)]
        A5[完整 .al]
        A6[parser + codegen<br/>(.al → Python)]
        A7[pytest]
        A1 --> A2 --> A3 --> A4 --> A5 --> A6 --> A7
    end

    B4 -. 对照 .-> A7
```

**关键**：两条 pipeline 用**同一个底层模型**和**同一份 spec**，唯一变量是中间是否经过 agent-lang。

---

## 3. 主 benchmark：Commit0

| 项 | 值 |
|---|---|
| Repo | https://github.com/commit-0/commit0 |
| 接入路径 | `thirdparty/commit0/`（git submodule） |
| 不修改原代码 | ✅（项目规则 9） |
| 子集大小 | v1 先选 5 个最小的 lib 跑 smoke，全集 54 个留阶段 ③ |
| 评测脚本 | `benchmarks/harness/commit0_adapter.py` |
| 评测产出 | `benchmarks/reports/<timestamp>/{run.json, summary.md}` |

---

## 4. 次要 benchmark：SWE-bench Verified（阶段 ③ 接入）

改造方法（来自评估报告）：剥掉 buggy 文件 → 当作 skeleton → 跑 pipeline → 检查 `FAIL_TO_PASS` 测试通过。

接入位置：`benchmarks/harness/swebench_adapter.py`（阶段 ③ 实现）。

---

## 5. 抗污染锚点：EvoCodeBench / R2E-Eval（阶段 ③+）

约 250 题级别的 sanity check，确认主榜单不是"模型记住了 Commit0"的产物。

---

## 6. agent 节点 oracle 类型

按评估报告 §2 推荐：每个 agent 节点必须声明以下之一：

| 类型 | 触发 | 评分方式 |
|---|---|---|
| `typed_output` | agent 节点的 `output:` 是结构化 schema | schema validation pass/fail |
| `downstream_pytest` | agent 输出流入 code 节点，最终落到 pytest | 复用底层 pytest 通过率 |
| `state_hash` | agent 改变了某个 state（DB / 文件） | 对比目标 state 哈希 |
| `llm_judge` | 自由文本输出 | Prometheus-2 / G-Eval rubric 评分 |

**没有 oracle 的 agent 节点拒绝合入 examples/ 和 benchmarks/**（阶段 ② 起加 lint check）。

---

## 7. 可靠性指标：pass^k

每个含 agent 节点的 pipeline 跑 k=5 次（阶段 ③ 起 k≥5），上报：

- `pass^1`：单次成功率
- `pass^k`：k 次全部成功的比例
- `pass^k / pass^1`：稳定性比

阈值（评估报告 §"会让我改建议的阈值"）：

- `pass^5 / pass^1 < 0.6` → 随机性是主要成本，先投资重试 / 验证 harness，再加新特性

---

## 8. 报告格式

每次跑生成：

```
benchmarks/reports/<YYYYMMDD-HHMMSS>/
├── run.json                # 完整 raw 数据
├── summary.md              # 人类可读摘要
├── per_repo/
│   ├── <repo_name>.json
│   └── <repo_name>.diff    # agent-lang 输出 vs 原始 Python diff
└── pass_at_k.json          # 跨 k 次的统计
```

`summary.md` 模板（`benchmarks/metrics/summary_template.md`）：

```markdown
# Benchmark Run — <timestamp>

| 指标 | Baseline | agent-lang | Δ |
|---|---|---|---|
| pytest pass% (over <N> repos)        | XX.X% | YY.Y% | ±ZZ.Z pp |
| 平均 pass^5                          | XX.X% | YY.Y% | ±ZZ.Z pp |
| 平均每 repo runtime (sec)            | NN    | MM    | +KK |

**往返税**：±ZZ.Z pp

## Per-repo
...
```

---

## 9. 决策阈值（评估报告 § 会让我改建议的阈值）

| 阈值 | 行动 |
|---|---|
| 往返税 > 15 pp | 重新评估 agent-lang 是否该作为真源（停下来开会） |
| 往返税 < 3 pp | 已饱和，进入阶段 ④ 并启动自建 benchmark 调研 |
| `pass^5 / pass^1 < 0.6` | 投资重试 / 验证 harness |
| LibCST 字节精确 roundtrip 失败 | 上游报 bug，**不**作为发布门禁；执行等价才是真契约 |

---

## 10. 注意事项（继承自评估报告 § 注意事项）

- Commit0 论文（arXiv 2412.01769）的"无 agent 能完整复现任何一个库"是 2024 年数据，我们重跑前要意识到 18 个月已过去。
- pass^k 跌幅是经久不变的曲线形状，但具体百分比看模型版本。
- benchmark 跑成本预算需提前留——前沿模型单次跑数十美元起步。
- SWE-ABS（2025）对抗测试加固让顶级系统平均掉 14.56 pp——**测试得真的能约束行为**，自建 benchmark 时尤其注意。
