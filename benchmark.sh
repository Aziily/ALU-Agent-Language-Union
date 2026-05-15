#!/usr/bin/env bash
#
# benchmark.sh — run the commit0 benchmark.
#
# Three modes (pick one flag; default = --docker-real):
#
#   --host           Run directly on host via python -m benchmarks.harness
#                    --real, no Docker. Uses LLM_* env vars from .env. Fast
#                    iteration when you're editing harness code. No
#                    isolation — uses host's python env.
#
#   --docker-real    (DEFAULT) Build al-bench image (16 repos baked in),
#                    run container, hit host's http://host.docker.internal:<port>
#                    via OpenAICompatClient. Picks up LLM_API_KEY / LLM_BASE_URL
#                    / LLM_MODEL from .env. Clean reproducible env, much
#                    faster than --host on big runs (pre-installed repos +
#                    file-revert + parallel-cells).
#
#   --docker-claude  Build al-bench image, run container, use Claude Code
#                    CLI via ANTHROPIC_* env vars. Legacy path; kept for
#                    reproducibility of the Phase 1.H'.F.2 results.
#
# Additional flags:
#   --build-only         Build image, skip run.
#   --no-build           Skip docker build (reuse existing al-bench:latest).
#   --parallel-cells N   Pass through to harness (default 4 in --docker-*
#                        modes, 1 in --host mode).
#
# Everything after recognised flags is forwarded to `python -m benchmarks.harness`.
#
# Examples:
#   ./benchmark.sh --host --k-repeats 1 --project-names cachetools           # quick smoke
#   ./benchmark.sh --docker-real --n-projects 3 --k-repeats 1                # docker smoke
#   ./benchmark.sh --docker-real --n-projects 16 --k-repeats 3 \
#                                --parallel-cells 6                          # full validation
#   ./benchmark.sh --docker-claude --n-projects 5 --k-repeats 5              # legacy

set -euo pipefail
cd "$(dirname "$0")"

IMAGE="al-bench:latest"
ENV_FILE=".env"

# ----- 1. .env sanity check ------------------------------------------------
if [ ! -f "${ENV_FILE}" ]; then
    cat >&2 <<EOF
error: ${ENV_FILE} not found at $(pwd)
Copy .env.example to .env and fill in either:
  (--host / --docker-real)  LLM_API_KEY / LLM_BASE_URL / LLM_MODEL
  (--docker-claude)         ANTHROPIC_AUTH_TOKEN / ANTHROPIC_BASE_URL /
                            ANTHROPIC_DEFAULT_OPUS_MODEL

.env is gitignored — never commit it.
EOF
    exit 1
fi

# ----- 2. Flag parsing -----------------------------------------------------
MODE="docker-real"     # default
BUILD=1
PARALLEL_DEFAULT=4
PARALLEL_USER_SET=0
RUN_ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --host)          MODE="host";           shift ;;
        --docker-real)   MODE="docker-real";    shift ;;
        --docker-claude) MODE="docker-claude";  shift ;;
        --build-only)    MODE="build-only";     shift ;;
        --no-build)      BUILD=0;               shift ;;
        --parallel-cells)
            PARALLEL_USER_SET=1
            RUN_ARGS+=("--parallel-cells" "$2")
            shift 2 ;;
        --)              shift; RUN_ARGS+=("$@"); break ;;
        *)               RUN_ARGS+=("$1");      shift ;;
    esac
done

# ----- 3. Ensure repos exist on host (only needed for --host) -------------
if [ "${MODE}" = "host" ]; then
    if [ ! -d "thirdparty/commit0_repos/cachetools" ]; then
        echo ">>> First run: setting up V1_SUBSET commit0 repos on host ..." >&2
        PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
        "${PYTHON_BIN}" -m benchmarks.harness --setup-only
    fi
fi

# ----- 4. Dispatch ---------------------------------------------------------
case "${MODE}" in
    host)
        echo ">>> Running benchmark on host (no Docker) ..." >&2
        set -a; source "${ENV_FILE}"; set +a
        PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
        if [ -z "${PYTHON_BIN}" ]; then
            echo "error: neither python3 nor python found on PATH" >&2; exit 3
        fi
        # Add --parallel-cells default for big runs if user didn't set one.
        if [ "${PARALLEL_USER_SET}" = "0" ]; then
            RUN_ARGS+=("--parallel-cells" "1")  # host: be conservative; safer
        fi
        "${PYTHON_BIN}" -m benchmarks.harness --real "${RUN_ARGS[@]}"
        ;;

    build-only)
        echo ">>> Building ${IMAGE} ..." >&2
        docker build -f Dockerfile.benchmark -t "${IMAGE}" .
        echo ">>> --build-only — done." >&2
        exit 0
        ;;

    docker-real|docker-claude)
        if [ "${BUILD}" = "1" ]; then
            echo ">>> Building ${IMAGE} ..." >&2
            docker build -f Dockerfile.benchmark -t "${IMAGE}" .
        else
            echo ">>> Skipping build (--no-build); using existing ${IMAGE}" >&2
        fi

        # Default parallelism in docker-* modes
        if [ "${PARALLEL_USER_SET}" = "0" ]; then
            RUN_ARGS+=("--parallel-cells" "${PARALLEL_DEFAULT}")
        fi

        # docker-real: pass --real flag and use OpenAI-compat env.
        # docker-claude: pass --use-claude-code flag and use Anthropic env.
        if [ "${MODE}" = "docker-real" ]; then
            BACKEND_FLAG="--real"
        else
            BACKEND_FLAG="--use-claude-code"
        fi

        # --add-host so the container can reach the host loopback proxy at
        # http://host.docker.internal:<port> (LLM_BASE_URL).
        #
        # If LLM_BASE_URL in .env uses 127.0.0.1 / localhost, we override it
        # to host.docker.internal so the container actually reaches the host's
        # local proxy (the .env value is used as-is for --host mode).
        HOST_BASE_URL="$(grep -E '^LLM_BASE_URL=' "${ENV_FILE}" | cut -d= -f2-)"
        # shellcheck disable=SC2001
        CONTAINER_BASE_URL="$(echo "${HOST_BASE_URL}" | sed -E 's#://(127\.0\.0\.1|localhost)#://host.docker.internal#')"

        echo ">>> Running benchmark inside ${IMAGE} (${BACKEND_FLAG}) ..." >&2
        if [ "${HOST_BASE_URL}" != "${CONTAINER_BASE_URL}" ]; then
            echo ">>> Rewriting LLM_BASE_URL ${HOST_BASE_URL} → ${CONTAINER_BASE_URL} for container" >&2
        fi
        echo ">>> args: ${RUN_ARGS[*]}" >&2
        docker run --rm \
            --env-file "${ENV_FILE}" \
            -e "LLM_BASE_URL=${CONTAINER_BASE_URL}" \
            --add-host=host.docker.internal:host-gateway \
            -v "$(pwd)/benchmarks/reports:/workspace/benchmarks/reports" \
            -v "$(pwd)/benchmarks/skeletons:/workspace/benchmarks/skeletons:ro" \
            "${IMAGE}" \
            "${BACKEND_FLAG}" "${RUN_ARGS[@]}"
        ;;

    *)
        echo "error: unknown mode ${MODE}" >&2; exit 2 ;;
esac

echo ">>> Done. Report:" >&2
ls -1t benchmarks/reports/runs/ 2>/dev/null | head -1
