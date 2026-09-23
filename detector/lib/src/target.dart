/// The surface class the code is built for.
///
/// This is not a size breakpoint. It decides which input the user has, and
/// that changes what a rule should even look for: a 48dp tap target is
/// meaningless on a TV nobody touches, and a focus highlight is optional on a
/// phone and mandatory on a remote.
enum Target {
  phone,
  tablet,
  tv,
  web;

  static Target? parse(String s) {
    for (final t in Target.values) {
      if (t.name == s) return t;
    }
    return null;
  }
}

/// The thresholds and capability questions a rule asks about its target.
class Profile {
  const Profile(this.target);

  final Target target;

  /// The user points at things with a finger.
  bool get isTouch => target == Target.phone || target == Target.tablet;

  /// The user moves a focus ring: a D-pad on TV, a Tab key on the web. Focus
  /// is the only way in, so an unfocusable control is an unreachable one.
  bool get isFocusDriven => target == Target.tv || target == Target.web;

  /// A pointer can hover. Never true on TV, and never true on a phone either —
  /// a hover-only affordance there is simply invisible.
  bool get hasHover => target == Target.web;

  /// Minimum readable body size. The phone figure assumes arm's length; the TV
  /// figure assumes roughly three metres, where anything under 20sp is a blur.
  double get minBodyTextSize => target == Target.tv ? 20 : 11;

  /// Below this, functional text (labels, captions, buttons) is too small to
  /// operate, as opposed to merely hard to read.
  double get minUiTextSize => target == Target.tv ? 18 : 12;

  /// Largest headline that still fits the narrowest surface in this class.
  /// A TV is 1920 wide at a device pixel ratio of 1, so display type has far
  /// more room than a phone does.
  double get maxHeadlineSize => switch (target) {
        Target.tv => 96,
        Target.tablet || Target.web => 72,
        Target.phone => 56,
      };

  /// Minimum touch target, in logical pixels. Zero where there is no touch.
  double get minTapTarget => isTouch ? 48 : 0;

  /// TV panels overscan: the outer band of the picture may not be displayed at
  /// all. Android TV asks for a 5% margin, which is 48 logical pixels on a
  /// 1920x1080 surface. `SafeArea` does not supply this.
  double get overscanInset => target == Target.tv ? 48 : 0;

  @override
  String toString() => target.name;
}
