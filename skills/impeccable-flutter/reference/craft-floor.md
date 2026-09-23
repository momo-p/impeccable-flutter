# Craft floor

Load after the direction is settled, and build without announcing the checklist. A pinned brief or the committed theme overrides anything here; your own habit does not.

## Verify

Checks on the built result, not on intentions. Run them together in one pass.

- **Contrast:** body text ≥4.5:1 against its actual surface, large text ≥3:1, in both schemes. On a colored surface, tint the secondary text from that hue, never drop to gray.
- **Depth:** elevation comes from `surfaceTint` and tonal levels, or a shadow with a real offset and soft blur. A zero-offset colored shadow is a glow, not depth.
- **Spacing:** tight groups, generous separation, more space above a heading than below it. If nearly every gap is the same number, no rhythm was designed.
- **Type:** a scale with obvious steps, body measure that does not run edge to edge on a tablet, tracking floor -0.04em. Run the real copy at 200% text scale and fix what clips.
- **Motion:** one authored moment. Exponential ease-out from an already-visible default.
- **States:** loading, empty, error, offline, disabled, plus real content and working controls.
- **Platform surfaces you did not draw:** the text-selection handles, the cursor, the overscroll indicator, the scrollbar, the splash and highlight colors, the system bar contrast. They ship with framework defaults belonging to no design system. Theme them. This is the cheapest signal that an app was built rather than assembled, and the one most reliably skipped.
- **Copy:** the product's own language. Controls name their action; errors name the problem and the recovery.

## Refuse

These are the category's defaults, not bans, the brief's own words can earn any of them. Reaching for one when the axis is free means you were not deciding.

Screen scaffolds:

- Same-size `Card`s of icon plus heading plus body as the screen structure. `Card` is the lazy container; a `Card` inside a `Card` is always wrong.
- The hero-metric template: big number, small label, supporting stats, accent.
- A kicker or eyebrow above a heading. This one is a ban, not a default: the heading carries its own weight.
- Section numbers (01 / 02 / 03) unless the sequence carries information the reader needs.
- A dialog for a task that needs neither interruption nor protected focus. A bottom sheet or a pushed route is usually right.

Surface habits:

- Gradient text through `ShaderMask`. Emphasis comes from weight and size, and the shader defeats contrast checking.
- Glass and blur as decoration rather than as a specific effect. `BackdropFilter` is also expensive on the raster thread.
- A colored `BorderSide` above 1 logical pixel on one edge of a card, tile or banner.
- `RadialGradient` halos behind hero content.
- A rounded square holding an icon, stacked above every heading.
- Unicode glyphs or emoji standing in for an icon system.
- `Colors.deepPurple`, `Colors.blue`, or an indigo-to-violet pair as the brand. Pick a seed from the product.
- Light or dark chosen by category. Pick it from the use scene: who, where, under what ambient light.

## Flutter-specific reflexes

No rule catches these, and they are what separates working code from shipped code.

- Read color and text style from `Theme.of(context)` as you write the widget, not as a cleanup pass afterwards. The cleanup pass never happens.
- Wrap content in `SafeArea` when you create the `Scaffold`, not when someone reports the notch bug.
- Give every `IconButton` a `tooltip` at the moment you write it.
- Reach for `ListView.builder` by default; the non-builder form is the exception for a short fixed list.
- Dispose every controller you create in the `initState` that created it.
- When you write a `GestureDetector`, ask whether `InkWell` belongs there instead, it gives you the ripple the platform expects.

The floor holds the mechanics; it never picks the direction. With every check green, spend the screen on the committed world.
