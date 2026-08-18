# Delegates

A `SelectDelegate` controls both data loading (`entriesLoader`) and how the body is rendered. It is passed to every entry point. The four built-ins:

| Delegate | Body |
| --- | --- |
| `CascadingSelectDelegate` | Tree select: categories on the left, cascading list on the right. Ignores `category.layout`. |
| `GridSelectDelegate` | Grid body (`crossAxisCount` required). Each category's children follow `category.layout` (default grid). |
| `ListSelectDelegate` | Single-column list. Use `.name(...)` leaves for a flat list; children follow `category.layout` (default list). |
| `FlattenSelectDelegate` | Renders children by `category.layout` (default chips) under a category sidebar synced to the scrolling column. Best with `SelectionMode.multiple` and an "Any" entry. |

```dart
PopupSelectBar(
  tabs: const [PopupTab(label: 'Price')],
  selectDelegates: [
    GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchPrice),
  ],
  onApplied: (tabData, selected) {},
);
```

## Shared constructor parameters (all delegates)

**Data**
- `entriesLoader` (required): `Future<SelectEntries> Function()` — async-first, every load is async.
- `selectedEntriesLoader`: `Future<SelectEntries?> Function()` — async initial selection (e.g. restore from a saved filter).
- `resetEntriesLoader`: `Future<SelectEntries?> Function()` — selection to restore after "Reset"; defaults to the initial load.
- `selectionMode`: delegate-level fallback when a category doesn't set its own.

**Search**
- `searchEnabled` — renders a `SelectSearchBar` above the body.
- `searchPredicate` (`bool Function(SelectEntry, String)`; default `defaultSelectSearchPredicate`, case-insensitive substring on `name`).
- `searchHintText`, `searchDebounceDuration` (default 300 ms).

**Action bar**
- `applyText`, `resetText` — override the localized labels.
- `actionBarBuilder` — replace the action bar entirely.

**Loading / error states**
- `skeletonBuilder`, `errorBuilder` — see [async-search.md](async-search.md).

**Styling** (details in [theming-i18n.md](theming-i18n.md))
- `selectedColor`, `onSelectedColor`.
- Fine-grained `*Theme` fields: `categoryTheme`, `bodyTheme`, `categoryItemTheme`, `entryTheme`, `rangeEntryTheme`, `counterEntryTheme`, `actionBarTheme`, `searchBarTheme`, `skeletonTheme`, `panelTheme` (panel background decoration).

`GridSelectDelegate` additionally requires `crossAxisCount`.

## Category layouts (`category.layout`)

In every delegate except `CascadingSelectDelegate`, each `SelectCategoryEntry.layout` decides how that category's children are rendered:

| Layout | Renders | Notable params |
| --- | --- | --- |
| `SelectListLayout` | Vertical list of tiles; a custom range entry becomes an input field | `toText` (separator between min/max fields, default `'-'`) |
| `SelectGridLayout` | Grid of tiles | `crossAxisCount` (required), `mainAxisSpacing`, `crossAxisSpacing`, `childAspectRatio`, `toText` |
| `SelectChipLayout` | Wrapping row of chips | `spacing`, `runSpacing` |
| `SelectCounterLayout` | Spin-box (`-` value `+`) stepping through `SelectTextEntry` children ("Any", "1", "1+", "2", ...) | — |
| `SelectRangeLayout` | "Price-range" control: range slider over two synced text fields; the category must expose exactly one custom `SelectRangeEntry` | `toText` |

```dart
SelectCategoryEntry(
  id: 'brand',
  name: 'Brand',
  layout: const SelectChipLayout(spacing: 8, runSpacing: 8),
  selectionMode: SelectionMode.multiple,
  children: {
    SelectTextEntry(parentId: 'brand', id: 'a', name: 'Apple'),
    SelectTextEntry(parentId: 'brand', id: 'b', name: 'Google'),
  },
);
```

Default per delegate: `GridSelectDelegate` → grid, `ListSelectDelegate` → list, `FlattenSelectDelegate` → chips. A category can override the default with any layout, mixing layouts within one select.

## Custom delegates

Subclass `SelectDelegate` for a fully custom body (e.g. a calendar). The delegate contract covers loading, search, selection state, and the action bar; entry points accept any subclass unchanged.
