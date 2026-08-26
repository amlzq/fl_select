# fl_select example

A demo app covering every entry point of `fl_select`:

- `SelectView` — a select embedded in a page body (`view_example.dart`)
- `PopupSelectBar` — a tab bar opening overlay selects (`bar_example.dart`)
- `PopupSelectButton` — a single-trigger button (`button_example.dart`)
- `showSelect` — a select in a modal dialog (`dialog_example.dart`)
- `showModalBottomSelect` — a select in a modal bottom sheet (`bottom_sheet_example.dart`)

Each demo combines the built-in delegates (`CascadingSelectDelegate`, `GridSelectDelegate`, `ListSelectDelegate`, `FlattenSelectDelegate`) with async `entriesLoader` data, search filtering, theming, and i18n.

## Run

```bash
cd example
flutter run
```
