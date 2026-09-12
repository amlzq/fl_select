# Delegates

A `SelectDelegate` controls both data loading (`entries` directly or `entriesLoader` async) and how the body is rendered. It is passed to every entry point. The seven built-ins are single-purpose by data shape — each asserts on the data shape it does not support, so a mis-migration surfaces immediately.

**Flat data** — parentless `.name(...)` leaves:

| Delegate | Body |
| --- | --- |
| `ListSelectDelegate` | Single-column list. |
| `GridSelectDelegate` | Grid body (`crossAxisCount` required). |
| `WrapSelectDelegate` | Wrapable chip bar — the go-to for filter bars. |

### Custom item widgets — `itemBuilder` (0.12.0; category delegates + `categoryId` + null fallback since 0.13.0)

The flat delegates (`ListSelectDelegate` / `GridSelectDelegate` / `WrapSelectDelegate`) and the three layout-based category delegates (`TabNavSelectDelegate` / `SideNavSelectDelegate` / `ExpandableSelectDelegate`) accept an `itemBuilder` (`SelectItemBuilder`) that fully replaces the default item widget — list tile, grid tile or chip:

```dart
GridSelectDelegate(
  crossAxisCount: 3,
  entriesLoader: _fetchPrice,
  itemBuilder: (context, entry, {required selected, required onTap, categoryId}) {
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

Rules: the builder renders its own selected-state visuals from `selected` and wires `onTap` (e.g. via `InkWell`) to its own gesture handler; custom range entries are not passed to the builder and keep rendering as the built-in min/max input field. `categoryId` carries the owning `SelectCategoryEntry.id` on category delegates and is null on flat delegates, so one builder can branch per category (e.g. render price tiles only for the price category and return null elsewhere). Returning **null** falls back to the default item widget — customize only some entries or categories while keeping the built-in visuals elsewhere.

Scope on category delegates: applies to categories laid out as list, grid or wrap (via `category.layout`); the range-slider and counter layouts keep their built-in controls, and a category's header/footer chips are never passed to the builder. `CascadingSelectDelegate` ignores `itemBuilder` (its nodes render per level; a node builder may arrive later). Builders render their own chip visuals, styled to match `SelectChipBarTheme` (the built-in `SelectChip` is no longer part of the public API).

Underlying chip widgets (0.12.0 split): `SelectChipBar` renders a single fixed-height row (`kSelectChipBarHeight`) with the title to its left; `SelectWrapView` renders the wrapping multi-row form — what `WrapSelectDelegate` and `SelectWrapLayout` render internally — and always stacks the title above the chips. `SelectChipBar.isWrapable` / `runSpacing` / `direction` are deprecated in favor of `SelectWrapView`; the skeleton split mirrors it (`SelectChipBarSkeleton` wrap form → `SelectWrapViewSkeleton`). `SelectChip`, `SelectChipBarStyle` and `resolveSelectChipBarStyle` are no longer part of the public API — custom `itemBuilder`s render their own chips, resolving visuals from `SelectChipBarTheme`. Style a `WrapSelectDelegate`'s chips via its `chipBarTheme` (`SelectChipBarTheme`: `variant` (filled/outlined), `chipColor`, `selectedChipColor`, `labelStyle`, `selectedLabelStyle`, `backgroundColor`, `padding`). Widget tests on built-in delegate trees should assert `find.byType(SelectWrapView)`, not `SelectChipBar`.

**Two-level (category) data** — a tree of `SelectCategoryEntry` roots:

| Delegate | Body |
| --- | --- |
| `CascadingSelectDelegate` | Tree select: categories on the left, cascading list on the right. Ignores `category.layout`. |
| `TabNavSelectDelegate` | Category tabs on top drive the content below; the tab bar hides with a single category. |
| `SideNavSelectDelegate` | Category sidebar on the left scrolls the single right column to the matching section. Best with `SelectionMode.multiple` and an "Any" entry. |
| `ExpandableSelectDelegate` | One expandable group per category; header/footer entries render as chip bars around the expanded content. |

`TabNavSelectDelegate`, `SideNavSelectDelegate` and `ExpandableSelectDelegate` badge a category (tab / sidebar item / expansion tile) that holds a real selection — driven by `SelectController.realSelectedCategories` (see [entry-points.md](entry-points.md)).

Scrolling (0.11.1–0.12.0): every scrollable body uses `ChainingClampingScrollPhysics` — a touch drag past an edge hands the leftover drag (and fling momentum) to the enclosing page-level scrollable, restoring the native nested-scrolling feel with no changes required on hosting pages. Since the next release, chaining follows the inner-first order of `NestedScrollView` and browsers: dragging back scrolls the body first, and the leftover only reaches the enclosing page once the body hits its edge. In `SideNavSelectDelegate`, tapping a sidebar item animates that category's full section (including its top padding) to the top of the right column, and the sidebar highlights the category at the right column's scroll position.

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
| `SelectWrapLayout` | Wrapping row of chips | `spacing`, `runSpacing` |
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
