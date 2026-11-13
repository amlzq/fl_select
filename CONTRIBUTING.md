# Contributing

Thanks for your interest in contributing to fl_select!

## Getting started

```bash
git clone https://github.com/amlzq/fl_select.git
cd fl_select
dart pub get
dart run melos bootstrap
```

The repository is a Dart pub workspace with three packages in `packages/`:
`fl_select`, `fl_select_genui` and `fl_select_playground`.

## Before opening a PR

```bash
dart run melos run check:format
dart run melos run check:analyze
dart run melos run test
```

CI runs the same checks. Please add or update tests for behavior changes and
add an entry to the affected package's `CHANGELOG.md` under `Unreleased`.

## Commit and PR title convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short summary
```

- **type**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **scope**: `fl_select`, `fl_select_genui` or `fl_select_playground`
  (optional when a change spans several packages)
- Append `!` for breaking changes, e.g. `refactor(fl_select_genui)!: migrate to a2ui`

Pull requests are squash-merged, so the PR title becomes the commit message.
CI checks the title format.

## Reporting issues

Use the issue templates: pick the one matching the affected package.
