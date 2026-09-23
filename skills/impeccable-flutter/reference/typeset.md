# typeset

Fix the type: the scale, the face, the hierarchy, and whether any of it survives the user's text-size setting.

Start from `detect --only overused-font,flat-type-hierarchy,tiny-text,tight-leading,oversized-headline,extreme-negative-tracking,hardcoded-text-style,fixed-height-text-box,all-caps-body,justified-text`.

## The scale

Steps, not a gradient. A scale a reader can feel has roughly a 1.25 ratio between adjacent roles and no two roles within four pixels. Define it once in `TextTheme` ([theme.md](theme.md)) and have screens pick roles.

`height` is a multiplier in Flutter, not a length. Body copy wants 1.4-1.6; display sizes want 1.05-1.2. A `height` under 1.15 on running text crowds the lines.

`letterSpacing` is logical pixels, not em. At `fontSize: 40`, `letterSpacing: -1.6` is -0.04em, which is the floor. Tighten display sizes, leave body alone, and open small caps labels slightly.

## The face

Roboto is the Android system face; shipping it as the brand face means no face was picked. Same for Inter, Poppins, Montserrat and the rest of the generated-UI set.

Bundle a face rather than depending on what the device has:

```yaml
fonts:
  - family: Söhne
    fonts:
      - asset: fonts/Soehne-Buch.otf
      - asset: fonts/Soehne-Halbfett.otf
        weight: 600
```

Then `fontFamily: 'Söhne'` on `ThemeData`. `google_fonts` fetches at runtime by default, which means a flash of fallback text on first launch, bundle the files instead where licensing allows.

## Text scaling

This is where Flutter typography actually breaks.

- Test at 200%. `MediaQuery(data: data.copyWith(textScaler: TextScaler.linear(2.0)))` in a widget test; the system font-size setting on a device.
- A `SizedBox` with a hard height around text clips the moment scaling rises. Let the box size to its content.
- A `Row` of labels with no `Expanded` and no wrap overflows.
- `maxLines` with `overflow: TextOverflow.ellipsis` on anything that can receive long or translated content. Translations run about 30% longer than English.
- Never clamp scaling to hide the bug. `TextScaler.noScaling` on a whole screen is an accessibility regression.

## Hierarchy

- One display-weight element per screen. Two competing headlines is none.
- Weight and size carry emphasis. Not color alone, not all-caps, not a gradient.
- All-caps removes word shape and breaks in languages without case. A short label can earn it; a sentence cannot.
- `TextAlign.justify` opens rivers on a phone measure and Flutter has no hyphenation to rescue it.

## Measure

Flutter will happily run a line the full width of a tablet. Cap it: `ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680))` around reading content, or a `LayoutBuilder` that adds side padding as width grows.
