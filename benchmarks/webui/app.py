"""Flask app for browsing benchmark runs.

Read-only local viewer. No LLM calls, no benchmark spawning. Just reads
``benchmarks/reports/runs/`` and renders templates.

Created via ``create_app(runs_root)``. Run via ``python -m benchmarks.webui``.
"""

from __future__ import annotations

import difflib
from pathlib import Path

from flask import Flask, abort, render_template, send_file
from markupsafe import Markup

from benchmarks.webui import data, metrics


def create_app(runs_root: Path | None = None) -> Flask:
    """Build Flask app rooted at ``runs_root`` (defaults to project ./benchmarks/reports/runs/)."""
    if runs_root is None:
        # Project root = parents[2] of this file
        runs_root = Path(__file__).resolve().parents[2] / "benchmarks" / "reports" / "runs"
    runs_root = runs_root.resolve()

    app = Flask(__name__)
    app.config["RUNS_ROOT"] = runs_root

    # -----------------------------------------------------------------
    # Routes
    # -----------------------------------------------------------------

    @app.route("/")
    def index():
        runs = data.list_runs(runs_root)
        return render_template("index.html", runs=runs)

    @app.route("/runs/<ts>")
    def run(ts: str):
        try:
            run_data = data.load_run(runs_root, ts)
        except FileNotFoundError:
            abort(404, f"no run at {ts}")
        repos = data.list_repos(runs_root, ts)
        results = run_data.get("results", [])
        repo_summaries = {}
        for repo in repos:
            try:
                pr = data.load_per_repo(runs_root, ts, repo)
                repo_summaries[repo] = metrics.per_repo_summary(pr)
            except (FileNotFoundError, OSError):
                continue
        return render_template(
            "run.html",
            ts=ts,
            meta=run_data,
            repos=repos,
            repo_summaries=repo_summaries,
            tokens=metrics.tokens_by_pipeline(results),
            errors=metrics.error_counts(results),
            bl_aggregate=metrics.aggregate_per_test(results, "baseline"),
            al_aggregate=metrics.aggregate_per_test(results, "al"),
        )

    @app.route("/runs/<ts>/repos/<repo>")
    def repo(ts: str, repo: str):
        try:
            pr = data.load_per_repo(runs_root, ts, repo)
        except FileNotFoundError:
            abort(404, f"no repo {repo!r} in run {ts}")
        return render_template(
            "repo.html",
            ts=ts,
            repo=repo,
            per_repo=pr,
            summary=metrics.per_repo_summary(pr),
        )

    @app.route("/runs/<ts>/cells/<repo>/<int:k>/<pipeline>")
    def cell(ts: str, repo: str, k: int, pipeline: str):
        if pipeline not in ("baseline", "al"):
            abort(400, f"bad pipeline {pipeline!r}")
        try:
            cell_data = data.load_cell(runs_root, ts, repo, k, pipeline)
        except (FileNotFoundError, ValueError):
            abort(404)
        workdir_files, truncated = data.list_workdir_files(runs_root, ts, repo, k, pipeline)
        return render_template(
            "cell.html",
            ts=ts,
            cell=cell_data,
            workdir_files=workdir_files,
            workdir_truncated=truncated,
        )

    @app.route("/runs/<ts>/cells/<repo>/<int:k>/<pipeline>/file/<path:rel_path>")
    def cell_file(ts: str, repo: str, k: int, pipeline: str, rel_path: str):
        try:
            content, truncated = data.read_workdir_file(
                runs_root, ts, repo, k, pipeline, rel_path,
            )
        except ValueError:
            abort(400, "path traversal blocked")
        except FileNotFoundError:
            abort(404)
        return render_template(
            "file.html",
            ts=ts, repo=repo, k=k, pipeline=pipeline,
            rel_path=rel_path,
            content=content, truncated=truncated,
        )

    @app.route("/runs/<ts>/raw/<repo>/<int:k>/<pipeline>.txt")
    def raw_passthrough(ts: str, repo: str, k: int, pipeline: str):
        raw_fp = runs_root / ts / "raw" / f"{repo}-k{k}-{pipeline}.txt"
        if not raw_fp.exists():
            abort(404)
        return send_file(raw_fp, mimetype="text/plain", as_attachment=False)

    @app.route("/runs/<ts>/diff/<repo>/<int:k>")
    def diff_prompts(ts: str, repo: str, k: int):
        """Side-by-side diff of BL vs AL prompt+completion for one (repo, k).

        Phase 1.H'.E. Read-only — uses ``difflib.HtmlDiff`` to render a
        side-by-side HTML table, then injects it into a Bootstrap layout
        so the user can directly inspect what extra context (skeleton +
        authoring guide) the AL pipeline gets vs the BL pipeline.
        """
        try:
            bl = data.load_cell(runs_root, ts, repo, k, "baseline")
            al = data.load_cell(runs_root, ts, repo, k, "al")
        except (FileNotFoundError, ValueError):
            abort(404, f"no diff data for {repo}/k{k} in run {ts}")

        # Tab 1: prompt diff (most useful — shows the AL extras the user
        # asked about: skeleton + authoring guide).
        prompt_html = difflib.HtmlDiff(wrapcolumn=80).make_table(
            bl.prompt.splitlines(),
            al.prompt.splitlines(),
            fromdesc=f"BL prompt ({bl.prompt_chars:,} chars)",
            todesc=f"AL prompt ({al.prompt_chars:,} chars)",
            context=False,  # show full diff, not just changed regions
        )
        completion_html = difflib.HtmlDiff(wrapcolumn=80).make_table(
            bl.completion.splitlines(),
            al.completion.splitlines(),
            fromdesc=f"BL completion ({bl.completion_chars:,} chars)",
            todesc=f"AL completion ({al.completion_chars:,} chars)",
            context=False,
        )
        return render_template(
            "diff.html",
            ts=ts, repo=repo, k=k,
            bl=bl, al=al,
            prompt_diff_html=Markup(prompt_html),
            completion_diff_html=Markup(completion_html),
        )

    # -----------------------------------------------------------------
    # Error handlers
    # -----------------------------------------------------------------

    @app.errorhandler(404)
    def not_found(e):
        return render_template("error.html", code=404, message=str(e)), 404

    @app.errorhandler(400)
    def bad_request(e):
        return render_template("error.html", code=400, message=str(e)), 400

    return app
