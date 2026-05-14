"""CLI entry: ``python -m benchmarks.webui``."""

from __future__ import annotations

import argparse
from pathlib import Path

from benchmarks.webui import create_app


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="benchmarks.webui")
    parser.add_argument("--host", default="127.0.0.1",
                        help="bind host (default: 127.0.0.1 — local only)")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--runs-root", type=Path, default=None,
                        help="override the benchmarks/reports/runs/ path")
    parser.add_argument("--debug", action="store_true",
                        help="flask debug mode (autoreload)")
    args = parser.parse_args(argv)

    app = create_app(runs_root=args.runs_root)
    print(f"WebUI: http://{args.host}:{args.port}/", flush=True)
    print(f"runs_root: {app.config['RUNS_ROOT']}", flush=True)
    app.run(host=args.host, port=args.port, debug=args.debug)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
