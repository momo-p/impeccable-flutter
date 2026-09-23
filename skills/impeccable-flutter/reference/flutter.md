# The Flutter platform contract

Read before any UI edit. This is what a fluent phone user expects from a Flutter app on their hardware, and what generated Flutter code most reliably breaks.

## The Flutter slop test

Would a fluent phone user trust this app, or notice it was assembled? The two tells:

**The default app.** Roboto, `Colors.blue` or `Colors.deepPurple`, `Card` as the only container, `EdgeInsets.all(16)` on everything, `Icons.star` for meaning it does not carry. Nothing was chosen; the framework's defaults were accepted.

**The ported website.** A `ListView` of full-bleed gradient sections with oversized headlines, a hand-rolled top bar instead of `AppBar`, hover states that never fire, text in fixed-height boxes, buttons that are `Container` plus `GestureDetector`. It compiles and it is not an app.

Departing from a platform default needs a reason the user would thank you for.

## The theme is the design

This is the rule that separates a Flutter app that can be maintained from one that cannot.

- **Colors come from `ColorScheme`.** `Theme.of(context).colorScheme.primary`, `.surface`, `.onSurfaceVariant`, `.error`. Build it with `ColorScheme.fromSeed(seedColor:, brightness:)` and override the roles you actually have an opinion about. A `Color(0xFF…)` literal in a widget cannot follow light and dark, so dark mode breaks the moment someone toggles it.
- **Text comes from `TextTheme`.** `displayLarge` through `labelSmall` are the roles. A screen picks a role; it does not pick a `fontSize`. Where a style needs a nudge, derive it: `theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)`.
- **Shape, elevation and component defaults live in `ThemeData`.** `cardTheme`, `filledButtonTheme`, `inputDecorationTheme`, `appBarTheme`. Set the look once there rather than on every instance.
- **The one file where literals belong is the theme file.** The detector exempts it by path and by the presence of `ThemeData` / `ColorScheme`.

Dark mode is a scheme you design, not an invert you enable. Build both with `ColorScheme.fromSeed` and check contrast in each.

## Layout and structure

- **`SafeArea` around content.** Without it, content runs under the notch, the status bar, the home indicator and the gesture bar. `AppBar` handles the top inset; the bottom is still yours.
- **Keyboard insets.** `resizeToAvoidBottomInset` plus scrollable content, or the field the user is typing in ends up behind the keyboard.
- **Navigation from the platform.** `NavigationBar` for 3-5 top-level destinations on compact width, `NavigationRail` or `NavigationDrawer` on expanded. `Navigator` for hierarchy, `showModalBottomSheet` for a self-contained task. No custom global nav.
- **System back always works.** `PopScope` with `onPopInvokedWithResult`, never `WillPopScope` (removed) and never a trap. Android predictive back animates the gesture only if you use `PopScope`.
- **Bounded scrollables.** A `ListView` inside a `Column` throws unless it is inside `Expanded`/`Flexible` or carries `shrinkWrap: true`. `shrinkWrap` builds every child, so it is for short lists only.
- **`Expanded` and `Flexible` express intent**; a hard `width`/`height` on a layout box usually hides a constraint problem.

## Adaptivity

- **Branch on `LayoutBuilder` constraints, never on `MediaQuery.of(context).size`.** The window size is not the space your widget was given. It reports the wrong number in split view, multi-window, inside a constrained parent, and on a foldable mid-fold. `constraints.maxWidth` is the truth.
- **Breakpoints restructure, they do not scale.** Compact under 600, medium 600-840, expanded above. On expanded width the navigation bar becomes a rail, a list becomes list-plus-detail.
- **Orientation restructures too.** Landscape puts panes side by side. Lock orientation only when the task truly demands it.

## Typography and text scaling

- **Type follows the user's text size.** `MediaQuery.textScalerOf(context)` is applied for you when sizes come from the theme. It breaks when a `SizedBox` with a hard height wraps text, or a `Row` of labels has no room to wrap.
- **Test at 200%.** `flutter run` then raise the system font size, or set `MediaQuery(data: data.copyWith(textScaler: TextScaler.linear(2.0)))` in a widget test. Clipped labels show up immediately.
- **Roboto is the Android system face.** Shipping it as the brand face means no face was picked. Bundle a real one through `fontFamily` in `pubspec.yaml`, or `google_fonts` where licensing allows, and keep body and controls legible.
- **`maxLines` plus `overflow: TextOverflow.ellipsis` on anything that can receive long content**, including translated strings, which run 30% longer than English.

## Touch targets and accessibility

- **48×48 logical pixels minimum**, 8 between adjacent targets. `IconButton` gives you this by default; `GestureDetector` on a bare `Icon` does not.
- **Every interactive element is labeled.** `IconButton` takes `tooltip`, which doubles as the screen-reader label. A `GestureDetector` or `InkWell` with no `Text` in its subtree needs a `Semantics(label:, button: true)` wrapper.
- **Decorative images get `excludeFromSemantics: true`**; meaningful ones get `semanticLabel`.
- **Announce state changes**, not just labels: selected, expanded, loading. `Semantics(selected:)`, `SemanticsService.announce`.
- **Honor reduced motion.** `MediaQuery.disableAnimationsOf(context)`: crossfade or cut instead of a large slide.

## Motion

- **Material motion patterns**: container transform for a card opening into a screen, shared axis for a step in a flow, fade-through for a lateral switch. `package:animations` implements them.
- **Exponential ease-out**, `Curves.easeOutCubic` or `easeOutQuint`, 200-400ms. `Curves.bounceOut` and `Curves.elasticOut` overshoot on arrival and read as dated.
- **Animate transform and opacity, not layout.** `AnimatedContainer` on `width` or `height` re-runs layout every frame; use `AnimatedSize` where the reflow is the point, otherwise `AnimatedScale`, `AnimatedSlide`, `FadeTransition`.
- **One authored moment per screen**, not an entrance on every widget.

## States

Every screen that loads anything needs four, and generated code ships one:

- **Loading**: a skeleton that matches the shape of the real content, not a centered spinner on an empty page.
- **Empty**: says what goes here and how to put the first one there. This is an onboarding surface, not an error.
- **Error**: names the problem and the recovery, with a retry that actually retries.
- **Offline**: Flutter apps run on phones that lose signal. Say what is stale and what is queued.

`Image.network` without `errorBuilder` shows a broken box; without `loadingBuilder` it pops in.

## Performance

- **`ListView.builder`, never `ListView(children: [...])` for long or unbounded lists.** The non-builder form constructs every child.
- **`const` constructors everywhere they apply.** They stop subtree rebuilds; `flutter analyze` with the default lints finds the misses.
- **Keep `build` pure.** No `setState`, no async work, no allocation of controllers. Controllers belong in `initState` and get disposed.
- **Check with the tools, not by eye.** `flutter run --profile` then the DevTools performance view; the raster and UI threads tell you which side is late.

## Verifying

Screenshots come from a device or emulator, never a browser, see [verify.md](verify.md). Golden tests (`matchesGoldenFile`) are the regression net for everything a static rule cannot see.
