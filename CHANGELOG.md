# Changelog

## 0.1.0 — 2026-09-23

### Detector

- 69 rules across four target surfaces (`phone`, `tablet`, `tv`, `web`). 46 of upstream impeccable's 61 rules are ported; each names its source in `portOf`, checked by a test.
- `--target` decides which rules run and what their thresholds are. A TV build is not a phone build: tap targets do not exist, the text floor rises to 20sp, and five focus rules switch on.
- `--baseline` / `--write-baseline` for adopting on a codebase that was not built against the detector. Entries key on the source line's text, not its number, so editing above a finding does not resurrect it.
- Design-system conformance against the project's own `DESIGN.md`, and font and asset conformance against `pubspec.yaml`.
- `signals` reports what a project already is, including inferring a TV target from a `LEANBACK_LAUNCHER` intent.
- `--format github` for CI annotations; `--json` for everything else.
- A custom_lint plugin in `lint/` surfaces the same findings in VS Code and IntelliJ, inferring the target from the project rather than asking for configuration.
- Ships as a standalone binary with a launcher, so no calling project needs a pubspec entry or a Dart SDK.

### Skill

- `SKILL.md` plus 18 reference playbooks: the Flutter platform contract, TV, theming, type, layout, color, motion, hardening, adaptivity, and verification.
- `init` asks once whether to build plain or shape the direction first, after reading `signals` so it never asks what the project already answers.
- `vibe` shows two or three visual directions as an artifact instead of interviewing.
- `capture-conditions` walks light, dark and large text off a device and restores its settings afterwards.

### Known gaps

- 12 upstream rules need rendered geometry and are covered by `verify.md` rather than ported; 3 more are skipped deliberately, with reasons in the README.
- `capture-conditions` has been verified against a stubbed `adb`, not a real device.
- `vibe` has not been run end to end.

## Versioning

The detector and the skill version together. `CHANGELOG.md` records what changed; `detector/pubspec.yaml` and the skill frontmatter carry the number.
