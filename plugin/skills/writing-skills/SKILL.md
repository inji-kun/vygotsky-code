---
name: writing-skills
description: "Use when creating or editing Vygotsky skills. Ensures new skills preserve the theory-building posture, use CSO-friendly descriptions, and stay within token budgets."
---

# Writing Skills

## The Rule

**Every skill must preserve Vygotsky's soul: theory-building first, collaborative
posture always, no quizzing, no scoring.**

A skill that makes Claude faster but undermines the human's understanding of
what's happening is a net negative.

## Creating a New Skill

### 1. Baseline Test

Before writing the skill, define what "working" looks like:
- What trigger should activate this skill?
- What behavior should it produce?
- What Vygotsky invariants must it preserve?

### 2. Write the Skill

#### Frontmatter

```yaml
---
name: kebab-case-name
description: "Use when [trigger]. [One sentence on what it does]."
---
```

The description MUST start with "Use when" — this is how Claude discovers skills.
Claude Search Optimization: be specific about the trigger condition.

#### Structure

- **The Rule**: One sentence that captures the core discipline
- **The Process**: Step-by-step, concrete, no ambiguity
- **Anti-Rationalization**: Table of rationalizations and reality checks

#### Token Budget

- Complex skills (workflows, multi-phase): under 500 lines
- Simple skills (single behavior): under 200 lines

### 3. Verify

- Skill loads without errors
- Description triggers on the right prompts
- Behavior matches the baseline test

## Vygotsky Soul Invariants

Any skill that modifies how Claude interacts must preserve:

1. **Theory-building first** — the human's understanding is the primary output
2. **No quizzing** — theory checks sound like a colleague, never a teacher
3. **No scoring** — the diary is narrative, never numeric
4. **Diary integrity** — entries capture what was demonstrated, not grades
5. **Collaborative posture** — "what's your read?" not "can you explain?"

If a skill conflicts with any of these, the invariant wins.

## Customization

Users may want skills that fit their workflow. When adapting:
- Keep the invariants above
- Adjust process steps to match the user's context
- If the user wants to skip theory checks, discuss the trade-off rather than
  silently complying — but ultimately respect their choice

## Anti-Rationalization

If you catch yourself rationalizing why invariant checks aren't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "The description is close enough" — CSO is exact. "Use when" or it won't trigger.
