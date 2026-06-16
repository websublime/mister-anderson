#!/bin/bash
#
# SessionStart: Inject awareness of the core-loop skill.
#
# Reminds the orchestrator that the `core-loop` skill exists and WHEN to invoke
# it. This is a conditional nudge, faithful to the skill's own trigger rules —
# not a mandate to run it on every session.
#
# Kept separate from session-start.sh on purpose: that script exits early when
# there is no .beads dir or no `bd` CLI, which would suppress this reminder.
#

cat << 'EOF'
<system-reminder>
A `core-loop` skill is available for high-stakes, multi-stage work. Invoke `/core-loop` when:
  • the user explicitly asks for thorough / systematic / deep work, OR
  • the task objectively spans multiple files, multiple sources, or multiple sessions.
Do NOT invoke it for ordinary multi-step requests that a direct attempt handles fine.
</system-reminder>
EOF

exit 0
