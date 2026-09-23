# animate

Add motion that carries meaning, inside the system the platform already has.

Start from `detect --only bounce-easing,layout-transition`.

## Use Material's motion patterns

`package:animations` implements them; hand-rolling these is how transitions start fighting the navigation model.

- **Container transform**: a card, tile or FAB opening into a full screen. `OpenContainer`.
- **Shared axis**: a step forward or back in a flow. `SharedAxisTransition`, X for lateral, Y for vertical, Z for zoom-depth.
- **Fade through**: switching between unrelated destinations, as in a `NavigationBar`. `FadeThroughTransition`.
- **Fade**: something entering or leaving on top, like a dialog.

## Curves and durations

- Exponential ease-out: `Curves.easeOutCubic`, `easeOutQuint`. Fast start, soft landing.
- 200-300ms for most transitions, up to 400ms for a large surface. Under 150ms reads as a jump; over 500ms reads as a wait.
- `Curves.bounceOut`, `elasticOut` and the `back` curves overshoot on arrival. They read as dated and fight Material motion.
- Entrances start from an already-visible default where possible. A screen that animates in from nothing is a screen that is blank for 300ms.

## Animate the cheap properties

- Transform, opacity and color are compositor-friendly. `AnimatedScale`, `AnimatedSlide`, `AnimatedOpacity`, `AnimatedContainer` on `color`.
- Animating `width` or `height` re-runs layout every frame. Use `AnimatedSize` where the reflow is the point; otherwise animate a transform.
- `AnimatedSwitcher` for swapping a child, with a `key` so it knows something changed.
- Implicit animations (`AnimatedFoo`) for state changes; `AnimationController` for anything choreographed, sequenced, or driven by a gesture.

## Discipline

- **One authored moment per screen.** A choreographed entrance for the thing that matters, not a stagger on every row.
- Motion that repeats forever is a distraction: pulsing dots, looping shimmer on loaded content, breathing buttons.
- Loading shimmer is for loading. Once content arrives it stops.
- **Honor reduced motion.** `MediaQuery.disableAnimationsOf(context)`: crossfade or cut instead of a large slide. This is an accessibility requirement, not a nicety.

## Lifecycle

Every `AnimationController` is created in `initState` with `vsync: this` and disposed in `dispose`. A controller that outlives its state leaks a ticker and the analyzer will not always catch it.
