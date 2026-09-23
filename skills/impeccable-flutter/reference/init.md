# init

The entry point for a project. Run it once, at the start.

## 1. Look before asking

```bash
impeccable-flutter signals            # or: signals <path> --json
```

Everything it reports is a fact on disk, and asking about any of it wastes the user's time. In particular: an Android TV launcher intent in the manifest means the target is `tv`, so that question is already answered.

Read `pubspec.yaml`, the route table and the existing screens too. Most of what a setup flow traditionally asks for can be inferred.

## 2. Offer the two paths

Ask once, in one line, and make the default obvious:

> This looks like **\<inferred description>**. Want to go straight to building, or shape the design direction first?

- **Plain** — the user wants to build. Record only what cannot be inferred (target, if `signals` reported it as unclear), write a minimal `PRODUCT.md`, and get out of the way. No design interview. If they later ask for design work, the direction gets settled then.
- **Discuss** — the user wants a design direction before code. Continue to step 3.

Take the answer from what they say, not from a form. "Just build it", "plain", or a concrete feature request is Plain. "Help me think about it" or a vague goal is Discuss. **If the request already contains a clear brief, that is Plain with the brief attached — do not interview someone who has already told you what they want.**

## 3. Plain

Write `PRODUCT.md` with what is known and mark the rest unknown. An honest gap beats an invented answer.

```markdown
# PRODUCT.md

## What it does
One sentence, in the product's own words.

## Who uses it
Audience, and what they know on arrival.

## Target
phone · tablet · tv · web, and the oldest device that matters.

## Operating context
Where, how long, one-handed or not, connectivity. This picks light or dark,
density and tap-target generosity more than taste does.

## Constraints
Accessibility commitments, brand assets that exist, performance floors,
offline requirements, regulatory limits.

## Voice
Two or three real lines of existing copy.

## Unknown
What was not established, so nobody mistakes a guess for a decision.
```

Then say which command is next — usually `theme` on a greenfield project, `document` on an existing one — and stop.

## 4. Discuss

A conversation, not a questionnaire. Ask about one thing at a time and let the answers move the next question.

Work through, in this order:

1. **The scene.** Who is using this, where, on what, under what light, for how long. This decides more than taste does. A TV app in a living room at night and a phone app on a train are different products before a single color is chosen.
2. **The mode.** Operate, Read, Persuade or Experience for the first real surface. See SKILL.md.
3. **References and anti-references.** Products they admire, and — more useful — one they do not want to resemble. Ask for the reason, not just the name.
4. **The one thing.** If a user remembers a single quality of this app, what is it? The answer becomes the tiebreaker for every later decision.
5. **Constraints that override taste.** Accessibility, regulation, an existing brand, a performance floor.

End the conversation with a **design read**, one line, and get agreement before writing anything:

> Reading this as: a **\<kind>** for **\<audience>**, in a **\<vibe>** language, on **\<target>**, leaning **\<direction>**.

Then write `PRODUCT.md` as in step 3, and record the visual direction separately in `DESIGN.md` via [document.md](document.md) once something exists to document. Keeping them apart is what lets a redesign replace the look without losing the product.

## 5. Either way

Report what `signals` found and name the next command. On an existing codebase with findings, mention [detect.md](detect.md)'s baseline so adoption does not start with a wall of output.

**Never**: run the interview when the user already gave a brief; ask about something `signals` already answered; invent a rationale nobody stated; write `DESIGN.md` on a greenfield project before anything is designed.
