# Delegates

A `SelectDelegate` controls both data loading (`entries` directly or `entriesLoader` async) and how the body is rendered. It is passed to every entry point. The seven built-ins are single-purpose by data shape — each asserts on the data shape it does not support, so a mis-migration surfaces immediately.

**Flat data** — parentless `.name(...)` leaves:

| Delegate | Body |
| --- | --- |
| `ListSelectDelegate` | Single-column list. |
| `GridSelectDelegate` | Grid body (`crossAxisCount` required). |
| `WrapSelectDelegate` | Wrapable chip bar — the go-to for filter bars. |

**Two-level (category) data** — a tree of `SelectCategoryEntry` roots:

| Delegate | Body |
| --- | --- |
| `CascadingSelectDelegate` | Tree select: categories on the left, cascading list on the right. Ignores `category.layout`. |
| `TabNavSelectDelegate` | Category tabs on top drive the content below; the tab bar hides with a single category. |
| `SideNavSelectDelegate` | Category sidebar on the left scrolls the single right column to the matching section. Best with `SelectionMode.multiple` and an "Any" entry. |
| `ExpandableSelectDelegate` | One expandable group per category; header/footer entries render as chip bars around the expanded content. |

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

**Data** (sync values are fixed for a delegate's lifetime — create a new delegate when the data changes)
- `entries`: `SelectEntries` passed directly — static data rendered on the first frame with no skeleton. Exactly one of `entries` / `entriesLoader` is required (enforced by assert).
- `entriesLoader`: `Future<SelectEntries> Function()` — async loading, the alternative to `entries`.
- `selectedEntries`: `SelectEntries` passed directly — initial selection without invoking a loader. At most one of `selectedEntries` / `selectedEntriesLoader`.
- `selectedEntriesLoader`: `Future<SelectEntries?> Function()` — async initial selection (e.g. restore from a saved filter).
- `resetEntries`: `SelectEntries` passed directly — selection restored after "Reset". At most one of `resetEntries` / `resetEntriesLoader`.
- `resetEntriesLoader`: `Future<SelectEntries?> Function()` — async "Reset" target; defaults to the initial load.
- `selectionMode`: delegate-level fallback when a category doesn't set its own.

```dart
ListSelectDelegate(
  entries: {...},          // static data, first frame
  selectedEntries: {...},  // optional initial selection
  resetEntries: {...},     // optional "Reset" target
);
```

**Search**
- `searchEnabled` — renders a `SelectSearchBar` above the body.
- `searchPredicate` (`bool Function(SelectEntry, String)`; default `defaultSelectSearchPredicate`, case-insensitive substring on `name`).
- `searchHintText`, `searchDebounceDuration` (default 300 ms).

**Action bar**
- `applyText`, `resetText` — override the localized labels.
- `actionBarBuilder` — replace the action bar entirely.

**Loading / error states**
- `skeletonBuilder`, `errorBuilder` — see [loading-search.md](loading-search.md).

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

Resolution order: the category's `layout` → the two-level delegate's `defaultLayout` (`TabNavSelectDelegate` → 3-column grid, `SideNavSelectDelegate` → chips, `ExpandableSelectDelegate` → list). A category can override with any layout, mixing layouts within one select.

## Custom delegates

Subclass `SelectDelegate` for a fully custom body (e.g. a calendar). The delegate contract covers loading, search, selection state, and the action bar; entry points accept any subclass unchanged.
