# vibe

The user describes the product; you come back with two or three visual directions they can point at. Use it inside [init.md](init.md)'s Discuss path, or whenever someone says what they are building but not what it should look like.

Showing beats asking. A theme is a small number of decisions — palette, type, shape, density, motion — and a person who cannot answer "what vibe do you want?" in the abstract will answer it in half a second when looking at three options.

## 1. Take the brief, then stop asking

One or two sentences about the product is enough to start. Ask at most one question, and only when the directions would genuinely differ on the answer — usually the scene (who, where, what light) or the target, when `signals` reported it as unclear.

Do not run the five-question interview first. This replaces it.

## 2. Build two or three real directions

**Genuinely different, not three tints of the same idea.** Three blues with different radii is one direction shown three times, and it teaches the user nothing. Pull them apart on the axes that actually change how a screen feels:

| Axis | Pull it apart |
|---|---|
| Palette | a committed hue vs near-neutral with one accent vs dark-first |
| Type | grotesque vs serif display vs a single face across the scale |
| Shape | sharp (0–4) vs soft (12–16) vs pill (999) |
| Density | generous vs compact |
| Elevation | tonal surfaces vs real shadow vs flat with borders |
| Motion | near-static vs one authored moment vs pervasive |

Name each one — "Field notes", "Broadcast", "Quiet utility" — and give it a single line of point of view. A direction you cannot describe in a sentence is not a direction.

**Include one that is a genuine risk.** Three safe options is a safe result, and the whole point of showing rather than asking is that people choose bolder from a picture than from a description.

Honor a pinned brief. If they said "like Linear", one direction is that, done properly — not your correction of it.

## 3. Render it as an artifact

An HTML artifact, not Flutter code. Choosing a direction should take seconds, and a Flutter build does not.

Each direction shows:

- The name and its one-line point of view.
- **The palette as role swatches** with hex values: primary, on-primary, surface, surface-container, on-surface, on-surface-variant, outline, error. Roles, not a rainbow — this is the thing that gets copied into the theme.
- **The type pairing at real sizes**, with the actual face loaded, showing display / title / body / label. Name the fonts and where they come from.
- **Shape and elevation**: the corner radius, and whether depth is tonal or shadowed.
- **One real screen from their product**, mocked at phone width — not a generic card grid. Use their nouns. A screen with their own content is the only thing that shows whether a direction survives contact with the product.
- **Both schemes.** A direction that only works in light is half a direction.

On a TV target, mock at 10-foot instead: 1920×1080 scaled down, body type at 20sp or more, a visible focus state on one tile, and the 5% overscan margin drawn in. A phone-width mock tells a TV project nothing.

## 4. The fidelity rule

**What the artifact shows must be what the app ships.**

`ColorScheme.fromSeed` derives every role from one seed through Material's tonal algorithm. It will not reproduce hand-picked hex values, so an artifact whose swatches came from your own eye and a theme built with a bare `fromSeed` are two different designs, and the user chose the first one.

Pick one and say which:

- **Seed-driven** — choose the seed, generate the roles with `ColorScheme.fromSeed`, and put *those generated values* in the artifact. Accurate, and the theme stays one line.
- **Role-driven** — hand-pick the roles, show them, and ship them with `ColorScheme.fromSeed(...).copyWith(primary: …, surface: …)` or a literal `ColorScheme`. More control, more to maintain.

Never show one and build the other.

## 5. After they pick

They will often take one and pull something from another. That is a good outcome, not indecision — record the result, not the original.

1. Write `DESIGN.md` with the chosen roles, faces, radii and motion character, in the shape [document.md](document.md) prescribes so the `design-system-*` rules can check against it.
2. Build the theme with [theme.md](theme.md).
3. Then the first screen.

**Never**: ship three variations of one direction; use Inter, Roboto or an indigo-to-violet pair as one of the options; mock a generic screen instead of theirs; show a palette the theme will not reproduce; write `DESIGN.md` before they have chosen.
