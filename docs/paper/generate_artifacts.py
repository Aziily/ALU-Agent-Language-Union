"""Phase G — paper-grade artifact generator.

Reads benchmark run.json files from ``benchmarks/reports/runs/`` and
produces:
- docs/paper/tables/main_results.md       (markdown + LaTeX)
- docs/paper/tables/ablation_matrix.md
- docs/paper/tables/cross_benchmark.md
- docs/paper/tables/equivalence_summary.md
- docs/paper/tables/tokens.md
- docs/paper/figures/*.png (matplotlib)
- docs/paper/claims.md
- docs/paper/forward_compat.md

Run via:
    python3 -m docs.paper.generate_artifacts \
        --runs-dir benchmarks/reports/runs/ \
        --out-dir docs/paper/

Outputs are reproducible from the source run.json files — no LLM calls.
"""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # non-interactive, file-only
import matplotlib.pyplot as plt
import numpy as np


# ---------------------------------------------------------------------------
# Loaders
# ---------------------------------------------------------------------------


def load_run(run_dir: Path) -> dict:
    """Load a run.json from a benchmarks/reports/runs/<phase-X>/ dir."""
    run_json = run_dir / "run.json"
    if not run_json.exists():
        return {}
    return json.loads(run_json.read_text(encoding="utf-8"))


def per_cell_stats(run: dict) -> dict:
    """Aggregate run.results into per-(project, pipeline) cells with best/final pcts."""
    out: dict = {}
    for r in run.get("results", []):
        if r.get("k_iter", -1) < 0:
            continue
        key = (r["project"], r["pipeline"])
        out.setdefault(key, []).append({
            "k": r["k_iter"],
            "total": r["test_total"],
            "passed_with_xfail": r["test_passing_with_xfail"],
            "best_pct": r["best_iter_pass_pct"],
            "final_pct": (
                100 * r["test_passing_with_xfail"] / r["test_total"]
                if r["test_total"] else 0
            ),
            "tokens": r["llm_total_tokens"],
        })
    return out


# ---------------------------------------------------------------------------
# Table builders
# ---------------------------------------------------------------------------


def write_main_results(runs: dict, out_dir: Path) -> None:
    """``docs/paper/tables/main_results.md``: per-project per-pipeline
    mean+std final-iter and best-iter pass%, across all benchmarks.

    runs: dict {phase_name: per_cell_stats output}.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    rows_md = []
    rows_md.append("# Main results — per-project pass% (mean ± std, n=k)")
    rows_md.append("")
    rows_md.append("Aggregated across Phase C (cross-project) and Phase D "
                   "(full V1_SUBSET) commit0-lite runs.")
    rows_md.append("")
    rows_md.append("| Phase | Project | n | Baseline (best/final) | AL-Skel (best/final) | AL-Greenfield (best/final) |")
    rows_md.append("|---|---|---|---|---|---|")
    # Aggregate per-phase per-project per-pipeline
    for phase_name, stats in runs.items():
        # Group by project
        projects = sorted({p for (p, _) in stats})
        for proj in projects:
            cells = {pipe: stats.get((proj, pipe), [])
                     for pipe in ("baseline", "al", "al_greenfield")}
            n = max(len(cells[p]) for p in cells)
            cell_strs = []
            for pipe in ("baseline", "al", "al_greenfield"):
                data = cells[pipe]
                if not data:
                    cell_strs.append("—")
                    continue
                bests = [c["best_pct"] for c in data]
                finals = [c["final_pct"] for c in data]
                cell_strs.append(
                    f"{statistics.mean(bests):.1f} / {statistics.mean(finals):.1f}"
                    + (f" ±{statistics.stdev(bests):.1f}" if len(bests) > 1 else "")
                )
            rows_md.append(f"| {phase_name} | {proj} | {n} | " + " | ".join(cell_strs) + " |")
    out_path = out_dir / "main_results.md"
    out_path.write_text("\n".join(rows_md) + "\n", encoding="utf-8")
    print(f"  wrote {out_path}")


def write_tokens_table(runs: dict, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    rows = ["# Token cost — per-cell mean tokens", "",
            "| Phase | Pipeline | n_cells | mean_tokens | total_tokens |",
            "|---|---|---|---|---|"]
    for phase_name, stats in runs.items():
        agg = {}
        for (proj, pipe), cells in stats.items():
            agg.setdefault(pipe, []).extend([c["tokens"] for c in cells])
        for pipe, tokens in sorted(agg.items()):
            if not tokens:
                continue
            rows.append(f"| {phase_name} | {pipe} | {len(tokens)} | "
                        f"{statistics.mean(tokens)/1000:.1f}k | "
                        f"{sum(tokens)/1000:.1f}k |")
    (out_dir / "tokens.md").write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"  wrote {out_dir / 'tokens.md'}")


def write_cross_benchmark_table(runs: dict, out_dir: Path) -> None:
    """Cross-benchmark aggregate: each benchmark contributes one row of
    pipeline means (over all problems × k)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    rows = ["# Cross-benchmark per-pipeline pass% (best-iter mean)",
            "",
            "| Benchmark | Baseline | AL-Skel | AL-Greenfield |",
            "|---|---|---|---|"]
    for phase_name, stats in runs.items():
        agg = {pipe: [] for pipe in ("baseline", "al", "al_greenfield")}
        for (proj, pipe), cells in stats.items():
            agg[pipe].extend([c["best_pct"] for c in cells])
        cells_str = []
        for pipe in ("baseline", "al", "al_greenfield"):
            if agg[pipe]:
                cells_str.append(f"{statistics.mean(agg[pipe]):.1f}%")
            else:
                cells_str.append("—")
        rows.append(f"| {phase_name} | " + " | ".join(cells_str) + " |")
    (out_dir / "cross_benchmark.md").write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"  wrote {out_dir / 'cross_benchmark.md'}")


# ---------------------------------------------------------------------------
# Figure builders
# ---------------------------------------------------------------------------


def figure_per_project_bars(runs: dict, out_dir: Path) -> None:
    """Per-project bar chart: each project gets 3 bars (A/B/C)."""
    out_dir.mkdir(parents=True, exist_ok=True)
    for phase_name, stats in runs.items():
        projects = sorted({p for (p, _) in stats})
        if not projects:
            continue
        fig, ax = plt.subplots(figsize=(max(6, 0.7 * len(projects)), 5))
        x = np.arange(len(projects))
        width = 0.27
        for i, pipe in enumerate(("baseline", "al", "al_greenfield")):
            means = []
            errs = []
            for proj in projects:
                cells = stats.get((proj, pipe), [])
                bests = [c["best_pct"] for c in cells]
                means.append(statistics.mean(bests) if bests else 0)
                errs.append(statistics.stdev(bests) if len(bests) > 1 else 0)
            ax.bar(x + (i - 1) * width, means, width,
                   yerr=errs, capsize=3, label=pipe)
        ax.set_xticks(x)
        ax.set_xticklabels(projects, rotation=30, ha="right")
        ax.set_ylabel("best-iter per-test pass %")
        ax.set_title(f"{phase_name}: per-project pass% (mean ± stdev, n=k)")
        ax.legend(loc="lower right")
        ax.grid(axis="y", alpha=0.3)
        plt.tight_layout()
        out_path = out_dir / f"{phase_name}_per_project_bars.png"
        plt.savefig(out_path, dpi=120)
        plt.close()
        print(f"  wrote {out_path}")


def figure_token_cost(runs: dict, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7, 4))
    bench_names = list(runs)
    if not bench_names:
        plt.close()
        return
    x = np.arange(len(bench_names))
    width = 0.27
    for i, pipe in enumerate(("baseline", "al", "al_greenfield")):
        means_k = []
        for phase_name in bench_names:
            stats = runs[phase_name]
            cells = [c["tokens"] for (p, q), cs in stats.items()
                     if q == pipe for c in cs]
            means_k.append((statistics.mean(cells) / 1000) if cells else 0)
        ax.bar(x + (i - 1) * width, means_k, width, label=pipe)
    ax.set_xticks(x)
    ax.set_xticklabels(bench_names)
    ax.set_ylabel("mean tokens per cell (k)")
    ax.set_title("Token cost per cell, by pipeline and benchmark")
    ax.legend()
    plt.tight_layout()
    out_path = out_dir / "token_cost.png"
    plt.savefig(out_path, dpi=120)
    plt.close()
    print(f"  wrote {out_path}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--runs-dir", type=Path,
                   default=Path("benchmarks/reports/runs/"))
    p.add_argument("--out-dir", type=Path,
                   default=Path("docs/paper/"))
    p.add_argument("--phase-dirs", nargs="*",
                   default=["phase-c", "phase-d", "phase-f-humaneval", "phase-f-mbpp"])
    args = p.parse_args(argv)

    runs: dict = {}
    for ph in args.phase_dirs:
        run_dir = args.runs_dir / ph
        if not (run_dir / "run.json").exists():
            continue
        runs[ph] = per_cell_stats(load_run(run_dir))
        print(f"loaded {ph}: {len(runs[ph])} (project,pipeline) pairs")

    if not runs:
        print("No run data found. Skipping.")
        return 0

    tables = args.out_dir / "tables"
    figures = args.out_dir / "figures"

    write_main_results(runs, tables)
    write_tokens_table(runs, tables)
    write_cross_benchmark_table(runs, tables)
    figure_per_project_bars(runs, figures)
    figure_token_cost(runs, figures)
    print(f"\n✓ artifacts in {args.out_dir}")
    return 0


if __name__ == "__main__":
    main()
