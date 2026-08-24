A customizable Flutter select widget for building filter bars, cascading menus, and pickers with single/multiple selection, async loading, search filtering, theming, and i18n.

[Playground](https://flselect.zeaon.dev/)

![Highlights](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/highlights.gif)

### Agent Skills

This repo bundles an [Agent Skill](https://skills.sh/) so AI coding agents (Claude Code, Cursor, Codex, Windsurf, GitHub Copilot, etc.) use `fl_select` correctly — accurate APIs, no hallucinated parameters.

Install it with:

```bash
npx skills add amlzq/fl_select
```

Then just ask your agent to build a filter bar or select UI with `fl_select`. The skill lives in [`skills/fl-select`](https://github.com/amlzq/fl_select/tree/main/skills/fl-select).

### Features

Two layers work together: **entry points** decide _where_ the select appears, and **delegates** decide _how_ entries are laid out — any delegate plugs into any entry point.

- **Entry points** — five ways to show a select: `SelectView` , `PopupSelectBar` , `PopupSelectButton` , `showSelect` , `showModalBottomSelect` .
- **Delegates** — four navigation styles: `CascadingSelectDelegate` , `GridSelectDelegate` , `ListSelectDelegate` , `FlattenSelectDelegate` . In all but the cascading one, each category's children are laid out by `category.layout` — list / grid / chips / range slider / counter.
- Single & multiple selection via `SelectionMode` (per category or as a delegate fallback).
- Async data loading through `entriesLoader`, or synchronous data via `entries` / `selectedEntries` / `resetEntries` (rendered on the first frame, no skeleton).
- Search filtering: set `searchEnabled` on any delegate and a `SelectSearchBar` filters entries as you type (debounced, with a customizable predicate and theme).
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

The built-in delegates are:

| Delegate                  | Description                                                                                                             | Preview                                                                                                          |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `CascadingSelectDelegate` | A tree select: categories on the left, a cascading list on the right.                                                   | ![CascadingSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/cascading.jpg) |
| `GridSelectDelegate`      | A grid layout (`crossAxisCount` is required; children follow `category.layout`, default grid).                                                                            | ![GridSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/grid.jpg)           |
| `ListSelectDelegate`      | A single-column list (use `.name(...)` leaves for a flat list; children follow `category.layout`, default list).                                                         | ![ListSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/list.jpg)           |
| `FlattenSelectDelegate`   | Renders children by `category.layout` (default chips) under a category sidebar synced to the scrolling column. Best with `SelectionMode.multiple` and an "Any" entry. | ![FlattenSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/flatten.jpg)     |

#### SelectEntry

Entries form a tree. `SelectCategoryEntry` is the root (a category) and `SelectChildEntry` is any non-root node, identified by its `parentId`.

| Entry                    | Purpose                                                                                                                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SelectCategoryEntry`    | Root node. Holds `children` and the `selectionMode` for them.                                                                                                                 |
| `SelectTextEntry`        | A plain text leaf. Use `.any(...)` for the "Any" (clear) entry. `.name(...)` creates a parentless leaf for flat lists.                                                        |
| `SelectRangeEntry<N, E>` | A numeric range leaf (`min`/`max`). Use `.any(...)` for "Any" and `.custom(...)` for a user-input range. `SelectIntEntry<E>` is a handy alias for `SelectRangeEntry<int, E>`. |

Selection is controlled by `SelectionMode` (`single` by default, or `multiple`), set on a `SelectCategoryEntry` (per category) or on the delegate (fallback). In multiple-selection mode, an entry with `immediate: true` applies on tap and skips the action bar.

Entries load asynchronously via `entriesLoader`, which returns a `Future<SelectEntries>` where `SelectEntries` is `Set<SelectEntry>`. For static data, skip the loader and pass the values directly — mutually exclusive with the loaders:

```dart
// A category with single-selection children
SelectCategoryEntry(
  id: 'price',
  name: 'Price',
  children: {
    SelectIntEntry.any(parentId: 'price', name: 'Any'),
    SelectIntEntry(parentId: 'price', id: '0-100', name: '0-100', min: 0, max: 100),
    SelectIntEntry.custom(parentId: 'price', name: 'Custom'),
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

```dart
// Static data: no loader, no async — renders on the first frame
ListSelectDelegate(
  entries: {SelectTextEntry.name(id: 'relevance', name: 'Relevance')},
  selectedEntries: {SelectTextEntry.name(id: 'relevance', name: 'Relevance')},
  resetEntries: {SelectTextEntry.name(id: 'relevance', name: 'Relevance')},
);
```

#### SelectView

`SelectView` embeds a select directly in a page or dialog body. Pass any `delegate`  — it controls both loading and rendering.

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
    FlattenSelectDelegate(entriesLoader: _fetchMore),
    ListSelectDelegate(entriesLoader: _fetchSort),
  ],
  onApplied: (tabData, selected) {
    // tabData is the PopupTabData; selected is the SelectEntries
  },
);
```

![PopupSelectBar](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/atx/bar.gif)

#### PopupSelectButton

A single-trigger alternative to `PopupSelectBar` — opens a select overlay on tap, like `PopupMenuButton`. It takes one `selectDelegate` and a `label`/`child`. Four variants: text (default), `.filled(...)`, `.elevated(...)`, and `.outlined(...)`.

```dart
PopupSelectButton(
  label: 'Neighborhood',
  selectDelegate: GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchNeighborhood),
  onApplied: (selected) { /* ... */ },
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

Shows a select in a modal bottom sheet built on Flutter's `showModalBottomSheet`. Same interaction as `showSelect`. Standard sheet parameters (`isScrollControlled`, `isDismissible`, `enableDrag`, `showDragHandle`, `constraints`, etc.) are forwarded.

```dart
final SelectEntries? selected = await showModalBottomSelect(
  context: context,
  delegate: ListSelectDelegate(
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

#### Search

Set `searchEnabled: true` on any delegate to render a `SelectSearchBar` above the body. Typing filters the displayed entries (debounced 300 ms by default) while preserving the layout and selection state — canceling the search restores the original entries.

```dart
CascadingSelectDelegate(
  entriesLoader: _fetchNeighborhood,
  searchEnabled: true,
  searchHintText: 'Search',
  searchDebounceDuration: const Duration(milliseconds: 300),
  // searchPredicate: (entry, query) => ..., // defaults to a case-insensitive
  //                                        // substring match on SelectEntry.name
);
```

The default predicate (`defaultSelectSearchPredicate`) matches `SelectEntry.name` case-insensitively; provide a custom `searchPredicate` to match `id`, `extra`, or any other field. Style the bar via `searchBarTheme` (`SelectSearchBarTheme`) on the delegate, or globally through `SelectThemeData`.

#### Serializing selections

Selections arrive as a `SelectEntries` tree. Two extensions turn that tree into URL query parameters — each category contributes key/value pairs keyed by its own id with the deepest selected leaf ids as values; an "Any" leaf resolves to its parent id; a custom `SelectRangeEntry` formats as `min-max`:

```dart
final selected = await showSelect(context: context, delegate: ...);

// Map<String, List<String>>, mirroring Uri.queryParametersAll
final map = selected?.toQueryMap(); // {price: [0-100], more: [near_subway]}

// Or a ready-made query string
selected?.toQueryParameters(); // price=0-100&more=near_subway

// Multi-value layouts via SelectArrayFormat
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.brackets); // more[]=a&more[]=b
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.comma);    // more=a,b
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.indices);  // more[0]=a
selected?.toQueryParameters(
  arrayFormat: SelectArrayFormat.delimited,
  delimiter: '|',
); // more=a|b (covers OpenAPI pipeDelimited / spaceDelimited)
```

Values are percent-encoded by default; pass `encode: false` when the caller handles encoding.

#### Theming

**Per instance** — delegates carry the styling: set `selectedColor` / `onSelectedColor` (or any finer-grained `*Theme` field) directly on a delegate. `PopupSelectBar` also accepts a single `selectTheme` that overrides the styling of every tab's delegate:

```dart
ListSelectDelegate(
  entriesLoader: _fetchSort,
  selectedColor: Theme.of(context).colorScheme.primary,
  onSelectedColor: Theme.of(context).colorScheme.onPrimary,
);

PopupSelectBar(
  tabs: ...,
  selectDelegates: ...,
  selectTheme: SelectThemeData(Theme.of(context)),
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
