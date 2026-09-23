# harden

Make the screen survive reality: failures, empty data, long text, other languages, no network.

Start from `detect --only network-image-unguarded,fixed-height-text-box,missing-semantics,unbounded-list`.

## The four states

Every screen that loads anything needs all four. Generated code ships one.

- **Loading.** A skeleton in the shape of the real content. A centered spinner on a blank page tells the user nothing about what is coming.
- **Empty.** Says what goes here and how to create the first one. This is an onboarding surface, not an error — and it is the screen a new user sees first.
- **Error.** Names the problem and the recovery. "Something went wrong" names neither. The retry must actually retry.
- **Offline.** Phones lose signal. Say what is stale, what is queued, and what will happen when the connection returns.

```dart
switch (state) {
  Loading() => const _Skeleton(),
  Empty() => _Empty(onCreate: _create),
  Failed(:final error) => _Error(error: error, onRetry: _load),
  Ready(:final items) => _List(items: items),
}
```

## Images and network

`Image.network` needs `errorBuilder`, or a failed fetch renders a broken box. `loadingBuilder` keeps it from popping in. `cacheWidth`/`cacheHeight` stop a full-size image being decoded for a thumbnail.

Every network call needs a timeout. A request with no deadline is a spinner with no end.

## Text that does not fit

- `maxLines` plus `overflow: TextOverflow.ellipsis` anywhere content is user-supplied or translated.
- Translations run about 30% longer than English. German compounds and Japanese line breaking both break layouts that only saw English.
- Test at 200% text scale. Fixed-height boxes around text clip there first.
- Names, amounts and dates are the fields that surprise you. Try a long one.

## Input

- Validate on submit, not on every keystroke. Validating as the user types tells them they are wrong before they have finished being right.
- Error messages name the fix: "Password needs 8 characters" beats "Invalid password".
- Correct `keyboardType`, `textInputAction`, `autofillHints`. Autofill is accessibility.
- The focused field must not sit behind the keyboard. `resizeToAvoidBottomInset` plus a scrollable.

## i18n

- No user-facing string literal in a widget. Route them through `AppLocalizations` even if only one language ships today — retrofitting is much more expensive.
- Dates, numbers and currency through `intl`, not string interpolation.
- Do not build sentences by concatenation; word order differs by language.
- `Directionality` for RTL: use `EdgeInsetsDirectional` and `AlignmentDirectional` rather than left and right.

## Accessibility is part of hardening

`tooltip` on every `IconButton`. `Semantics(label:, button: true)` around a tap target with no text. `excludeFromSemantics: true` on decorative images. Announce state changes, not just labels.
