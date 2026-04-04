---
name: executing-plans
description: "Use when implementing a plan produced by writing-plans. Executes tasks in batches with theory-building at checkpoints. Reads plan files directly — no MCP planning tools."
---

# Executing Plans

## The Rule

**Execute in batches. Build theory at the boundaries.**

Batch execution is efficient. But efficiency without understanding produces code
nobody can maintain. The batch boundary is where you pause, share what was built,
and make sure the human's theory kept up.

## Execution Flow

### Before Each Batch

1. Read `.claude/plans/index.json` to orient — find current active node
2. Read the active plan file (get the goal, steps, theory-check points)
3. Read parent plan file for breadcrumb context if needed
4. Note which concepts this batch touches — check diary if flagged as new territory

### During Execution

- Execute tasks sequentially within the batch
- Stop immediately if blocked — don't guess, ask
- Run tests after each implementation task
- **Never commit to main without explicit consent**
- Write the pre-diff preamble before every code change (see SKILL.md)

### At Each Batch Boundary

Present a batch report:

```
## Batch N Complete

**Built:** [what was implemented]
**Key decisions:** [any choices made during implementation]
**Tests:** [pass/fail status]
**What this means:** [1-2 sentences connecting code to the broader design]
```

The "what this means" section is the theory-building moment.

### After Batch Report

Update the plan file: mark completed steps, note any discoveries.
Update `index.json`: set completed nodes to `completed`.

If a discovery affects other branches: log in `## Discoveries`, update affected
plan files, set their status to `needs-revision` in index.json.

### Theory Checks Between Batches

If the plan has a theory-check annotation or the diary flagged a concept:

- "Before we continue — here's what we just built and what it means for [concept].
  Does that match your mental model, or should we walk through it?"

If the human engages genuinely: write a diary entry. Continue.

If the human is passive (3+ rubber stamps): recalibrate quadrant from the live
conversation, make the next theory check more concrete, consider a `calibration`
diary entry if adjusting strategy.

## Batch Sizing

- **Default**: 3-5 tasks per batch
- **New territory** (no diary entries): 1-2 tasks, then check
- **Extension mode**: 5-8 tasks, light reports
- **Brake pedal mode**: 1 task at a time, theory check after each

## When Things Go Wrong

- **Test failure**: Stop the batch. Diagnose before continuing.
- **3+ consecutive failures**: Question architecture, not just implementation.
- **Blocked on a decision**: Present options with trade-offs and ask.
- **Scope creep discovered**: Log in `## Discoveries`, invoke **writing-plans** to
  create child tasks rather than expanding the current task in place.

## Completion

When all tasks are done, invoke **finishing-a-development-branch**.
