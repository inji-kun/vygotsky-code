---
name: brainstorming
description: "Use when the user explicitly asks to brainstorm, explore design options, or discuss architecture before coding. Not for straightforward implementation requests."
---

# Brainstorming

## The Rule

**No code until the design is presented and the human has engaged with it.**

Not "presented and approved." Presented and *engaged with*. If they say "looks good"
without engaging with the trade-offs, you haven't finished brainstorming — you've
just gotten a rubber stamp.

## The Process

### 1. Build Shared Understanding of the Problem Space

Don't jump to solutions. First, make sure you and the human are looking at the same
problem. Read the relevant code. Read the diary for related concepts.

Ask the kind of questions a colleague asks when they sit down next to you:
- "What's the actual problem we're solving here?"
- "What have you already tried or considered?"
- "What constraints are we working within?"

**Do NOT** run through a checklist. Have a conversation. If you already know the
answer from the diary, don't re-ask — build on what's established.

### 2. Explore the Design Space Together

Surface at least two viable approaches. For each one:
- What it gives you
- What it costs you
- Where it gets tricky

The human should be thinking about these trade-offs, not just picking from a menu.
Ask: "Which of these trade-offs matters more for this project?" or "Where do you
think we'll feel the pain first?"

### 3. Present the Design

Once you've converged, write up the design clearly:
- **Approach**: What we're building and why this shape
- **Key decisions**: The trade-offs we made and why
- **Risks**: What could go wrong and how we'd know

Present it as a proposal, not a decree. The human should be able to push back on
any part of it.

### 4. Confirm Engagement, Not Just Approval

If the human rubber-stamps ("looks good", "sure", "go ahead") without engaging
with the substance:
- Pick the most consequential trade-off and make it concrete
- "Just to make sure we're aligned — we're choosing X over Y, which means Z. That
  feel right for this use case?"

This is not a quiz. It's the kind of thing you'd say to a colleague before investing
a week of work.

### 5. Record and Transition

After genuine engagement:
- Write a diary entry for what the human demonstrated understanding of
- Invoke the **writing-plans** skill to translate the design into a recursive
  file-based plan tree — decomposing as deep as the problem requires

## Anti-Rationalization

If you catch yourself rationalizing why brainstorming isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "The design is obvious" — if it's obvious, articulating it takes 30 seconds. If not, you just saved hours.
