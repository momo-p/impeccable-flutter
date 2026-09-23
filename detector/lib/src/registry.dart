import 'finding.dart';
import 'target.dart';

/// The Flutter rule catalog.
///
/// `portOf` names the rule in pbakaus/impeccable's registry
/// (`crates/foundation/src/registry.rs`, extracted to
/// `tool/upstream_registry.json`) that this one carries over. A null `portOf`
/// is a rule the web engine has no equivalent for, because the thing it checks
/// only exists on a Flutter surface.
///
/// Upstream rules that need rendered geometry or a live DOM — `text-occlusion`,
/// `edge-flush-cards`, `broken-image`, `line-length`, `script-error`,
/// `content-hidden-at-rest`, `first-viewport-column-overflow` — have no entry
/// here. They are not portable to static source; `verify.md` covers them with
/// screenshots and golden tests instead.
const List<Rule> kRules = [
  // ---- pubspec.yaml conformance -------------------------------------------
  Rule(
    id: 'undeclared-font',
    category: Category.platform,
    section: 'Typography',
    name: 'Font not declared in pubspec.yaml',
    description:
        'A fontFamily the pubspec never declares under flutter: fonts:. Flutter falls back to the platform face without a warning, so the app ships in Roboto and nothing reports it — not the analyzer, not a crash, not a log line.',
  ),
  Rule(
    id: 'undeclared-asset',
    category: Category.platform,
    severity: Severity.error,
    section: 'Edge cases',
    name: 'Asset not declared in pubspec.yaml',
    description:
        'An asset path that no entry under flutter: assets: covers. The image throws when that widget builds, which is often a screen nobody opened before release.',
  ),
  // ---- Web -----------------------------------------------------------------
  Rule(
    id: 'text-not-selectable',
    category: Category.platform,
    targets: {Target.web},
    section: 'Platform',
    name: 'Content text cannot be selected',
    description:
        'Flutter paints text to a canvas, so on the web it is not selectable unless a SelectionArea wraps it. Copying a paragraph is something every other page on the web allows, and its absence reads as a broken page rather than a design choice.',
  ),
  Rule(
    id: 'hash-url-strategy',
    category: Category.platform,
    targets: {Target.web},
    section: 'Platform',
    name: 'URLs left on the hash strategy',
    description:
        'Without usePathUrlStrategy() a Flutter web app serves every route under a # fragment. Those URLs do not share cleanly, and search engines treat them as one page.',
  ),
  // ---- Design-system conformance (silent without a DESIGN.md) -------------
  Rule(
    id: 'design-system-color',
    category: Category.quality,
    portOf: 'design-system-color',
    section: 'Color',
    name: 'Color outside DESIGN.md',
    description:
        'A color used in widget code that the project never declared. Either add it to the design system on purpose, or use the token that already covers this case.',
  ),
  Rule(
    id: 'design-system-font',
    category: Category.quality,
    portOf: 'design-system-font',
    section: 'Typography',
    name: 'Font outside DESIGN.md',
    description:
        'A font family the design system does not list. A second undeclared face is how a type system quietly becomes two type systems.',
  ),
  Rule(
    id: 'design-system-font-size',
    category: Category.quality,
    portOf: 'design-system-font-size',
    section: 'Typography',
    name: 'Font size off the ramp',
    description:
        'A font size that is not on the declared type ramp. One-off sizes are what flatten a scale into a gradient.',
  ),
  Rule(
    id: 'design-system-radius',
    category: Category.quality,
    portOf: 'design-system-radius',
    section: 'Visual Details',
    name: 'Radius outside DESIGN.md',
    description:
        'A corner radius the design system does not declare. Mixed radii read as inconsistency long before anyone can name why.',
  ),
  Rule(
    id: 'repeated-container-text',
    category: Category.quality,
    portOf: 'repeated-container-text',
    section: 'Copy',
    name: 'Same text repeated in one container',
    description:
        'The identical string rendered twice inside one parent is almost always a copy-paste that was never filled in, or a label duplicating its own value.',
  ),
  // ---- Second port wave ---------------------------------------------------
  Rule(
    id: 'radial-spotlight-glow',
    category: Category.slop,
    portOf: 'radial-spotlight-glow',
    section: 'Color',
    name: 'Decorative radial spotlight glow',
    description:
        'A low-opacity accent-colored radial gradient fading to transparent, dropped behind a hero as atmosphere. It carries no information and dates the screen.',
  ),
  Rule(
    id: 'hero-eyebrow-chip',
    category: Category.slop,
    portOf: 'hero-eyebrow-chip',
    section: 'Typography',
    name: 'Hero eyebrow pill chip',
    description:
        'A tiny uppercase letterspaced label rendered as a pill chip above an oversized headline. Drop it and let the headline carry its own weight.',
  ),
  Rule(
    id: 'undersized-ui-text',
    category: Category.quality,
    portOf: 'undersized-ui-text',
    section: 'Typography',
    name: 'Undersized functional text',
    description:
        'Interactive and content-bearing text — button labels, list tiles, tabs, chips — below the legibility floor is a defect, not a style choice. Being on the theme ramp does not exempt it.',
  ),
  Rule(
    id: 'gray-on-color',
    category: Category.quality,
    portOf: 'gray-on-color',
    section: 'Color',
    name: 'Gray text on a colored surface',
    description:
        'Neutral gray text washes out on a tinted surface. Tint the text from the surface hue, or go to near-white or near-black. On Flutter this is what onSurfaceVariant exists for.',
  ),
  Rule(
    id: 'aphoristic-cadence',
    category: Category.slop,
    portOf: 'aphoristic-cadence',
    severity: Severity.advisory,
    section: 'Copy',
    name: 'Aphoristic-cadence copy',
    description:
        'Several strings landing on the same short rebuttal shape — "Not X. Y." or "No X. Just Y." — is the most recognizable rhythm of generated copy. Say the thing once, plainly.',
  ),
  Rule(
    id: 'theater-slop-phrase',
    category: Category.slop,
    portOf: 'theater-slop-phrase',
    severity: Severity.advisory,
    section: 'Copy',
    name: 'Theater framing copy',
    description:
        'Dismissing something as theater, noise or magic, or promising it "just works", is filler standing in for the actual claim.',
  ),
  Rule(
    id: 'numbered-section-labels',
    category: Category.slop,
    portOf: 'numbered-section-labels',
    severity: Severity.advisory,
    section: 'Typography',
    name: 'Tiny numbered section labels',
    description:
        'Small numeric index labels riding beside headings, section after section, is a screen numbering its own chapters instead of earning structure.',
  ),
  Rule(
    id: 'pulsing-dot',
    category: Category.slop,
    portOf: 'pulsing-dot',
    section: 'Motion',
    name: 'Pulsing status dot',
    description:
        'A small circular container on a repeating animation simulates liveness decoratively. Reserve pulse for an indicator tied to genuinely changing data; otherwise a static, labeled dot is honest and calmer.',
  ),
  Rule(
    id: 'blinking-cursor',
    category: Category.slop,
    portOf: 'blinking-cursor',
    severity: Severity.advisory,
    section: 'Motion',
    name: 'Decorative blinking cursor',
    description:
        'A blinking caret animated into a hero simulates typing where no input exists. Real text fields draw their own caret.',
  ),
  Rule(
    id: 'marquee',
    category: Category.slop,
    portOf: 'marquee',
    section: 'Motion',
    name: 'Auto-scrolling marquee',
    description:
        'Continuously auto-scrolling content demands attention it has not earned and hides half of itself at any moment. On TV it also fights the focus model.',
  ),
  Rule(
    id: 'cream-palette',
    category: Category.slop,
    portOf: 'cream-palette',
    section: 'Color',
    name: 'Cream or beige surface',
    description:
        'A warm cream or beige background has become the default tasteful surface, reached for by reflex. Choose a background that comes from a deliberate palette.',
  ),
  Rule(
    id: 'thin-border-wide-shadow',
    category: Category.slop,
    portOf: 'gpt-thin-border-wide-shadow',
    severity: Severity.advisory,
    section: 'Visual Details',
    name: 'Hairline border with a wide shadow',
    description:
        'A hairline border paired with a wide diffuse shadow is a generated-UI signature. Commit to a defined edge or to soft elevation, not both.',
  ),
  Rule(
    id: 'repeating-stripes-gradient',
    category: Category.slop,
    portOf: 'repeating-stripes-gradient',
    severity: Severity.advisory,
    section: 'Visual Details',
    name: 'Repeating-gradient stripes',
    description:
        'Stripes built from a repeating gradient as surface decoration are a generated-UI signature. Reach for a deliberate texture or leave the surface plain.',
  ),
  Rule(
    id: 'grid-line-background',
    category: Category.slop,
    portOf: 'codex-grid-background',
    severity: Severity.advisory,
    section: 'Visual Details',
    name: 'Decorative grid-line background',
    description:
        'A grid or line field painted behind content. Reserve grid overlays for an actual canvas, map, blueprint or measurement surface.',
  ),
  Rule(
    id: 'italic-serif-display',
    category: Category.slop,
    portOf: 'italic-serif-display',
    section: 'Typography',
    name: 'Italic serif display headline',
    description:
        'Oversized italic serif as the primary headline reads as taste in isolation and has become the universal generated hero. An editorial register may legitimately want it; judge by context.',
  ),
  Rule(
    id: 'wide-tracking',
    category: Category.quality,
    portOf: 'wide-tracking',
    section: 'Typography',
    name: 'Wide letter spacing on body text',
    description:
        'Letter spacing above 0.05em on running text breaks up natural character groupings and slows reading. Reserve wide tracking for short uppercase labels.',
  ),
  Rule(
    id: 'image-hover-transform',
    category: Category.slop,
    portOf: 'image-hover-transform',
    severity: Severity.advisory,
    targets: {Target.web},
    section: 'Motion',
    name: 'Image transform on hover',
    description:
        'Scaling or rotating an image on hover is a generated-UI signature. Let imagery sit still, or find a subtler purposeful interaction.',
  ),
  // ---- Focus-driven targets: TV and the web's keyboard path --------------
  Rule(
    id: 'unreachable-by-dpad',
    category: Category.platform,
    severity: Severity.error,
    targets: {Target.tv, Target.web},
    section: 'Focus',
    name: 'Control unreachable by D-pad',
    description:
        'A GestureDetector.onTap with nothing focusable around it cannot be activated by a remote or by the Tab key. There is no pointer to put on it, so the control does not exist for the user.',
  ),
  Rule(
    id: 'missing-focus-highlight',
    category: Category.platform,
    severity: Severity.error,
    targets: {Target.tv, Target.web},
    section: 'Focus',
    name: 'Focusable with no visible focus state',
    description:
        'On a focus-driven surface the focus ring is the cursor. A focusable whose subtree never reads hasFocus, onShowFocusHighlight, onFocusChange or focusColor looks identical focused and unfocused, so the user cannot tell where they are.',
  ),
  Rule(
    id: 'no-autofocus-on-route',
    category: Category.platform,
    severity: Severity.error,
    targets: {Target.tv},
    section: 'Focus',
    name: 'Screen opens with nothing focused',
    description:
        'A screen with focusable controls and no autofocus, FocusScope or FocusTraversalGroup opens with focus nowhere. The first press of the remote does nothing, which reads as a frozen app.',
  ),
  Rule(
    id: 'hover-only-affordance',
    category: Category.platform,
    targets: {Target.tv, Target.web},
    section: 'Focus',
    name: 'Affordance available only on hover',
    description:
        'Behaviour attached to hover with no focus equivalent is unreachable from a remote and from the keyboard. Pair every onHover with onFocusChange or a focus-aware style.',
  ),
  Rule(
    id: 'overscan-unsafe',
    category: Category.platform,
    severity: Severity.error,
    targets: {Target.tv},
    section: 'Layout',
    name: 'Content inside the TV overscan band',
    description:
        'TV panels may crop the outer 5 percent of the picture. SafeArea does not account for this. Android TV asks for a margin of about 48 logical pixels on a 1920x1080 surface.',
  ),
  // ---- Ported slop -------------------------------------------------------
  Rule(
    id: 'overused-font',
    category: Category.slop,
    portOf: 'overused-font',
    section: 'Typography',
    name: 'Overused font',
    description:
        'Inter, Roboto, Poppins, Montserrat, Plus Jakarta Sans, Space Grotesk and Geist are on so many apps they no longer read as a choice. Roboto is also the Android default, so shipping it as the brand face means no face was picked. Choose one that gives the app a voice.',
  ),
  Rule(
    id: 'gradient-text',
    category: Category.slop,
    portOf: 'gradient-text',
    section: 'Typography',
    name: 'Gradient text',
    description:
        'A ShaderMask pouring a gradient into a headline. Emphasis comes from weight and size; the gradient reads as a template. It also defeats text contrast checks.',
  ),
  Rule(
    id: 'ai-color-palette',
    category: Category.slop,
    portOf: 'ai-color-palette',
    section: 'Color',
    name: 'AI color palette',
    description:
        'The indigo-to-violet or blue-to-purple pairing every generated UI converges on. Pick a palette from the product, not from the default.',
  ),
  Rule(
    id: 'nested-cards',
    category: Category.slop,
    portOf: 'nested-cards',
    section: 'Layout',
    name: 'Nested cards',
    description:
        'A Card inside a Card. Two elevation surfaces stacked cancel each other out and add a border the layout did not ask for. Flatten the inner one.',
  ),
  Rule(
    id: 'bounce-easing',
    category: Category.slop,
    portOf: 'bounce-easing',
    section: 'Motion',
    name: 'Bounce or elastic easing',
    description:
        'Curves.bounceOut, Curves.elasticIn/Out and easeOutBack overshoot on arrival. They read as dated and fight Material motion. Use an exponential ease-out such as Curves.easeOutCubic.',
  ),
  Rule(
    id: 'side-tab',
    category: Category.slop,
    portOf: 'side-tab',
    section: 'Visual Details',
    name: 'Side-tab accent border',
    description:
        'A thick colored BorderSide on one edge of a container — the most recognizable tell of generated UI. Drop it or carry the accent some other way.',
  ),
  Rule(
    id: 'border-accent-on-rounded',
    category: Category.slop,
    portOf: 'border-accent-on-rounded',
    section: 'Visual Details',
    name: 'Border accent on rounded surface',
    description:
        'A thick accent border on a rounded container: the stripe fights the corner radius. Remove one of the two.',
  ),
  Rule(
    id: 'dark-glow',
    category: Category.slop,
    portOf: 'dark-glow',
    section: 'Visual Details',
    name: 'Glowing shadow accent',
    description:
        'A BoxShadow with a chromatic color, no offset and a wide blur is a halo, not depth. Real shadows have an offset and a neutral, low-alpha color.',
  ),
  Rule(
    id: 'radial-halo',
    category: Category.slop,
    portOf: 'radial-halo',
    section: 'Color',
    name: 'Radial-gradient background halo',
    description:
        'A RadialGradient glow behind the hero content. It carries no information and dates the screen immediately.',
  ),
  Rule(
    id: 'icon-tile-stack',
    category: Category.slop,
    portOf: 'icon-tile-stack',
    section: 'Layout',
    name: 'Icon tile stacked above heading',
    description:
        'A rounded square holding an Icon, sitting above a heading, repeated down the screen. The tile adds nothing the icon did not already say.',
  ),
  Rule(
    id: 'kicker-above-heading',
    category: Category.slop,
    portOf: 'kicker-above-heading',
    section: 'Typography',
    name: 'Kicker above heading',
    description:
        'A small, often uppercase or letterspaced label directly above a large heading. Upstream treats this as a ban rather than a default: the heading carries its own weight.',
  ),
  Rule(
    id: 'oversized-headline',
    category: Category.slop,
    portOf: 'oversized-h1',
    section: 'Typography',
    name: 'Oversized headline',
    description:
        'A fontSize past roughly 56 logical pixels on a phone-width surface. Flutter has no viewport-relative unit, so an oversized display size clips on small devices and at large text scale.',
  ),
  Rule(
    id: 'extreme-negative-tracking',
    category: Category.slop,
    portOf: 'extreme-negative-tracking',
    section: 'Typography',
    name: 'Crushed letter spacing',
    description:
        'letterSpacing below about -4% of the font size collides glyphs. The tracking floor is -0.04em.',
  ),
  Rule(
    id: 'monotonous-spacing',
    category: Category.slop,
    portOf: 'monotonous-spacing',
    section: 'Layout',
    name: 'Monotonous spacing',
    description:
        'Nearly every gap in the file is the same number. Tight groups and generous separation are what make a layout read; one repeated value flattens it.',
  ),
  Rule(
    id: 'flat-type-hierarchy',
    category: Category.slop,
    portOf: 'flat-type-hierarchy',
    section: 'Typography',
    name: 'Flat type hierarchy',
    description:
        'Many text sizes that sit within a few pixels of each other. Without clear steps, nothing reads as more important than anything else.',
  ),
  Rule(
    id: 'marketing-buzzword',
    category: Category.slop,
    portOf: 'marketing-buzzword',
    severity: Severity.advisory,
    section: 'Copy',
    name: 'Marketing buzzword',
    description:
        'Seamless, effortless, unlock, elevate, supercharge, game-changing. Say what the feature does.',
  ),
  Rule(
    id: 'em-dash-overuse',
    category: Category.slop,
    portOf: 'em-dash-overuse',
    severity: Severity.advisory,
    section: 'Copy',
    name: 'Em-dash overuse',
    description:
        'Several em dashes across the UI strings. It is the most recognizable tell of generated copy.',
  ),

  // ---- Ported quality ----------------------------------------------------
  Rule(
    id: 'tiny-text',
    category: Category.quality,
    portOf: 'tiny-text',
    section: 'Typography',
    name: 'Tiny text',
    description:
        'Text below 11 logical pixels is unreadable for many users before text scaling is even applied.',
  ),
  Rule(
    id: 'tight-leading',
    category: Category.quality,
    portOf: 'tight-leading',
    section: 'Typography',
    name: 'Tight line height',
    description:
        'A TextStyle height below about 1.15 on running text crowds the lines. Body copy wants 1.4 or more.',
  ),
  Rule(
    id: 'justified-text',
    category: Category.quality,
    portOf: 'justified-text',
    section: 'Typography',
    name: 'Justified text',
    description:
        'TextAlign.justify opens rivers of whitespace on narrow phone measures and has no hyphenation to fall back on in Flutter.',
  ),
  Rule(
    id: 'all-caps-body',
    category: Category.quality,
    portOf: 'all-caps-body',
    section: 'Typography',
    name: 'All-caps body text',
    description:
        'toUpperCase() on a sentence-length string. All caps removes word shape and slows reading; it also breaks in languages without case.',
  ),
  Rule(
    id: 'cramped-padding',
    category: Category.quality,
    portOf: 'cramped-padding',
    section: 'Layout',
    name: 'Cramped padding',
    description:
        'Padding under 8 logical pixels inside a decorated surface leaves the content touching its own background.',
  ),
  Rule(
    id: 'layout-transition',
    category: Category.quality,
    portOf: 'layout-transition',
    section: 'Motion',
    name: 'Animated layout property',
    description:
        'Animating width or height re-runs layout every frame. Animate a transform, an opacity, or use AnimatedSize where the reflow is the point.',
  ),
  Rule(
    id: 'low-contrast',
    category: Category.quality,
    portOf: 'low-contrast',
    severity: Severity.error,
    section: 'Color',
    name: 'Low contrast text',
    description:
        'Literal foreground and background colors whose ratio falls under WCAG AA (4.5:1 for body, 3:1 for large text).',
  ),

  // ---- Flutter platform rules (no upstream equivalent) -------------------
  Rule(
    id: 'hardcoded-color',
    category: Category.platform,
    section: 'Theming',
    name: 'Hard-coded color',
    description:
        'A Color(0x…) literal or a Colors.* constant used as a surface or text color. It cannot follow the light and dark schemes, so dark mode breaks. Read it from Theme.of(context).colorScheme.',
  ),
  Rule(
    id: 'hardcoded-text-style',
    category: Category.platform,
    section: 'Typography',
    name: 'Hand-picked text style',
    description:
        'TextStyle(fontSize: …) written inline instead of a role from Theme.of(context).textTheme. Per-screen sizes are how a type scale stops existing.',
  ),
  Rule(
    id: 'missing-safe-area',
    category: Category.platform,
    severity: Severity.error,
    section: 'Layout',
    name: 'Scaffold body outside SafeArea',
    description:
        'Content laid out without SafeArea runs under the notch, the status bar, the home indicator, or the keyboard.',
  ),
  Rule(
    id: 'tap-target-undersized',
    category: Category.platform,
    severity: Severity.error,
    section: 'Accessibility',
    name: 'Tap target below the minimum',
    description:
        'A tappable box under 48x48 logical pixels fails Material guidance and the Android accessibility scanner; 44x44 is the iOS floor.',
  ),
  Rule(
    id: 'mediaquery-size-branch',
    category: Category.platform,
    section: 'Adaptivity',
    name: 'Layout branched on MediaQuery size',
    description:
        'MediaQuery.of(context).size drives layout from the window, not from the space the widget was actually given. It reports the wrong number in split view, multi-window, and inside a constrained parent. Branch on LayoutBuilder constraints.',
  ),
  Rule(
    id: 'missing-semantics',
    category: Category.platform,
    severity: Severity.error,
    section: 'Accessibility',
    name: 'Unlabeled interactive element',
    description:
        'An IconButton without a tooltip, or a GestureDetector with no Semantics wrapper, is an unlabeled control to TalkBack and VoiceOver.',
  ),
  Rule(
    id: 'deprecated-with-opacity',
    category: Category.platform,
    section: 'Color',
    name: 'Color.withOpacity',
    description:
        'withOpacity is deprecated in favour of withValues(alpha: …), which avoids the precision loss of the old 8-bit channel round-trip.',
  ),
  Rule(
    id: 'unbounded-list',
    category: Category.platform,
    severity: Severity.error,
    section: 'Layout',
    name: 'Scrollable in an unbounded column',
    description:
        'A ListView or GridView placed directly in a Column throws a layout overflow unless it is wrapped in Expanded or given shrinkWrap.',
  ),
  Rule(
    id: 'fixed-height-text-box',
    category: Category.platform,
    section: 'Accessibility',
    name: 'Text in a fixed-height box',
    description:
        'A SizedBox with a hard height around text clips as soon as the user raises the system text size. Let the box size to its content.',
  ),
  Rule(
    id: 'platform-control-mix',
    category: Category.platform,
    section: 'Platform',
    name: 'Cupertino and Material mixed',
    description:
        'Cupertino and Material controls in one widget tree give each platform half an app it does not recognize. Pick per platform, not per widget.',
  ),
  Rule(
    id: 'deprecated-will-pop-scope',
    category: Category.platform,
    section: 'Platform',
    name: 'WillPopScope',
    description:
        'WillPopScope is removed in favour of PopScope, which is what Android predictive back needs to animate the gesture.',
  ),
  Rule(
    id: 'network-image-unguarded',
    category: Category.platform,
    section: 'Edge cases',
    name: 'Network image with no error or loading state',
    description:
        'Image.network without errorBuilder shows a broken box on a failed fetch, and without loadingBuilder it pops in with no placeholder.',
  ),
];

final Map<String, Rule> kRulesById = {for (final r in kRules) r.id: r};
