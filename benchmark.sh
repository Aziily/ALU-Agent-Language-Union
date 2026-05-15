#!/usr/bin/env bash
#
# benchmark.sh — run the commit0 benchmark.
#
# Two modes:
#   --host (Round 0.4): run directly on host via python -m benchmarks.harness
#          --real, no Docker. Uses LLM_* env vars from .env, talks OpenAI-
#          compatible HTTP. Fast iteration, no rebuild required.
#   (default): run inside the al-bench Docker container via --use-claude-code.
#          Uses ANTHROPIC_* env vars; talks Anthropic format via claude -p.
#
# Prerequisites:
#   Both modes:
#     - .env at project root (see .env example below)
#     - thirdparty/commit0_repos/ populated (first run auto-setup)
#   --host:
#     - pip install -e .[test], pip install pytest-json-report pytest-cov
#   Docker mode:
#     - Docker daemon running
#
# Usage:
#   ./benchmark.sh --host --k-repeats 1 --project-names cachetools     # fast smoke
#   ./benchmark.sh --host --n-projects 16 --k-repeats 3                # full host run
#   ./benchmark.sh --n-projects 5 --k-repeats 5                        # Docker
#   ./benchmark.sh --build-only                                        # just image
#
# .env example for --host (OpenAI-compatible local proxy):
#   LLM_API_KEY=<your-key>
#   LLM_BASE_URL=http://127.0.0.1:9000/v1
#   LLM_MODEL=gpt-5.4
#
# .env example for Docker (Anthropic-format via Claude Code CLI):
#   ANTHROPIC_AUTH_TOKEN=<your-traxnode-token>
#   ANTHROPIC_BASE_URL=https://canvas.aipaibox.com
#   ANTHROPIC_DEFAULT_OPUS_MODEL=gpt-5.4   (or gemini-3-flash)
#
# Reports land in benchmarks/reports/runs/<ts>/ either way.

set -euo pipefail

cd "$(dirname "$0")"

IMAGE="al-bench:latest"
ENV_FILE=".env"

# --- 1. Sanity check .env ---------------------------------------------------
if [ ! -f "${ENV_FILE}" ]; then
    cat >&2 <<EOF
error: ${ENV_FILE} not found at $(pwd)

Copy .env.example to .env and fill in either:
  (--host mode)  LLM_API_KEY / LLM_BASE_URL / LLM_MODEL
  (Docker mode)  ANTHROPIC_AUTH_TOKEN / ANTHROPIC_BASE_URL / ANTHROPIC_DEFAULT_OPUS_MODEL

.env is gitignored — never commit it.
EOF
    exit 1
fi

# --- 2. Parse flags: --host / --build-only / pass remaining args to runner --
HOST_MODE=0
BUILD_ONLY=0
RUN_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --host)       HOST_MODE=1 ;;
        --build-only) BUILD_ONLY=1 ;;
        *)            RUN_ARGS+=("$arg") ;;
    esac
done

# --- 3. Ensure commit0 repos exist on host ----------------------------------
if [ ! -d "thirdparty/commit0_repos/cachetools" ] && [ ! -L "thirdparty/commit0_repos" ]; then
    echo ">>> First run: setting up V1_SUBSET commit0 repos on host ..."
    if ! command -v commit0 >/dev/null 2>&1; then
        echo "error: commit0 not installed on host. Run 'pip install -e thirdparty/commit0' first." >&2
        exit 2
    fi
    PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
    "${PYTHON_BIN}" -m benchmarks.harness --setup-only
fi

# --- 4a. HOST MODE: run directly, no Docker --------------------------------
if [ "${HOST_MODE}" = "1" ]; then
    if [ "${BUILD_ONLY}" = "1" ]; then
        echo ">>> --host + --build-only is a no-op (no image needed in host mode)" >&2
        exit 0
    fi
    echo ">>> Running benchmark on host (no Docker) ..."
    # Pull .env into the current shell so the Python process sees LLM_* etc.
    set -a; source "${ENV_FILE}"; set +a
    # Prefer python3 (macOS default), fall back to python.
    PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
    if [ -z "${PYTHON_BIN}" ]; then
        echo "error: neither python3 nor python found on PATH" >&2
        exit 3
    fi
    "${PYTHON_BIN}" -m benchmarks.harness --real "${RUN_ARGS[@]}"
    echo ">>> Done. Report:"
    ls -1t benchmarks/reports/runs/ 2>/dev/null | head -1
    exit 0
fi

# --- 4b. DOCKER MODE: build image + run inside container --------------------
echo ">>> Building ${IMAGE} ..."
docker build -f Dockerfile.benchmark -t "${IMAGE}" .

if [ "${BUILD_ONLY}" = "1" ]; then
    echo ">>> --build-only — done."
    exit 0
fi

echo ">>> Running benchmark inside ${IMAGE} ..."
docker run --rm \
    --env-file "${ENV_FILE}" \
    -v "$(pwd)/thirdparty/commit0_repos:/workspace/thirdparty/commit0_repos:ro" \
    -v "$(pwd)/benchmarks/reports:/workspace/benchmarks/reports" \
    -v "$(pwd)/benchmarks/skeletons:/workspace/benchmarks/skeletons:ro" \
    "${IMAGE}" \
    --use-claude-code "${RUN_ARGS[@]}"

echo ">>> Done. Report:"
ls -1t benchmarks/reports/runs/ 2>/dev/null | head -1
