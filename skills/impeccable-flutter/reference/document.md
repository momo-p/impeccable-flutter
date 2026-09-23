# document

Write `DESIGN.md` from the code that exists. This captures the incumbent visual world so later commands can preserve it deliberately rather than drift away from it by accident.

A missing `DESIGN.md` does not make a project greenfield. The theme and the widgets are the design; this reads them back.

## 1. Read the theme first

`ThemeData`, `ColorScheme`, `TextTheme` and the component themes are the intended system. Record:

- The seed color if `fromSeed` is used, and every role overridden away from it.
- Whether a dark scheme exists and whether it was designed or derived.
- The type roles actually defined, with size, height and letter spacing.
- Component themes set: card, buttons, input decoration, app bar, dividers.
- The font family and whether it is bundled or fetched.

## 2. Then read what the screens actually do

The theme is the intent; the widgets are the truth. Run the detector to find where they diverge:

```bash
impeccable-flutter detect lib --only hardcoded-color,hardcoded-text-style
```

A color used in fourteen places and defined nowhere is part of the real system. Record it as such, and note that it is undeclared.

## 3. Write it

The detector reads this document back: the four `design-system-*` rules check code against the values recorded here. The parse is forgiving and scans for value-shaped tokens rather than a schema, but it only finds what is actually written down. A color you describe as "the green" and never give a hex for cannot be checked.

Keep values on a line with their label — `font size:`, `corner radius:`, a table row with a hex — and the parse picks them up.

```markdown
# DESIGN.md

## Visual world
One paragraph: what this app looks like and what that is trying to say.

## Color
| Role | Value |
|---|---|
| primary | #1B7F5C |
| surface | #FBFAF8 |
| onSurface | #14171A |

The dark scheme's status, and any color living outside the theme, with the file.

## Type
Font: Söhne
Display font: Fraunces

Type ramp — font size: 36, 24, 18, 16, 13

Where screens depart from the roles.

## Spacing and shape
Spacing steps: 4, 8, 12, 16, 24, 32, 48
Corner radius: 4, 8, 12

Elevation approach: tonal surfaces, or shadow.

## Components
The recurring widgets that carry the identity, and where they live.

## Motion
Transition patterns in use, curves, durations.

## Known drift
Where the code disagrees with the theme. Not a to-do list — a record of
what is true today.
```

## Rules

- Describe what is there, not what should be. Recommendations belong in `audit` and `critique`.
- Cite files. A claim about the design system that names no file is a guess.
- Do not invent a rationale nobody wrote down. "Undocumented" is an honest entry.
- Where the code contradicts itself, record both and say which is more common.
