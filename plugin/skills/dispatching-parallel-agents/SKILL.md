---
name: dispatching-parallel-agents
description: "Use when work can be split into independent parallel tracks. Dispatches sub-agents for concurrent execution while ensuring the human maintains strategic awareness of all tracks."
---

# Dispatching Parallel Agents

## The Rule

**The human must understand the shape of the parallel work before it starts,
and the meaning of the results after it finishes.**

Parallel agents are a multiplier. But if the human doesn't know what each agent
is doing or why, you've just multiplied the opacity.

## Before Dispatching

### 1. Identify Independent Domains

Find work that can proceed in parallel without stepping on each other:
- Different files or modules
- Different layers (tests vs implementation vs config)
- Independent features with clean boundaries

### 2. Confirm Strategic Awareness

Present the split and check that the human sees it:
- "So we're sending one agent to handle [X] and another to handle [Y] — does
  that split make sense to you?"
- "These two can run in parallel because [reason]. If you see a dependency I'm
  missing, now's the time."

This is not a quiz. It's what you'd say to a colleague before kicking off
parallel workstreams.

### 3. Write Focused Agent Prompts

Each sub-agent gets:
- **Scope**: Exactly what to build, exact file paths
- **Boundaries**: What NOT to touch (other agent's territory)
- **Context**: Relevant diary concepts and plan state
- **Tests**: What to verify before reporting done

## After Completion

### 1. Walk Through Results

Don't silently integrate. For each agent's output:
- "Agent A built [X]. Here's what it does and why it matters."
- "Agent B built [Y]. This connects to what A built because [reason]."

The walkthrough builds the human's theory of code they didn't watch being written.

### 2. Integration Review

- Check for conflicts between agents' output
- Run the full test suite — not just individual agent tests
- If integration reveals issues, invoke **systematic-debugging**

### 3. Record

- Write a diary entry about the human's understanding of the parallel work
- Note which pieces they engaged with vs accepted passively
- If engagement was uneven, flag the passive domain for a theory check next session

## Anti-Rationalization

If you catch yourself rationalizing why the walkthrough isn't needed, STOP and read
`skills/vygotsky/reference/anti-rationalization.md` before proceeding.

Key trap for this skill: "The split is obvious" — obvious to you. The human needs to see the boundaries.
