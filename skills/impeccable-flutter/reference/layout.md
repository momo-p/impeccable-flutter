# layout

Fix spacing, rhythm, alignment and structure.

Start from `detect --only monotonous-spacing,cramped-padding,nested-cards,icon-tile-stack,unbounded-list,kicker-above-heading`.

## Rhythm

A spacing scale, not a habit. Pick steps, 4, 8, 12, 16, 24, 32, 48, 64, and use them to mean something:

- Tight inside a group (4-12), generous between groups (32-64).
- More space above a heading than below it. The heading belongs to what follows.
- If nearly every gap in a file is the same number, no rhythm was designed. That is what `monotonous-spacing` fires on.

`EdgeInsets.symmetric(horizontal:, vertical:)` says more than `EdgeInsets.all`. Screen edges want 16-24 on a phone, more as width grows.

## Structure

- `Card` is the lazy container. A screen that is a `Column` of identical cards has no hierarchy, flatten it and let spacing and type do the grouping. A `Card` inside a `Card` is always wrong.
- `Column` plus `Expanded` expresses intent; a hard `height` on a layout box usually hides a constraint problem.
- A `ListView` inside a `Column` throws unless it is in `Expanded`/`Flexible` or carries `shrinkWrap: true`. `shrinkWrap` builds every child, so it is for short lists only.
- `Spacer` for pushing things apart in a flex; `SizedBox` for a measured gap. They are not interchangeable.
- Use `ListView.separated` rather than interleaving `SizedBox` between children by hand.

## Alignment

- Optical alignment beats mathematical. Icons next to text usually need a pixel or two of adjustment; `crossAxisAlignment: CrossAxisAlignment.start` plus a small top pad on the icon reads better than centering.
- One text alignment per screen region. Centered body copy under a left-aligned heading reads as an accident.
- `IntrinsicHeight` and `IntrinsicWidth` are expensive and usually a sign the layout wants restructuring.

## Density

Density follows the mode. A settings list is dense on purpose; a paywall is not. Check the real content, at the real length, in the smallest device class you ship to.
