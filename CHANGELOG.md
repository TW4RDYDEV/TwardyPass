# Changelog

## 1.1.0 — 2026-09-14

Major product update evolving TwardyPass into a more polished privacy-first password security workbench.

### Design and architecture
- Cold dark visual system, TP identity, system typography, reusable QML controls.
- Six focused pages replace the monolithic Main.qml.
- Animated score ring, five-axis radar with explicit unknown breach safety,
  readable findings, responsive vertical scrolling and equal Compare columns.

### Features
- Generator presets, custom exclusions and exact constrained-space entropy.
- Configurable passphrase capitalization and optional secure number/symbol suffixes.
- Policy Lab presets/custom rules and individual pass/fail results.
- Sanitized JSON/PDF reports and optional aggregate session statistics.
- Offline mode, masking preference, clipboard/inactivity controls and About page.
- Local license classification using the unchanged bundled LICENSE.

### Security and fixes
- Remove matched password fragments from findings; use typed report allowlists.
- Hash before dispatching a breach worker; discard stale/cleared/offline responses.
- Reject redirects/malformed responses; redact transport exception details.
- Shared panic clear and shutdown cleanup; preserve unrelated clipboard contents.
- Retain long-input analysis and text transport of large guess counts.
- Keep all generation on cryptographic randomness; enforce impossible exclusions.

### Packaging and validation
- Central version metadata, Windows icon and version resource, PyInstaller spec,
  PowerShell build script and local GitHub Actions definitions.
- Preserve original tests, screenshots, LICENSE and funding configuration.
- Add backend, report sanitization and Qt integration regression coverage.
