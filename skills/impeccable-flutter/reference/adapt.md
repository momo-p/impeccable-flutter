# adapt

Adapt a screen to another context: a larger device class, another orientation, a folded or split window, the other platform.

The trap is treating adaptation as scaling. The job is restructuring.

Start from `detect --only mediaquery-size-branch,platform-control-mix`.

## Size, not device

**Branch on `LayoutBuilder` constraints, never on `MediaQuery.of(context).size`.** The window size is not the space your widget was given. It is wrong inside a constrained parent, in split view, in multi-window, in a side sheet, and on a foldable mid-fold. Device-model checks are wrong for the same reason, only more so.

```dart
LayoutBuilder(
  builder: (context, constraints) => constraints.maxWidth >= 840
      ? const _ListDetail()
      : const _ListOnly(),
)
```

Material's window size classes: **compact** under 600, **medium** 600–840, **expanded** 840 and up.

## Phone to tablet

- **Restructure, do not stretch.** A phone layout filling a tablet is the failure mode: a 900-pixel line of body text and a column of full-width buttons.
- Navigation changes shape: `NavigationBar` at compact, `NavigationRail` at medium, `NavigationDrawer` at expanded.
- Use the width: list-plus-detail side by side, multi-column grids, a dialog or popover where the phone used a full-screen route.
- Cap reading measure even when there is room. `ConstrainedBox(maxWidth: 680)` around text.
- Split view and multi-window can hand a tablet a phone-width window. Constraint-driven layout handles both for free.

## Orientation and foldables

- Landscape restructures into side-by-side panes; it does not clip or letterbox. Lock orientation only when the task truly demands it.
- Foldables: react to posture through `MediaQuery.displayFeaturesOf(context)`. Test folded, unfolded and tabletop.

## Platform to platform

Flutter draws Material on both by default, which is a decision, not a neutral state. A Material-everywhere app still owes iOS its OS guarantees on Apple hardware: safe-area insets, the left-edge back gesture, reduced motion.

If the app adapts per platform, adapt the whole vocabulary, not one control:

| Material | Cupertino |
|---|---|
| `NavigationBar` | `CupertinoTabBar` |
| `AppBar` | `CupertinoNavigationBar` |
| `Switch`, `Slider` | `CupertinoSwitch`, `CupertinoSlider` |
| `showModalBottomSheet` | `showCupertinoModalPopup` |
| `AlertDialog` | `CupertinoAlertDialog` |
| `CircularProgressIndicator` | `CupertinoActivityIndicator` |

One `CupertinoButton` inside a Material `Scaffold` gives each platform half an app it does not recognize. Pick per platform, not per widget — `Theme.of(context).platform` at the top, or adaptive constructors (`Switch.adaptive`) throughout.

## Verify

Test at each size class, both orientations, and split-screen where supported. Simulators give breadth; posture, gestures and performance need hardware. Say which produced the evidence — see [verify.md](verify.md).

**Never**: ship a stretched phone layout on a tablet; port one platform's navigation onto the other; hide core functionality on small screens; lock orientation to dodge a layout bug.
