A customizable Flutter select widget for building filter bars, cascading menus, and pickers with single/multiple selection, async loading, theming, and i18n.

![Highlights](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/highlights.gif)

**`[Multiple Selection]` `[Async Loading]` `[5 Entry Points]` `[4 Delegate Layouts]` `[i18n ×10]`**

[Playground](https://flselect.zeaon.dev/)

### Features

Two layers work together: **entry points** decide _where_ the select appears, and **delegates** decide _how_ entries are laid out — any delegate plugs into any entry point.

- **Entry points** — five ways to show a select: `SelectView` (inline), `PopupSelectBar` (tab bar), `PopupSelectButton` (single trigger), `showSelect` (dialog), `showModalBottomSelect` (bottom sheet).
- **Delegates** — four layouts: `CascadingSelectDelegate` (tree), `GridSelectDelegate` (grid), `ListSelectDelegate` (single column), `FlattenSelectDelegate` (grid that keeps category grouping).
- Single & multiple selection via `SelectionMode` (per category or as a delegate fallback).
- Async data loading through `entriesLoader`.
- Flexible entries: the "Any" entry clears a category, `SelectRangeEntry.custom` takes user min/max input, and an `immediate` entry applies on tap without the action bar.
- `skeletonBuilder` & `errorBuilder` for loading and error states.
- Theming via `SelectThemeData` and the `PopupSelectBarTheme` / `PopupSelectButtonTheme` extensions.
- Built-in i18n in 10 languages via `SelectLocalizationsDelegate`.

### Getting started

#### Install

```bash
flutter pub add fl_select
```

#### Import

```dart
import 'package:fl_select/fl_select.dart';
```

### Usage

#### Delegates

A delegate controls both data loading and how the body is rendered, and any delegate works with every entry point above.

##### Common concepts

Entries form a tree. `SelectCategoryEntry` is the root (a category) and `SelectChildEntry` is any non-root node, identified by its `parentId`.

| Entry                    | Purpose                                                                                                                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SelectCategoryEntry`    | Root node. Holds `children` and the `selectionMode` for them.                                                                                                                 |
| `SelectTextEntry`        | A plain text leaf. Use `.any(...)` for the "Any" (clear) entry. `.name(...)` creates a parentless leaf for flat lists.                                                        |
| `SelectRangeEntry<N, E>` | A numeric range leaf (`min`/`max`). Use `.any(...)` for "Any" and `.custom(...)` for a user-input range. `SelectIntEntry<E>` is a handy alias for `SelectRangeEntry<int, E>`. |

Selection is controlled by `SelectionMode` (`single` by default, or `multiple`), set on a `SelectCategoryEntry` (per category) or on the delegate (fallback). In multiple-selection mode, an entry with `immediate: true` applies on tap and skips the action bar.

Entries load asynchronously via `entriesLoader`, which returns a `Future<SelectEntries>` where `SelectEntries` is `Set<SelectEntry>`.

```dart
// A category with single-selection children
SelectCategoryEntry(
  id: 'price',
  name: 'Price',
  children: {
    SelectRangeEntry<int, void>.any(parentId: 'price', name: 'Any'),
    SelectRangeEntry<int, void>(parentId: 'price', id: '0-100', name: '0-100', min: 0, max: 100),
    SelectRangeEntry<int, void>.custom(parentId: 'price', name: 'Custom'),
  },
);

// A multi-selection category
SelectCategoryEntry(
  id: 'more',
  name: 'More',
  selectionMode: SelectionMode.multiple,
  children: {
    SelectTextEntry.any(parentId: 'more', name: 'Any'),
    SelectTextEntry(parentId: 'more', id: 'near_subway', name: 'Near subway'),
  },
);

// Parentless leaves for a flat list
SelectTextEntry.name(id: 'default', name: 'Default');
```

The built-in delegates are:

| Delegate                  | Description                                                                                                             | Preview                                                                                                          |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `CascadingSelectDelegate` | A tree select: categories on the left, a cascading list on the right.                                                   | ![CascadingSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/cascading.jpg) |
| `GridSelectDelegate`      | A grid layout. `crossAxisCount` is required.                                                                            | ![GridSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/grid.jpg)           |
| `ListSelectDelegate`      | A single-column list (use `.name(...)` leaves for a flat list).                                                         | ![ListSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/list.jpg)           |
| `FlattenSelectDelegate`   | Renders children in a grid while keeping the category hierarchy. Best with `SelectionMode.multiple` and an "Any" entry. | ![FlattenSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/flatten.jpg)     |

#### SelectView

`SelectView` embeds a select directly in a page or dialog body. Pass any `delegate` from the [Delegates](#delegates) section above — it controls both loading and rendering.

```dart
SelectView(
  delegate: CascadingSelectDelegate(entriesLoader: _fetchNeighborhood),
  onChanged: (selected) {
    // selected is the SelectEntries when the selection changes
  },
);
```

#### PopupSelectBar

A tab bar (`PreferredSizeWidget`) that opens an overlay select when a tab is tapped. Provide `tabs` for the bar and a matching `selectDelegates` list (one per tab). Results arrive via `onChanged` / `onApplied` / `onReset`.

```dart
PopupSelectBar(
  tabs: const [
    PopupTab(label: 'Neighborhood'),
    PopupTab(label: 'Price'),
    PopupTab(label: 'Rooms'),
    PopupTab(label: 'More'),
    PopupTab(label: 'Sort'),
  ],
  selectDelegates: [
    CascadingSelectDelegate(entriesLoader: _fetchNeighborhood),
    GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchPrice),
    GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchRooms),
    FlattenSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchMore),
    ListSelectDelegate(entriesLoader: _fetchSort),
  ],
  onApplied: (tabData, selected) {
    // tabData is the PopupTabData; selected is the SelectEntries
  },
);
```

![PopupSelectBar](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/bar.gif)

#### PopupSelectButton

A single-trigger alternative to `PopupSelectBar` — opens a select overlay on tap, like `PopupMenuButton`. It takes one `selectDelegate` and a `label`/`child`. Three variants: filled (default), `.elevated(...)`, and `.outlined(...)`.

```dart
PopupSelectButton(
  label: 'Neighborhood',
  selectDelegate: GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchNeighborhood),
  onApplied: (tabData, selected) { /* ... */ },
);

PopupSelectButton.elevated(
  label: 'Price',
  selectDelegate: GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchPrice),
);

PopupSelectButton.outlined(
  label: 'Rooms',
  icon: const Icon(Icons.filter_alt_outlined),
  selectDelegate: GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchRooms),
);
```

![PopupSelectButton](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/button.gif)

#### showSelect

Shows a select in a modal dialog. Returns the selected `SelectEntries` when applied, or `null` when dismissed. In single-selection mode, tapping an item applies immediately; in multi-selection mode, "Apply" in the action bar confirms.

```dart
final SelectEntries? selected = await showSelect(
  context: context,
  delegate: FlattenSelectDelegate(entriesLoader: _fetchRooms),
  title: const Text('Rooms'),
);

if (selected != null) {
  // a selection was applied
}
```

![showSelect](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/dialog.gif)

#### showModalBottomSelect

Shows a select in a modal bottom sheet built on Flutter's `showModalBottomSheet`. Same interaction as `showSelect` (and its deprecated alias `showselect`). Standard sheet parameters (`isScrollControlled`, `isDismissible`, `enableDrag`, `showDragHandle`, `constraints`, etc.) are forwarded.

```dart
final SelectEntries? selected = await showModalBottomSelect(
  context: context,
  delegate: ListSelectDelegate(
    crossAxisCount: 3,
    selectionMode: SelectionMode.multiple,
    entriesLoader: _fetchMore,
  ),
  title: const Text('More'),
);

if (selected != null) {
  // a selection was applied
}
```

![showModalBottomSelect](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/bottom_sheet.gif)

#### Theming

**Per instance** — pass `selectTheme` to any select entry point (`SelectView`, `showSelect`, `showModalBottomSelect`, `PopupSelectBar`, `PopupSelectButton`):

```dart
SelectView(
  delegate: ListSelectDelegate(entriesLoader: _fetchSort),
  selectTheme: SelectThemeData(
    Theme.of(context),
    selectedColor: Theme.of(context).colorScheme.primary,
    onSelectedColor: Theme.of(context).colorScheme.onPrimary,
  ),
);
```

**Globally** — register `PopupSelectBarTheme` and `PopupSelectButtonTheme` as `ThemeData` extensions so every bar/button picks them up automatically:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      PopupSelectBarTheme(
        height: 48,
        labelColor: Colors.blue,
        selectTheme: SelectThemeData(ThemeData.light()),
      ),
      PopupSelectButtonTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    ],
  ),
);
```

#### Internationalization

Add `SelectLocalizationsDelegate()` to your `MaterialApp`. It ships translations for `de`, `en`, `es`, `fr`, `id`, `ja`, `ko`, `pt`, `vi`, and `zh` (Hans/Hant), localizing the "Apply" / "Reset" / "Multiple" labels automatically.

```dart
const localizationsDelegates = <LocalizationsDelegate>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  SelectLocalizationsDelegate(),
];

const supportedLocales = SelectLocalizationsDelegate.supportedLocales;

MaterialApp(
  localizationsDelegates: localizationsDelegates,
  supportedLocales: supportedLocales,
  home: const HomePage(),
);
```

To override the labels for a single delegate, set `applyText` / `resetText` on it directly.
