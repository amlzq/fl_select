# Delegates

A `SelectDelegate` controls both data loading (`entries` directly or `entriesLoader` async) and how the body is rendered. It is passed to every entry point. The seven built-ins are single-purpose by data shape — each asserts on the data shape it does not support, so a mis-migration surfaces immediately.

**Flat data** — parentless `.name(...)` leaves:

| Delegate | Body |
| --- | --- |
| `ListSelectDelegate` | Single-column list. |
| `GridSelectDelegate` | Grid body (`crossAxisCount` required). |
| `WrapSelectDelegate` | Wrapable chip bar — the go-to for filter bars. |

### Custom item widgets — `itemBuilder` (0.12.0)

Each flat delegate accepts an `itemBuilder` (`SelectItemBuilder`) that fully replaces the default item widget — list tile, grid tile or chip:

```dart
GridSelectDelegate(
  crossAxisCount: 3,
  entriesLoader: _fetchPrice,
  itemBuilder: (context, entry, {required selected, required onTap}) {
    return InkWell(
      onTap: onTap, // keeps the library's normal selection flow
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        child: Text(entry.name ?? ''),
      ),
    );
  },
);
```

Rules: the builder renders its own selected-state visuals from `selected` and wires `onTap` (e.g. via `InkWell`) to its own gesture handler; custom range entries are not passed to the builder and keep rendering as the built-in min/max input field. Only used when rendering flat data (the deprecated two-level fallbacks on `ListSelectDelegate` / `GridSelectDelegate` do not forward it); two-level delegates customize per-category rendering via `category.layout` instead. `SelectChip` is publicly exported so builders can reuse the exact default chip visuals.

Underlying chip widgets (0.12.0 split): `SelectChipBar` renders a single fixed-height row (`kSelectChipBarHeight`) with the title to its left; `SelectWrapView` renders the wrapping multi-row form — what `WrapSelectDelegate` and `SelectWrapLayout` render internally — and always stacks the title above the chips. `SelectChipBar.isWrapable` / `runSpacing` / `direction` are deprecated in favor of `SelectWrapView`; the skeleton split mirrors it (`SelectChipBarSkeleton` wrap form → `SelectWrapViewSkeleton`). `SelectChip`, `SelectChipBarStyle` and `resolveSelectChipBarStyle` are publicly exported so custom `itemBuilder`s can reuse the built-in chip and its three-level style resolution. Style a `WrapSelectDelegate`'s chips via its `chipBarTheme` (`SelectChipBarTheme`: `variant` (filled/outlined), `chipColor`, `selectedChipColor`, `labelStyle`, `selectedLabelStyle`, `backgroundColor`, `padding`). Widget tests on built-in delegate trees should assert `find.byType(SelectWrapView)`, not `SelectChipBar`.

**Two-level (category) data** — a tree of `SelectCategoryEntry` roots:

| Delegate | Body |
| --- | --- |
| `CascadingSelectDelegate` | Tree select: categories on the left, cascading list on the right. Ignores `category.layout`. |
| `TabNavSelectDelegate` | Category tabs on top drive the content below; the tab bar hides with a single category. |
| `SideNavSelectDelegate` | Category sidebar on the left scrolls the single right column to the matching section. Best with `SelectionMode.multiple` and an "Any" entry. |
| `ExpandableSelectDelegate` | One expandable group per category; header/footer entries render as chip bars around the expanded content. |

`TabNavSelectDelegate`, `SideNavSelectDelegate` and `ExpandableSelectDelegate` badge a category (tab / sidebar item / expansion tile) that holds a real selection — driven by `SelectController.realSelectedCategories` (see [entry-points.md](entry-points.md)).

Deprecated dual-mode paths (0.11.0, still working via forwarding with a one-time warning): `ListSelectDelegate` / `GridSelectDelegate` fed two-level data forward to `ExpandableSelectDelegate` / `TabNavSelectDelegate` (without forwarding `itemBuilder`); `FlattenSelectDelegate` maps to `SideNavSelectDelegate` (two-level) / `WrapSelectDelegate` (flat). See the package's MIGRATION.md for the diffs.

Scrolling (0.11.1–0.12.0): every scrollable body uses `ChainingClampingScrollPhysics` — a touch drag past an edge hands the leftover drag (and fling momentum) to the enclosing page-level scrollable, restoring the native nested-scrolling feel with no changes required on hosting pages. In `SideNavSelectDelegate`, tapping a sidebar item animates that category's full section (including its top padding) to the top of the right column, and the sidebar highlights the category at the right column's scroll position.

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
| `SelectWrapLayout` (deprecated alias: `SelectChipLayout`) | Wrapping row of chips | `spacing`, `runSpacing` |
| `SelectCounterLayout` | Spin-box (`-` value `+`) stepping through `SelectTextEntry` children ("Any", "1", "1+", "2", ...) | — |
| `SelectRangeLayout` | "Price-range" control: range slider over two synced text fields; the category must expose exactly one custom `SelectRangeEntry` | `toText` |

```dart
SelectCategoryEntry(
  id: 'brand',
  name: 'Brand',
  layout: const SelectWrapLayout(spacing: 8, runSpacing: 8),
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
