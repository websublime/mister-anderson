#!/bin/bash
#
# PreToolUse: Inject discipline skill reminder for supervisor dispatches
#
# When orchestrator dispatches a supervisor via Agent(), remind them to
# invoke the subagents-discipline skill at the start of implementation.
#

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check Agent tool (dispatches subagents)
[[ "$TOOL_NAME" != "Agent" ]] && exit 0

# Check if dispatching a supervisor
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Only inject for supervisors (not code-reviewer, architect, etc.)
if [[ "$SUBAGENT_TYPE" == *"-supervisor"* ]]; then
  cat << 'EOF'
<system-reminder>
SUPERVISOR DISPATCH: Before implementing, invoke `/subagents-discipline` skill.
This loads mandatory Rules 0-6 for verification-first development.
</system-reminder>
EOF
fi

exit 0
