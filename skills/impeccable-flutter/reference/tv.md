# TV

For Flutter shipping to Android TV, Google TV, Fire TV, or tvOS. Read before any TV UI edit, alongside [flutter.md](flutter.md).

Run the detector with the target set, or most of this is unchecked:

```bash
impeccable-flutter detect lib --target tv
```

## TV is not a large phone

A phone screen ported to a TV fails for one reason: **there is no pointer.** The user has a D-pad with up, down, left, right and select. Everything else follows from that.

- The **focus ring is the cursor.** If the user cannot see what is focused, they are lost. This is the single most common Android TV failure and it is invisible in a screenshot taken without focus.
- A control that cannot take focus **does not exist**. `GestureDetector(onTap:)` is unreachable, there is nothing to put on it.
- **Hover does not exist.** Any behaviour behind `onHover` or `MouseRegion` is dead.
- The viewing distance is roughly three metres, not thirty centimetres. Type that is comfortable on a phone is a blur.
- The user is leaning back, often with other people in the room. Sessions are long and attention is loose.

## Focus

**Every interactive element is focusable, and visibly so.** Material's buttons and `InkWell` handle this; a bare `Container` with a tap handler does not.

```dart
FocusableActionDetector(
  autofocus: isFirst,
  onShowFocusHighlight: (value) => setState(() => _focused = value),
  actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _play)},
  child: AnimatedScale(
    scale: _focused ? 1.06 : 1.0,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    child: _card,
  ),
)
```

- **Something takes focus on entry.** A screen that opens with focus nowhere ignores the first press of the remote, which reads as a frozen app. `autofocus: true` on the primary element, or an explicit `FocusScope` request.
- **The focus state is unmistakable.** Scale, a border at 3 logical pixels or more, a background change, usually two of them together. A subtle tint is not enough across a room, and colour alone fails for colour-blind viewers.
- **Traversal order follows the visual layout.** `FocusTraversalGroup` per row or rail; `FocusTraversalOrder` where the default reading order is wrong.
- **Focus must never be trapped.** Every screen needs a path back out with the Back button.
- **Keep the focused item on screen.** `Scrollable.ensureVisible` on focus change, or the focused card sits under the edge of the panel.

## Overscan

TV panels may crop the outer band of the picture. `SafeArea` does not know about this, it handles notches and system bars, not a television's own geometry.

Android TV asks for a **5% margin**: about 48 logical pixels on a 1920×1080 surface. Put it at the root of the screen, and never place text or a focusable inside it.

## Type and density

- **20sp is the floor for body text**, and 18sp for functional labels. The detector enforces this under `--target tv`.
- Display type has far more room than on a phone; the headline ceiling rises to about 96.
- Fewer things per screen, larger. A TV row holds 5-7 items, not a dense grid.
- High contrast. Living rooms have glare and the panel is often miscalibrated.

## Colour and motion

- **Dark by default.** A bright screen in a dark room is painful, and most TV content is letterboxed video.
- **Avoid pure white** (`#FFFFFF`) on large areas: it blooms on OLED and clips on poorly calibrated panels. Around 90% white is the usual ceiling.
- **Avoid pure black** on OLED where content sits beside it; near-black reads better against video.
- Motion is for the focus transition, and it is fast: 150-200ms. A slow animation between every card makes navigation feel laggy when the user holds a direction down.

## Layout

- Rails: a vertical list of horizontal rows is the pattern the platform and the user expect. Do not invent a new navigation model.
- No `NavigationBar` at the bottom, a side rail or a top row is the TV idiom.
- Text input is painful on a remote. Avoid it; offer voice or on-screen search with prediction where you cannot.
- Nothing time-sensitive: no hover tooltips, no controls that disappear before the user can D-pad to them.

## Verifying

```bash
flutter run -d <android-tv-device>
adb connect <tv-ip>:5555
adb shell input keyevent KEYCODE_DPAD_DOWN     # drive focus from the shell
adb exec-out screencap -p > shots/tv.png
```

Capture **with something focused**, or the screenshot proves nothing about the state the user actually sees. Walk the whole screen with the D-pad and confirm every control is reachable and every focus change is visible.

An emulator gives breadth. A real TV across a real room is the only thing that settles whether the type is large enough.
