# Diary Conventions

## Recording Discipline

**Record whenever you observe something genuinely informative. No fixed quota.**

The diary builds a model of a person across sessions. A reasonable picture emerges
after a handful of sessions — some within-session signals are genuinely strong
(clear demonstration, accurate self-report, revealing mistake), others are noise.
Be wary of overfitting: a single session is a small sample. Hold within-session
observations lightly unless the signal is unusually clear. When uncertain, record
the uncertainty or don't record at all. Let the extant body of diary entries guide
your judgment — if a concept already has rich observations, raise the bar for what's
worth adding.

The diary is Claude's private working memory, not a report card for the developer.
Write entries directly to `~/.vygotsky/diary/{concept-slug}.md`.

## Writing Diary Entries

Append a diary entry after the human demonstrates understanding, struggles with
something, or engages meaningfully. Use the Write tool to append to the concept file.

### Evidence Types

| Type | Signal | When |
|------|--------|------|
| `prediction` | Learning | Human predicted behaviour before seeing it |
| `explanation` | Learning | Human explained concept in own words |
| `connection` | Learning | Linked concepts together or asked a probing question |
| `extension` | Learning | Applied concept to new context or extended it |
| `transfer` | Learning | Connected to external knowledge or different domain |
| `correction` | Learning | Revised own wrong model after seeing evidence |
| `disagreement` | Mastery | Pushed back on Claude's approach with reasoning |
| `directive` | Mastery | Gave technically grounded instruction |
| `design_decision` | Mastery | Made architectural choice with reasoning |
| `gap` | Gap | Revealed missing prerequisite |
| `acknowledgment` | Low | Acknowledged without demonstrating (DEFAULT) |
| `calibration` | Internal | Claude adjusting its own engagement strategy |

### The `calibration` type

Use `calibration` when adjusting engagement strategy mid-session — it's Claude's
private reasoning voice, not an observation about the developer. Use only when a
genuine strategy shift is happening.

Good calibration entry:
> "Three rubber-stamps on DB schema decisions. Feels like overwhelm not disinterest.
> Shifting SP → Sparring. Will surface FK tradeoff explicitly rather than presenting
> a solution. If engagement picks up, move back to SP."

### Good Diary Entries

- **Specific**: "Explained JWT vs session tokens clearly. Chose JWT because the API is stateless."
- **Behavioral**: "Asked about error propagation in promise chains"
- **Linked**: "This connects to [[error-handling]] — they struggled with try/catch in async."
- **Contextual**: "During the webhook handler implementation"
- **Honest about uncertainty**: "May be navigating by intuition — needs more sessions to confirm."

### Bad Diary Entries

- Scores: "7/10 understanding" — never.
- Vague: "Did well" — useless.
- Assumptions: "Probably understands X" — if you didn't observe it, don't write it.
- Overfit: Recording every exchange — the model gets noisier, not richer.
