"""Benchmark WebUI — local viewer for runs under benchmarks/reports/runs/.

Usage:
    python -m benchmarks.webui [--port 8765] [--host 127.0.0.1]

Default: bind 127.0.0.1 (local only, no LAN exposure).
"""

from benchmarks.webui.app import create_app

__all__ = ["create_app"]
