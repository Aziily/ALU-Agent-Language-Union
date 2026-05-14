#!/usr/bin/env bash
#
# benchmark.sh — run Phase 1.H benchmark inside the Docker container.
#
# Prerequisites (host):
#   1. Docker daemon running
#   2. .env at project root with ANTHROPIC_AUTH_TOKEN / ANTHROPIC_BASE_URL /
#      ANTHROPIC_DEFAULT_OPUS_MODEL set. See .env.example.
#   3. thirdparty/commit0_repos/ populated. The script will call
#      `commit0 setup` on the host the first time if needed (faster than
#      doing it inside Docker because of HuggingFace cache).
#
# Usage:
#   ./benchmark.sh                          # smoke 1 project × k=1
#   ./benchmark.sh --n-projects 5 --k-repeats 5
#   ./benchmark.sh --build-only             # just rebuild the image
#
# Reports land in benchmarks/reports/runs/<ts>/ on the host (bind-mounted).
# Raw LLM transcripts land in raw/ — .gitignored.

set -euo pipefail

cd "$(dirname "$0")"

IMAGE="agentlang-bench:latest"
ENV_FILE=".env"

# --- 1. Sanity check .env ---------------------------------------------------
if [ ! -f "${ENV_FILE}" ]; then
    cat >&2 <<EOF
error: ${ENV_FILE} not found at $(pwd)

Copy .env.example to .env and fill in:
    ANTHROPIC_AUTH_TOKEN=<your traxnode token>
    ANTHROPIC_BASE_URL=https://canvas.aipaibox.com   # or your gateway
    ANTHROPIC_DEFAULT_OPUS_MODEL=gemini-3-flash

.env is gitignored — never commit it.
EOF
    exit 1
fi

# --- 2. Parse --build-only / pass remaining args to runner ------------------
BUILD_ONLY=0
RUN_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --build-only) BUILD_ONLY=1 ;;
        *)            RUN_ARGS+=("$arg") ;;
    esac
done

# --- 3. Build image ---------------------------------------------------------
echo ">>> Building ${IMAGE} ..."
docker build -f Dockerfile.benchmark -t "${IMAGE}" .

if [ "${BUILD_ONLY}" = "1" ]; then
    echo ">>> --build-only — done."
    exit 0
fi

# --- 4. Ensure commit0 repos exist on host (first time only) ----------------
if [ ! -d "thirdparty/commit0_repos/cachetools" ]; then
    echo ">>> First run: setting up V1_SUBSET commit0 repos on host ..."
    if ! command -v commit0 >/dev/null 2>&1; then
        echo "error: commit0 not installed on host. Run 'pip install -e thirdparty/commit0' first." >&2
        exit 2
    fi
    python -m benchmarks.harness --setup-only
fi

# --- 5. Run inside container ------------------------------------------------
# Mount:
#   - .env (env vars come via --env-file)
#   - commit0_repos read-only (skeleton source for each project)
#   - benchmarks/reports read-write (so summary.md / run.json appear on host)
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
