# audit

A scored technical review of a Flutter surface. Document issues; do not fix them, other commands do that. This is a code-level audit, not a UX critique; [critique.md](critique.md) is that.

Start from `detect` output rather than re-deriving it by reading. Score against [flutter.md](flutter.md).

## Diagnostic scan

Score each dimension 0-4.

### 1. Accessibility

- Unlabeled controls: `IconButton` without `tooltip`, `GestureDetector`/`InkWell` with no `Text` or `Semantics` in the subtree.
- Tap targets under 48×48, or crammed without 8 between them.
- Text scaling: layouts that clip at 200%, text inside fixed-height boxes, `Row`s of labels with no room to wrap.
- Reading and focus order: illogical traversal, focus lost on navigation, state changes that never announce.
- Contrast below 4.5:1 for body or 3:1 for large text, in either scheme.
- Reduced motion ignored.

**0**: screen reader unusable · **1**: major gaps · **2**: labels exist, order or scaling breaks · **3**: minor gaps · **4**: labeled, ordered, scales to 200%, reduced motion honored

### 2. Performance

- `ListView(children: [...])` where `ListView.builder` belongs.
- Missing `const` constructors causing subtree rebuilds.
- Work in `build`: allocation, async calls, `setState`.
- Controllers created without `dispose`.
- `BackdropFilter`, large shadows, `Opacity` on big subtrees, unnecessary `saveLayer`.
- Full-size images decoded for thumbnails; no `cacheWidth`.

**0**: janky everywhere · **1**: unvirtualized lists or leaks · **2**: partial · **3**: minor · **4**: smooth in profile mode, lean

### 3. Theming

- `Color(0x…)` and `Colors.*` literals outside the theme file.
- `TextStyle(fontSize:)` written inline instead of a `TextTheme` role.
- Dark scheme missing, or a quick invert with broken contrast.
- Component looks set per instance instead of in `ThemeData`.
- Framework surfaces left at default: splash, highlight, scrollbar, text selection, system bar contrast.

**0**: hard-coded everything · **1**: minimal theming · **2**: theme exists, used inconsistently · **3**: minor literals · **4**: semantic throughout, both schemes first-class

### 4. Platform conformance (critical)

- `WillPopScope` instead of `PopScope`; system back trapped or hijacked.
- Content outside `SafeArea`; keyboard insets unhandled.
- Hand-rolled navigation instead of `NavigationBar`/`NavigationRail`/`Navigator`.
- Web-shaped controls: `Container` plus `GestureDetector` where a button belongs; hover-dependent affordances.
- Cupertino and Material mixed in one tree.
- Icon sets mixed.

**0**: ported website · **1**: heavy violations · **2**: one or two noticeable · **3**: subtle issues · **4**: a fluent user trusts every screen

### 5. Adaptivity

- Layout branched on `MediaQuery.of(context).size` instead of `LayoutBuilder` constraints.
- Phone layout stretched on a tablet rather than restructured.
- Landscape clipped, ignored, or locked without reason.
- Split view and multi-window breaking layout; foldable postures unhandled.

**0**: one screen size · **1**: tablet or landscape broken · **2**: partial · **3**: minor edge cases · **4**: adapts across sizes, orientations and windowing

## Report

| # | Dimension | Score | Key finding |
|---|---|---|---|
| 1 | Accessibility | ? | |
| 2 | Performance | ? | |
| 3 | Theming | ? | |
| 4 | Platform conformance | ? | |
| 5 | Adaptivity | ? | |
| **Total** | | **??/20** | |

**Bands**: 18-20 excellent · 14-17 good · 10-13 acceptable · 6-9 poor · 0-5 critical

### Platform conformance verdict

Start here. Does this read as an app, or as a website that compiles? List the specific violations. Be honest.

### Findings by severity

- **P0** blocking: prevents task completion. Fix now.
- **P1** major: significant difficulty or a platform-guideline violation. Fix before release.
- **P2** minor: annoyance with a workaround.
- **P3** polish: no real user impact.

For each: location (file and line), category, user impact, the guideline it breaks, the fix, and which command to run.

### Patterns

Name recurring problems rather than listing each instance: "colors are hard-coded in 14 of 17 screens", "no `IconButton` in the app has a tooltip". Those are one fix each, not fourteen.

### What works

Note the good practices worth keeping and replicating.

## Recommended actions

Priority order, P0 first, drawn only from the commands in SKILL.md. End with `polish` if any fixes were recommended. Then tell the user they can run these in any order, and that re-running `audit` after fixes shows the score move.

**Never**: report an issue without its user impact; give generic advice; skip what works; mark everything P0; report a finding you have not verified in the source.
