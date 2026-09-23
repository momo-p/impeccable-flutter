# init

One-time setup. Capture durable product truth in `PRODUCT.md`, so later commands know who this is for without confusing that with how it currently looks.

Ask only about material gaps. Read the code first: `pubspec.yaml`, the route table, the screens, existing docs. Most of this is inferable, and asking about what you could have read wastes the user's time.

## What PRODUCT.md holds

Durable facts that survive a redesign:

- **What the app does**, in one sentence, in the product's own words.
- **Who uses it**, and what they know when they arrive.
- **The operating context**: on the move or at a desk, one-handed, ambient light, connectivity, how long a session lasts. This picks light or dark, density, and tap target generosity more than taste does.
- **Platforms and device classes shipped.** Android, iOS, both; phone only or tablet too; the oldest device that matters.
- **Constraints**: regulatory, accessibility commitments, brand assets that already exist, performance floors, offline requirements.
- **Voice**: how the product talks. Two or three real examples from existing copy.

## What it does not hold

Visual direction. That is per-surface and lives in `DESIGN.md` ([document.md](document.md)). Keeping them separate is what lets a redesign replace the look without losing the product.

## After writing it

Run the detector over `lib` and report what the project already trips. If the theme layer is thin, recommend [theme.md](theme.md) first — most other commands have little to work with until it exists.
