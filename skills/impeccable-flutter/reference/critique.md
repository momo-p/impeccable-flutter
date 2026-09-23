# critique

A UX and visual review. Not a code audit — [audit.md](audit.md) is that. The question is whether the screen has a point of view and whether a user can act on it.

## 1. The design read

Before judging anything, say what the screen is trying to be, in one line:

> Reading this as: **\<screen kind>** for **\<audience>**, in a **\<vibe>** language, on **\<platform>**.

Examples: *"Reading this as: a settings screen for existing users, in a quiet utility language, on Android-first Material 3."* · *"Reading this as: a paywall for trial users, in a premium consumer language, adaptive across both platforms."*

Judge against that read, not against your own taste. If the read genuinely diverges, ask exactly one question. If you can infer it, do not ask.

This framing follows [taste-skill](https://github.com/Leonxlnx/taste-skill); the dials below are its three, mapped onto Flutter.

## 2. The dials

| Dial | 1 | 10 | Expressed in Flutter as |
|---|---|---|---|
| `VARIANCE` | perfect symmetry | asymmetric, art-directed | how far layout departs from a uniform `Column` of equal cards |
| `MOTION` | static | cinematic | how much of `package:animations` the screen earns |
| `DENSITY` | airy | packed | vertical rhythm and how much fits in a viewport |

Baselines by mode: **Operate** 4 / 4 / 6 · **Read** 5 / 3 / 4 · **Persuade** 7 / 6 / 4 · **Experience** 8 / 7 / 3.

App screens sit lower on VARIANCE than a landing page and higher on DENSITY. A settings screen at VARIANCE 9 is a broken settings screen. Set the dials from the read, then say whether the screen hits them.

## 3. Heuristic scoring

Score 0–4 each.

- **Hierarchy.** Does the eye land on the one thing that matters first? Is there a real type scale, or three sizes within four pixels of each other?
- **Clarity.** Can a first-time user say what this screen is for within seconds? Do controls name their action?
- **Cognitive load.** How many decisions is the user holding? What could be defaulted, deferred, or removed?
- **Information architecture.** Is the grouping the user's model or the database's? Does navigation depth match the task?
- **Emotional resonance.** Does the screen feel like it belongs to this product, or to the framework? Would anyone recognize it with the logo removed?
- **Point of view.** Was anything chosen? Name the decision. If you cannot, that is the finding.

## 4. The honest verdict

Lead with it. Is this the default app, a ported website, or a designed screen? Name specifics: which widget, which line. Generic praise helps nobody.

Then: the three changes with the largest effect, in order, each pointing at the command that does it.

**Never**: soften the verdict to be pleasant; critique the brief instead of the execution; recommend a redesign when a refinement was asked for; list every small thing and bury the one that matters.
