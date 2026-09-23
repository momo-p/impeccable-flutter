# verify

The web version of this tooling drives a browser: it picks elements, reads computed styles, and measures contrast on the rendered page. Flutter paints to a canvas, so none of that exists here. This is the replacement.

Verification runs in **bounded passes**. Build fully, capture once across the device classes you ship to, fix everything the round shows in one batch, confirm with at most one more round, stop. Open-ended self-QA burns the user's budget doing worse what a golden test does.

## 1. Static pass

```bash
dart run impeccable_flutter detect lib --fail-on error
flutter analyze
```

The two catch different things and neither substitutes for the other. `flutter analyze` finds Dart defects; the detector finds design defects. A screen can be analyzer-clean and still be the default app.

## 2. Capture

Screenshots come from a device or emulator. Never a browser, even when the app runs on Flutter web — the web build does not have the platform's insets, text scaling, or system bars.

```bash
flutter devices
flutter run -d <device-id>
flutter screenshot --out=shots/phone-light.png      # from a running session
```

On Android, `adb exec-out screencap -p > shots/phone.png` (`adb -s <serial>` with several attached). On iOS, `xcrun simctl io booted screenshot shots/phone.png`, replacing `booted` with the UDID from `xcrun simctl list devices booted` when more than one is running — display names collide, UDIDs do not.

Capture every device class the app ships to: at least one phone, and a tablet when tablets are a target.

## 3. The four conditions that break layouts

A single default-phone screenshot proves almost nothing. These four are where generated Flutter code fails, and each is one command:

- **Dark scheme.** `adb shell cmd uimode night yes`, or `xcrun simctl ui booted appearance dark`. Hard-coded colors show up here and nowhere else.
- **Large text.** `adb shell settings put system font_scale 1.5` (restore `1.0`). Clipped labels and fixed-height text boxes show up here.
- **Small phone.** A 5-inch class device. Oversized headlines and fixed widths show up here.
- **Tablet or split view.** Phone layouts stretched to fill a tablet show up here.

## 4. What the eye still owns

The detector cannot see these; look for them in the captures:

- Text occluded by an overlapping widget, or clipped by a parent's `overflow`.
- A line of body text running the full width of a tablet.
- A layout overflow stripe. Yellow-and-black in debug; in release it is silently clipped content, which is worse.
- Images that failed to load rendering as a broken box.
- Spacing rhythm: whether the screen has groups, or just evenly-spread widgets.
- Whether the screen has a point of view at all.

## 5. Lock it in

A screenshot proves today. A golden test proves every day after.

```dart
testWidgets('settings screen matches its golden', (tester) async {
  await tester.pumpWidget(const TestBedApp());
  await expectLater(
    find.byType(SettingsScreen),
    matchesGoldenFile('goldens/settings.png'),
  );
});
```

Run with `flutter test --update-goldens` once, review the image, then commit it. Golden tests over the dark scheme and at `TextScaler.linear(2.0)` cover the two conditions that regress most:

```dart
await tester.pumpWidget(MediaQuery(
  data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
  child: const TestBedApp(),
));
```

## Reporting

Say which device and which conditions produced the evidence. Emulators give breadth; gesture feel, refresh rate and real performance need hardware, and a claim about any of those from an emulator capture is not supported.
