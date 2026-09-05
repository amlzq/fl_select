# fl_select

A monorepo for **fl_select** — a Flutter package for building selection UIs (e.g. filter bars) on a composable architecture of **entry points, delegates, and layouts**, with single & multiple selection, sync/async loading, search filtering, theming, and i18n built in.

[Playground](https://flselect.zeaon.dev/)

![Highlights](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/highlights.gif)

## Packages

| Package | Pub | Description |
| --- | --- | --- |
| [`packages/fl_select`](packages/fl_select) | [![pub package](https://img.shields.io/pub/v/fl_select.svg)](https://pub.dev/packages/fl_select) | Core select widgets. |
| [`packages/fl_select_genui`](packages/fl_select_genui) | [![pub package](https://img.shields.io/pub/v/fl_select_genui.svg)](https://pub.dev/packages/fl_select_genui) | GenUI / A2UI integration bridge. |
| [`packages/fl_select_playground`](packages/fl_select_playground) | — | Interactive playground. |

## Repository structure

```
fl_select/
├── packages/
│   ├── fl_select/            # Core package
│   ├── fl_select_genui/      # GenUI bridge
│   └── fl_select_playground/ # Interactive playground
├── screenshots/            # GIFs and images used by docs
├── skills/                 # Agent skills for AI coding assistants
└── pubspec.yaml            # Pub workspace root (managed with melos)
```

## Documentation

- Select widgets docs: [`packages/fl_select/README.md`](packages/fl_select/README.md)
- Changelog: [`packages/fl_select/CHANGELOG.md`](packages/fl_select/CHANGELOG.md)
- Migration guide: [`packages/fl_select/MIGRATION.md`](packages/fl_select/MIGRATION.md)
- GenUI integration docs: [`packages/fl_select_genui/README.md`](packages/fl_select_genui/README.md)
- Playground quickstart: [`packages/fl_select_playground/README.md`](packages/fl_select_playground/README.md)

## Development

This repo uses [melos](https://melos.invertible.dev/) to manage the workspace.

```bash
dart pub global activate melos
melos bootstrap   # install dependencies and link packages

melos run analyze
melos run test
```

## License

[MIT](LICENSE)
