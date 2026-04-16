#!/bin/bash
#
# PreToolUse (Bash matcher, subagent frontmatter): stamp pending enforcement entry
#
# When an enforced subagent (code-reviewer, qa-gate, *-supervisor) runs its
# first `bd show <id>` call, capture the bead ID and persist it in bd's KV
# store keyed by the subagent's unique agent_id. The paired Stop hook reads
# this entry to know which bead to verify state against.
#
# Idempotent: only writes on first match; subsequent Bash calls are no-ops.
#

INPUT=$(cat)

AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Require agent_id (we're inside a subagent) and a command to inspect.
[[ -z "$AGENT_ID" || -z "$CMD" ]] && exit 0

# Already stamped for this agent invocation? Skip.
bd kv get "pending.${AGENT_ID}" >/dev/null 2>&1 && exit 0

# Extract first `bd show <id>` occurrence. If the subagent hasn't run it yet,
# this Bash call is unrelated — exit silently and wait for the next one.
BEAD_ID=$(echo "$CMD" | grep -oE 'bd show [A-Za-z0-9_-]+' | head -1 | awk '{print $3}')
[[ -z "$BEAD_ID" ]] && exit 0

# Persist pending entry. Format: "<bead_id>:<agent_type>"
bd kv set "pending.${AGENT_ID}" "${BEAD_ID}:${AGENT_TYPE}" >/dev/null 2>&1

exit 0
