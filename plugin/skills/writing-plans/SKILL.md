---
name: writing-plans
description: "Use when translating a design into an implementation plan. Produces a recursive file-based plan tree with bite-sized tasks, theory-check points, and cross-cutting discovery tracking."
---

# Writing Plans

## The Rule

**Every plan is a map of both the code to be built and the theory to be built.**

A plan that only tracks files and functions is half a plan. The other half is: what
does the human need to understand at each step, and where are the natural moments
to check?

## Plan Storage

Plans live in `.claude/plans/` — markdown files + a JSON index. They're git-tracked,
human-readable, and survive compaction. No MCP tools needed.

### index.json

Flat skeleton of all nodes. Compact — titles, statuses, parent IDs only.

```json
{
  "01":       {"t": "Root goal",        "s": "active",   "p": null},
  "01-01":    {"t": "Sub-task A",       "s": "planned",  "p": "01"},
  "01-01-01": {"t": "Leaf task",        "s": "planned",  "p": "01-01"}
}
```

Status values: `planned` | `active` | `completed` | `blocked` | `needs-revision`

### Plan file format

Each node gets a `.md` file named after its ID:

```markdown
# [Task Name]
**ID:** 01-01
**Breadcrumb:** Root goal → Sub-task A
**Status:** planned
**Children:** 01-01-01, 01-01-02

## Goal
[What this task achieves]

## Steps
[Concrete steps — exact file paths, function signatures, TDD-shaped where possible]

## Theory-Check Points
--- theory check recommended if [[concept]] is new territory ---

## Discoveries
[Cross-cutting findings that affect other branches — logged here when found]

## Notes from other branches
[Findings from sibling/cousin tasks that affect this one]
```

## Recursion

Decompose until tasks are 2-5 minutes of work. There's no depth limit — go as
deep as the problem requires (depth 4-5 is common for complex features).

When to recurse: a step is bigger than 5 minutes, crosses an abstraction boundary,
or involves a concept the diary flags as new territory.

ID convention: `01` → `01-01` → `01-01-01` → `01-01-01-01`. Breadcrumb in each
file gives navigation context without loading the whole tree.

## Cross-Cutting Updates

When work at one leaf reveals implications for other branches:

1. Log the discovery in the current file's `## Discoveries` section
2. Update affected files with a `## Notes from other branches` entry
3. Set affected nodes to `needs-revision` in index.json
4. Claude reads the index skeleton (already in context) to identify affected branches,
   loads only those files, edits them

## Writing the Plan

1. Read `index.json` if it exists — orient to existing plan state
2. Identify the top-level tasks and decompose recursively
3. Create `.md` files and update `index.json` for each node
4. Present the plan tree to the human
5. Wait for their input — they may reorder, cut, or add tasks
6. After agreement, invoke the **executing-plans** skill

## Theory-Check Points

At natural boundaries — abstraction crossings, new concepts, batch-level handoffs:

```
--- theory check recommended if [[concept]] is new territory ---
```

Not gates. Reminders. During execution, read the diary. If the human has demonstrated
understanding, skip it. If not, pause and check in.

## Anti-Rationalization

If you catch yourself rationalizing why planning isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "Just one big task, it's simpler" — a 20-minute task with no checkpoints is 20 minutes of silent accumulation.
