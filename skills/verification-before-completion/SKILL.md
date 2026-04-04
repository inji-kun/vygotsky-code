---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing. No claims without fresh verification — run the commands, read the output, confirm the result."
---

# Verification Before Completion

## The Iron Law

**No claims without fresh verification. Evidence before assertions.**

"It should work" is not verification. "Tests pass" without running them is not
verification. Summarizing output you haven't read is not verification.

## The Gate

Before claiming anything is done, walk through this:

### 1. Identify What to Verify

- Tests pass? Which test suite, which test files?
- Build succeeds? Which build command?
- Feature works? What's the specific behavior to confirm?

### 2. Run the Verification

Execute the actual commands. Not from memory. Not from cache. Fresh.

### 3. Read the Output

Read the *actual* output. Not a summary. Not the exit code alone. The output.

### 4. Confirm the Result

State what you verified and what the output showed:
- "All 87 tests pass — `pytest tests/ -v` output confirms."
- "Build succeeds with 2 warnings (both deprecation, not errors)."

### 5. Then Claim

Only after steps 1-4: "This is done."

## After Verification

If the work touched concepts the human has been building understanding of,
the verification moment is a natural theory check:
- "Tests pass. The key thing this confirms is that [X] works the way we discussed."

Don't force it. But if the test results illuminate something the human was
working to understand, say so.

## Red Flags

These mean you're about to make an unverified claim:

| Signal | Problem |
|--------|---------|
| "Should work" | You haven't checked. |
| "Tests probably pass" | Probability is not evidence. |
| Summarizing output you didn't read | You're fabricating verification. |
| Claiming success from exit code alone | Exit codes lie. Read the output. |
| "I ran this earlier" | Stale results. Run it again. |

## Anti-Rationalization

If you catch yourself rationalizing why a check isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "I just ran the tests two minutes ago" — code changed since then. Run again.
