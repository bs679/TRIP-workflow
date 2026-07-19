#!/usr/bin/env bash
# Shared paths, key derivation, and prompt-loading helpers for the
# codex-plan-review and codex-code-review skills. Source-only.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# STATE_DIR can be overridden by the caller (e.g., codex-code-review
# exports its own state path before invoking the shared scripts).
# Default falls back to the script's own skill directory.
: "${STATE_DIR:=$SKILL_DIR/state}"
export STATE_DIR
mkdir -p "$STATE_DIR"

# Model/effort per flow (single source of truth for all codex skills):
# implementation runs Luna, reviews (plan + code) run Sol.
# Adjust these defaults to your preferred models.
#
# Cost tiers: the orchestrator exports CODEX_TIER=simple|standard|complex
# per delegated batch/review so frontier compute is only spent where it
# pays. Unset CODEX_TIER = complex (the historical default).
#   simple   -> light model (CODEX_MODEL_LIGHT, if set) at medium effort
#   standard -> flow model at high effort
#   complex  -> flow model at xhigh effort
# CODEX_MODEL / CODEX_EFFORT remain absolute per-run overrides, and
# CODEX_MODEL_LIGHT names your provider's cheap coding model once you
# know it (falls back to the flow model — you still save on effort).
case "$STATE_DIR" in
    *codex-implement*) FLOW_MODEL="gpt-5.6-luna" ;;
    *)                 FLOW_MODEL="gpt-5.6-sol" ;;
esac
case "${CODEX_TIER:-complex}" in
    simple)   TIER_EFFORT="medium"; FLOW_MODEL="${CODEX_MODEL_LIGHT:-$FLOW_MODEL}" ;;
    standard) TIER_EFFORT="high" ;;
    complex)  TIER_EFFORT="xhigh" ;;
    *)
        echo "warning: unknown CODEX_TIER='$CODEX_TIER', treating as complex" >&2
        TIER_EFFORT="xhigh" ;;
esac
CODEX_MODEL="${CODEX_MODEL:-$FLOW_MODEL}"
CODEX_EFFORT="${CODEX_EFFORT:-$TIER_EFFORT}"
export CODEX_MODEL CODEX_EFFORT

# Derive a per-target key from a path-like string. For real paths we
# resolve to absolute; for non-path targets (branch names, commit
# ranges) we sanitize in place. Replace '/' with '__'; force any other
# non-portable characters to '_'.
target_key() {
    local target="$1"
    if [ -e "$target" ]; then
        local abs
        abs="$(realpath -- "$target" 2>/dev/null || readlink -f -- "$target")"
        if [ -z "$abs" ]; then
            echo "error: cannot resolve target path: $target" >&2
            return 1
        fi
        printf '%s' "$abs" | sed 's|^/||; s|/|__|g'
    else
        printf '%s' "$target" | sed 's|^/||; s|/|__|g; s|[^A-Za-z0-9._-]|_|g'
    fi
}

# Backwards-compatible alias used by older script call sites.
plan_key() { target_key "$@"; }

thread_file() {
    printf '%s/%s.thread' "$STATE_DIR" "$(target_key "$1")"
}

review_file() {
    printf '%s/%s.review.txt' "$STATE_DIR" "$(target_key "$1")"
}

events_file() {
    printf '%s/%s.events.ndjson' "$STATE_DIR" "$(target_key "$1")"
}

# Load a prompt template from $1 and substitute {{TARGET}} and
# {{EXTRA_PROMPT}} placeholders with the values of the $TARGET and
# $EXTRA_PROMPT environment variables. Other text passes through
# verbatim — no surprise expansion of unrelated $VAR sequences.
# Writes the substituted prompt to stdout.
load_prompt() {
    local tpl="$1"
    if [ ! -f "$tpl" ]; then
        echo "error: prompt template not found: $tpl" >&2
        return 1
    fi
    awk -v target="${TARGET-}" -v extra="${EXTRA_PROMPT-}" -v notes="${IMPLEMENTER_NOTES-}" '
        {
            gsub(/\{\{TARGET\}\}/, target)
            gsub(/\{\{EXTRA_PROMPT\}\}/, extra)
            gsub(/\{\{IMPLEMENTER_NOTES\}\}/, notes)
            print
        }
    ' "$tpl"
}
