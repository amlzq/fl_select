# AGENTS.md

Guidance for AI coding agents and contributors working in this repository.

## Layout

Dart pub workspace (managed with Melos), three packages under `packages/`:

- `fl_select` — core selection UI package (published)
- `fl_select_genui` — A2UI/GenUI catalog integration (published)
- `fl_select_playground` — web playground (not published)

## Commands

Run from the repository root:

```bash
dart pub get && dart run melos bootstrap   # resolve the workspace
dart run melos run check:format            # dart format --set-exit-if-changed
dart run melos run check:analyze           # flutter analyze
dart run melos run test                    # tests for all packages
```

Run a single package's tests: `cd packages/<pkg> && flutter test`.

## Commits and PR titles

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`.

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- Scopes: `fl_select`, `fl_select_genui`, `fl_select_playground` (omit when a change spans packages)
- Breaking changes: add `!` after the type/scope, e.g. `refactor(fl_select_genui)!: migrate from genui to a2ui`
- PRs are squash-merged, so the **PR title** becomes the commit message and must follow this format.

## Rules

- Update the affected package's `CHANGELOG.md` (under `Unreleased`) for user-visible changes.
- Add or update tests for behavior changes.
- Do not hand-edit generated files, `pubspec.lock`, or bump versions unless asked.
