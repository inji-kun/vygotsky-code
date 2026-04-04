---
name: finishing-a-development-branch
description: "Use when implementation is complete and all tests pass. Guides the human through merge strategy options with enough context to make an informed choice."
---

# Finishing a Development Branch

## The Rule

**The human chooses the merge strategy. You make sure they understand the options.**

Don't assume they know the difference between merge and rebase. Don't assume they
don't. Check the diary and calibrate.

## Pre-Finish Checklist

Before presenting options:

1. **All tests pass** — invoke `verification-before-completion` if not already done
2. **No uncommitted changes** — `git status` is clean
3. **Determine the base branch** — usually `main`, confirm with the human
4. **Check for upstream changes** — `git fetch` and note if base has moved

## Present Options

Four paths. Present all four with enough context for the human to choose:

### 1. Merge Commit

```
git checkout main && git merge feature-branch
```

Creates a merge commit. History shows the branch existed. Good when the branch
history tells a story worth preserving.

### 2. Pull Request

```
git push -u origin feature-branch
gh pr create
```

Code review before merge. Good when others need to see the changes, or when
you want a record of the discussion.

### 3. Rebase and Fast-Forward

```
git rebase main && git checkout main && git merge --ff-only feature-branch
```

Linear history. Looks like the changes were made directly on main. Good when
the branch was small and the intermediate commits aren't meaningful.

### 4. Discard

Delete the branch without merging. **Requires the human to articulate why** —
not just "yes, delete it." And type the branch name to confirm.

## After Completion

The finish point is a natural moment for a diary entry — it's a session
boundary where you can note what the human built and what they understood about it.

If you're cleaning up a worktree, invoke `using-git-worktrees` for the cleanup.

## Anti-Rationalization

If you catch yourself rationalizing why presenting options isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "Just merge it, they said they're done" — done with code doesn't mean done choosing strategy.
