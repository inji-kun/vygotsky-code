---
name: test-driven-development
description: "Use when implementing any feature or bugfix. Red-green-refactor with theory-building: the human understands what each test proves, not just that it passes."
---

# Test-Driven Development

## The Iron Law

**No production code without a failing test first.**

TDD isn't just about catching bugs. Each test is a statement about what the code
should do. If the human doesn't understand *what* the test is checking, passing
tests are just green lights they can't interpret.

## The Cycle

### RED: Write the Failing Test

Before writing the test, one sentence on what it verifies and why it matters:
- "This test checks that expired tokens get rejected — right now they silently pass through."

Not a lecture. Just the same thing you'd say to a colleague before writing the test.

Write the test. Run it. Confirm it fails for the right reason.

### GREEN: Make It Pass

Write the minimum code to pass the test. No more.

If the implementation touches a concept the diary flags as new territory, say what
the code does in plain terms: "This adds a timestamp check before the token lookup."

### REFACTOR: Clean Up

Refactor with tests green. If refactoring changes the *shape* of the solution
(not just the style), mention why: "Extracting this because the validation logic
will need to run in two places."

## When to Check In

- **New concept**: If the test covers something the human hasn't worked with before,
  explain what the test proves after GREEN.
- **Surprising failure**: If RED fails for an unexpected reason, that's a theory-building
  moment. "Interesting — I expected it to fail on X, but it's failing on Y. That
  tells us something about how Z works."
- **Multiple cycles**: After 3+ cycles, brief status: "We've covered A, B, and C.
  The main gap left is D."

## Anti-Rationalization

If you catch yourself rationalizing why a test isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "This is too simple to need a test" — simple tests document assumptions. Write it.
