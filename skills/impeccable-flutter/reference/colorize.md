# colorize

Give the app a color point of view, and make dark mode real.

Start from `detect --only ai-color-palette,hardcoded-color,dark-glow,radial-halo,low-contrast,gradient-text`. If literals are widespread, run [theme.md](theme.md) first — this command has nothing to work with until the scheme exists.

## Pick a seed with a reason

`ColorScheme.fromSeed` does the tonal work. What it cannot do is choose. The seed comes from the product: the material of the thing, the scene it is used in, the brand that exists.

`Colors.deepPurple` is the Flutter counter-app default. An indigo-to-violet pair is the generated-UI default. Both mean nobody chose.

## Use the roles

- `primary` is the main action and little else. It is not a decoration budget.
- `secondaryContainer` and `tertiaryContainer` carry accents that must not compete with the action.
- `surface`, `surfaceContainerLow/High/Highest` are the elevation ladder. Use tonal surfaces rather than stacking shadows.
- Secondary text is `onSurfaceVariant`. Gray text on a tinted surface is the failure this replaces.
- `error` for errors only; a red that also means "delete" and "overdue" means nothing.

## Dark mode

Build it with `ColorScheme.fromSeed(brightness: Brightness.dark)` and look at it. Two things go wrong:

- Saturated colors that worked on white vibrate on near-black. Dark schemes want lower chroma and higher tone for the same role.
- Pure black surfaces plus pure white text is harsh. Flutter's dark surfaces are tinted for a reason; keep the tint.

Check contrast in both. `low-contrast` in the detector only resolves literal pairs, so a clean run is not proof.

## Restraint

- Color carries meaning or it carries nothing. Three semantic colors that a user can learn beat a palette of nine.
- A gradient is a specific effect for a specific surface, not a background treatment. `ShaderMask` on a headline defeats contrast checking and reads as a template.
- A `RadialGradient` halo behind hero content is decoration standing in for a decision.
- Shadows are neutral and low-alpha with a real offset. A chromatic zero-offset shadow is a glow.
- `Colors.black` and `Colors.white` at full strength are rarely right; tint them toward the scheme.
