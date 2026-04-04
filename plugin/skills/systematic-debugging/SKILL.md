---
name: systematic-debugging
description: "Use when diagnosing a bug, test failure, or unexpected behavior. Systematic root-cause investigation that builds the human's mental model of the system alongside the fix."
---

# Systematic Debugging

## The Iron Law

**No fix without a root cause. No root cause without investigation.**

Guessing at fixes is how you turn one bug into three. And if only you understand
the root cause, the human can't debug the next one.

## The Four Phases

### Phase 1: Form Hypotheses Together

Read the error. Read the relevant code. Read the diary for related concepts.

Then involve the human:
- "What's your read on where this might be breaking?"
- "Have you seen this pattern before in this codebase?"
- "My first instinct is [X] — does that match what you're seeing?"

You're not testing them. You're doing what colleagues do: pooling intuitions
before diving in.

Check the diary for concepts the bug touches. If it shows gaps,
this is where theory-building and debugging become the same activity.

### Phase 2: Build the Mental Model

Walk through the relevant code path:
- "Here's what happens when a request comes in: first X, then Y, then Z"
- "The working case does A → B → C. The broken case diverges at B"

This is you thinking out loud, the way a colleague does when staring at a bug
together. If the human already knows the code path (check the diary), skip to
the divergence point.

### Phase 3: Test Hypotheses

For each hypothesis:
1. **Predict**: Ask the human what they expect. "If it's a race condition,
   what should we see when we add logging here?"
2. **Test**: Run the minimal experiment
3. **Interpret**: Compare prediction to result

The prediction step is the theory-building moment. When they predict correctly,
their model is working. When they predict incorrectly, that's where the model
needs to grow — and the evidence is right there.

### Phase 4: Fix and Record

Once root cause is confirmed:
1. Write the test that reproduces the bug (TDD — test first)
2. Implement the fix
3. Verify the test passes
4. Write a diary entry for the human's understanding of the root cause

## Escalation Rules

- **3+ failed hypotheses**: Step back. Question your assumptions. Re-read from scratch.
- **3+ similar bugs**: Question the architecture. "We keep hitting this pattern —
  is there a structural issue?"
- **Fix works but nobody knows why**: Not done. Keep investigating.

## Anti-Rationalization

If you catch yourself rationalizing why systematic investigation isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "I already know the fix" — if you can't explain the root cause, you know a patch, not a fix.
