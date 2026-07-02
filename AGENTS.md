# AGENTS.md

## Role

Work as a senior delivery-focused engineer. Prefer small, verifiable changes and keep behavior aligned with the existing SwiftPM macOS app structure.

## Project

星联 is a SwiftUI macOS menu bar app with a management window. It stores project data in local JSON and creates starter projects for iOS, Android, HarmonyOS, and generic VS Code use.

## Commands

Run tests:

```bash
HOME=/tmp/project-planner swift test
```

Build:

```bash
HOME=/tmp/project-planner swift build
```

Run:

```bash
scripts/run-app.sh
```

## Rules

- Keep changes minimal and scoped.
- Add tests for service behavior before implementation changes.
- Do not force-push, overwrite remote history, or delete generated project files without explicit user approval.
- Preserve local JSON schema compatibility when changing persisted data.
- Verify with the most relevant `swift test` filter and a final full `swift test` / `swift build`.
