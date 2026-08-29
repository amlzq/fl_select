# fl_select

A monorepo for **fl_select** — a customizable Flutter select widget for building filter bars, cascading menus, and pickers with single/multiple selection, async loading, search filtering, theming, and i18n.

![Highlights](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/highlights.gif)

## Packages

| Package | Pub | Description |
| --- | --- | --- |
| [`packages/fl_select`](packages/fl_select) | [![pub package](https://img.shields.io/pub/v/fl_select.svg)](https://pub.dev/packages/fl_select) | Core select widgets: `SelectView`, delegates (`ListSelectDelegate`, `GridSelectDelegate`, `WrapSelectDelegate`, `CascadingSelectDelegate`, `TabNavSelectDelegate`, `SideNavSelectDelegate`, `ExpandableSelectDelegate`), popup bar/button, dialogs, and bottom sheets. |
| [`packages/fl_select_genui`](packages/fl_select_genui) | [![pub package](https://img.shields.io/pub/v/fl_select_genui.svg)](https://pub.dev/packages/fl_select_genui) | [GenUI SDK](https://pub.dev/packages/genui) / A2UI integration: ready-made `CatalogItem`s so conversational AI agents can render fl_select widgets and receive selections as structured data. |
| [`packages/fl_select_playground`](packages/fl_select_playground) | — | Interactive playground for fl_select: live preview of `SelectView`, `PopupSelectBar`, `PopupSelectButton`, etc. with a control panel for behavior/appearance params and Zillow / 乐有家 demo data sources. Not published to pub. |

## Repository structure

```
fl_select/
├── packages/
│   ├── fl_select/            # Core package (lib / test / example)
│   ├── fl_select_genui/      # GenUI bridge
│   └── fl_select_playground/ # Interactive playground (not published)
├── screenshots/            # GIFs and images used by docs
├── skills/                 # Agent skills for AI coding assistants
└── pubspec.yaml            # Pub workspace root (managed with melos)
```

## Documentation

- Full documentation, delegate reference, and live playground: [`packages/fl_select/README.md`](packages/fl_select/README.md)
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

The example app (web demo) lives at [`packages/fl_select/example`](packages/fl_select/example) and is deployed to GitHub Pages / Cloudflare Pages on pushes to `main`.

## License

[MIT](LICENSE)
