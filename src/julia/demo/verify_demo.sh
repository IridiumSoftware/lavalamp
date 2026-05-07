#!/bin/bash
# verify_demo.sh — run the LavaLamp demo and assert the output matches
# the canonical reference at expected_output.txt.
#
# Cross-machine reproducibility check. Wall-clock timings are normalized
# to "<TIMING>" before diffing (they vary by machine); everything else
# (residue/σ ratios, λ values, state transitions, accept/reject
# decisions) is deterministic per seed and Julia version and is asserted
# by exact match.
#
# Usage (run from repo root):
#
#     bash src/julia/demo/verify_demo.sh
#
# Exit codes:
#   0  — actual matches expected (cross-machine reproducible)
#   1  — actual differs from expected (numerical drift, missing lines,
#         or unexpected lines — investigate before treating as a regression)

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
DEMO_FILE="${REPO_ROOT}/src/julia/demo/lavalamp_demo.jl"
EXPECTED="${REPO_ROOT}/src/julia/demo/expected_output.txt"
ACTUAL="$(mktemp -t lavalamp_demo_actual.XXXXXX)"

# Normalization regex — turns wall-clock timings into "<TIMING>" so the
# diff is cross-machine deterministic. Matches three patterns:
#   1. "in 3.89 s." / "in 0.18 s" — verify_full / register progress lines
#   2. "registered in 3.89 s" — register-envelope completion
#   3. "Wall-clock — <label> : 3.89 s" — summary lines
NORMALIZE_SED='s/in [0-9]+\.[0-9]+ s/in <TIMING> s/g; s/registered in [0-9]+\.[0-9]+ s/registered in <TIMING> s/g; s/Wall-clock — ([^:]+) : [0-9]+\.[0-9]+ s/Wall-clock — \1 : <TIMING> s/g'

# Run the demo (capture stdout + stderr) and normalize.
if ! julia --project="${REPO_ROOT}/src/julia" "${DEMO_FILE}" 2>&1 | sed -E "${NORMALIZE_SED}" > "${ACTUAL}"; then
    echo "❌ Demo failed to run."
    rm -f "${ACTUAL}"
    exit 1
fi

# Diff against expected.
if diff -u "${EXPECTED}" "${ACTUAL}"; then
    echo "✅ Demo output matches expected_output.txt (cross-machine reproducible)."
    rm -f "${ACTUAL}"
    exit 0
else
    echo ""
    echo "❌ Demo output differs from expected_output.txt"
    echo "   Actual (normalized) output saved at: ${ACTUAL}"
    echo ""
    echo "   If this divergence is intentional (e.g. Julia or"
    echo "   DifferentialEquations.jl version bump shifted numerical"
    echo "   values within tolerance), regenerate expected_output.txt:"
    echo ""
    echo "       julia --project=src/julia src/julia/demo/lavalamp_demo.jl 2>&1 \\"
    echo "         | sed -E '${NORMALIZE_SED}' > src/julia/demo/expected_output.txt"
    echo ""
    exit 1
fi
