#!/bin/bash
#
# Stop (subagent frontmatter, auto-converted to SubagentStop): verify that the
# subagent set the expected state dimension on its bead before completing.
#
# Enforced agents MUST call `bd set-state <bead_id> <dim>=<value>` as part of
# their workflow. This hook checks that the dimension has a non-empty value.
# Missing state → exit 2 (blocks the orchestrator so it can react).
#
# The bead ID is recovered from `bd kv` using the pending entry written by the
# paired PreToolUse (stamp-pending.sh).
#

INPUT=$(cat)

AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')

[[ -z "$AGENT_ID" ]] && exit 0

# Map subagent type → expected state dimension.
case "$AGENT_TYPE" in
  code-reviewer) DIM=review ;;
  qa-gate)       DIM=qa ;;
  *-supervisor)  DIM=impl ;;
  *)
    # Unknown agent_type — not an enforced role. Silent pass.
    exit 0
    ;;
esac

PENDING=$(bd kv get "pending.${AGENT_ID}" 2>/dev/null)

if [[ -z "$PENDING" ]]; then
  # No pending entry: the subagent never ran `bd show <id>`, so we have no
  # bead to verify against. Warn but don't block — this can happen in legit
  # flows (e.g. reviewer aborted early before reading the bead).
  echo "verify-state: no pending entry for agent_id=${AGENT_ID} (${AGENT_TYPE}) — skipping enforcement" >&2
  exit 0
fi

BEAD_ID="${PENDING%%:*}"

STATE=$(bd state "$BEAD_ID" "$DIM" 2>/dev/null)

if [[ -n "$STATE" ]]; then
  # Success: dimension set. Clean up pending entry.
  bd kv clear "pending.${AGENT_ID}" >/dev/null 2>&1
  exit 0
fi

# Failure: enforced agent finished without setting its state dimension.
cat >&2 <<EOF
ENFORCEMENT FAILURE: ${AGENT_TYPE} did not set '${DIM}' state on bead ${BEAD_ID}.

Expected: bd set-state ${BEAD_ID} ${DIM}=<value> --reason "..."

The orchestrator should re-dispatch ${AGENT_TYPE} or surface this as a workflow error.
EOF
exit 2
