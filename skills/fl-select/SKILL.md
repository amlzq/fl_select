---
name: fl-select
description: A Flutter package (fl_select) for building selection UIs (e.g. filter bar) on a composable architecture of entry points, delegates, and layouts — 5 entry points (`SelectView`, `PopupSelectButton`, `PopupSelectBar`, `showSelect`, `showModalBottomSelect`), 7 delegates (list, grid, wrap, cascading, tab-nav, side-nav, expandable), 5 category layouts (list, grid, wrap, range slider, counter), plus `SelectDelegate` and `SelectEntry` types. A2UI-ready, with single & multiple selection, sync/async loading, search filtering, theming, and i18n built in; includes a JSON entry-tree codec (`SelectEntryCodec`) and a GenUI bridge package (`fl_select_genui`). This skill should be used when building filter UIs, dropdown menus with categories, cascading/grid/list/chip selects, range pickers, or whenever working with fl_select APIs or `fl_select_genui`.
---

# fl_select

A Flutter package for building filter bars, cascading menus, and pickers.

> Applies to fl_select `>=0.11.0` (verified against `0.12.0`).

## Mental model (two orthogonal layers)

1. **Entry points** decide *where* the select appears:
   `SelectView` (inline) · `PopupSelectBar` (filter-bar tabs) · `PopupSelectButton` (single trigger) · `showSelect` (dialog) · `showModalBottomSelect` (bottom sheet).
2. **Delegates** decide *how* entries are laid out — seven single-purpose styles:
   flat data: `ListSelectDelegate` · `GridSelectDelegate` · `WrapSelectDelegate`; two-level (category) data: `CascadingSelectDelegate` · `TabNavSelectDelegate` · `SideNavSelectDelegate` · `ExpandableSelectDelegate`.

Any delegate plugs into any entry point — there is exactly one delegate parameter, no per-entry-point variants. Custom layouts come from subclassing `SelectDelegate`, not from new entry points; custom item widgets come from `itemBuilder` on the flat and layout-based category delegates (not `CascadingSelectDelegate`), not from subclassing.

Data reaches the delegate either synchronously (`entries`, `selectedEntries`, `resetEntries` passed directly — static data renders on the first frame, no skeleton) or asynchronously via loaders (`entriesLoader`: `Future<SelectEntries> Function()`, where `SelectEntries` is `Set<SelectEntry>`). Pass exactly one of `entries` / `entriesLoader`; sync data is fixed for a delegate's lifetime — create a new delegate when the data changes.

## Selection semantics (memorize)

- `SelectionMode.single` (default): tapping an item **applies immediately** (dialogs/sheets close and return the selection).
- `SelectionMode.multiple`: the action bar's "Apply" confirms; "Reset" clears without closing. An entry with `immediate: true` applies on tap and skips the action bar.
- Category-level modes are nullable and inherit: `SelectCategoryEntry.selectionMode` / `headerSelectionMode` / `footerSelectionMode` default to null — `selectionMode` inherits `delegate.selectionMode`, while header/footer modes inherit the category's effective mode; an explicit value overrides. Resolve non-null modes via `category.effectiveSelectionMode(delegate.selectionMode)` (also `effectiveHeaderSelectionMode` / `effectiveFooterSelectionMode`).

## Quick start

```dart
import 'package:fl_select/fl_select.dart';

Future<SelectEntries> _fetchPrice() async => {
      SelectCategoryEntry(
        id: 'price',
        name: 'Price',
        children: {
          SelectIntEntry.any(parentId: 'price', name: 'Any'),
          SelectIntEntry(parentId: 'price', id: '0-100', name: '0-100', min: 0, max: 100),
          SelectIntEntry.custom(parentId: 'price', name: 'Custom'),
        },
      ),
    };

// Inline
SelectView(
  delegate: GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchPrice),
  onChanged: (selected) { /* SelectEntries tree */ },
);

// Dialog — returns null when dismissed
final SelectEntries? selected = await showSelect(
  context: context,
  delegate: SideNavSelectDelegate(entriesLoader: _fetchPrice),
  title: const Text('Price'),
);
```

## Common pitfalls

- `GridSelectDelegate` requires `crossAxisCount`.
- The flat delegates (`ListSelectDelegate` / `GridSelectDelegate` / `WrapSelectDelegate`) and the layout-based category delegates (`TabNavSelectDelegate` / `SideNavSelectDelegate` / `ExpandableSelectDelegate`) accept an `itemBuilder` that fully replaces each item widget — render your own selected state from `selected`, wire `onTap` so taps flow through the library's normal selection flow, and branch per category on `categoryId` (the owning category's id; null on flat delegates). Returning null falls back to the default item widget; custom range entries still render as the built-in min/max input, the range-slider/counter category layouts keep their built-in controls, header/footer chips are not covered, and `CascadingSelectDelegate` ignores the builder.
- `SelectChipBar.isWrapable` is deprecated (0.12.0): `SelectChipBar` is now single-row only; use `SelectWrapView` for the wrapping multi-row form (`WrapSelectDelegate` renders it internally).
- `SelectController.badgedCategories` was renamed to `realSelectedCategories` (0.12.0); the old name is a deprecated alias. It returns the categories holding at least one non-"Any" selection and drives category badges and TabNavSelect's initial tab focus.
- Every delegate is single-purpose: `ListSelectDelegate` / `GridSelectDelegate` accept flat data only and assert on two-level data (use `ExpandableSelectDelegate` / `TabNavSelectDelegate` for categories); `FlattenSelectDelegate` is removed (use `SideNavSelectDelegate` for two-level or `WrapSelectDelegate` for flat).
- Only `CascadingSelectDelegate` navigates a tree; the other two-level delegates lay out each category's `children` according to `category.layout` (list / grid / chips / range slider / counter).
- `SelectChildEntry` is identified by its `parentId`. Prefer the `SelectCategoryEntry(children: {...})` factory, which injects `parentId` automatically.
- Use `SelectTextEntry.name(...)` / `SelectIntEntry.name(...)` (parentless leaves) for flat single-level lists.
- An "Any" entry (`.any(...)`) clears its category; in `toQueryMap()` it resolves to the parent id.
- Serialize results with `selected.toQueryMap()` / `selected.toQueryParameters(arrayFormat: ...)` for category trees, or `selected.toIdList()` for flat single-level panels — each throws `StateError` on the wrong structure, so misuse surfaces immediately; do not hand-walk the tree.

## JSON codec & GenUI bridge

- The repo is a melos + pub-workspace monorepo: core package at `packages/fl_select`, GenUI bridge at `packages/fl_select_genui`.
- `SelectEntryCodec.fromJson(list)` / `toJson(entries)` convert entry trees to/from declarative JSON (`type`: category / text / range / any / custom; `layout.kind`: list / grid / chip / counter / range). Prefer the codec over hand-building `SelectEntry` objects from dynamic data; it throws `FormatException` / `UnsupportedError` on bad payloads instead of silently dropping data.
- `fl_select_genui` wraps the codec as a GenUI (A2UI) `CatalogItem` (`FlSelectCatalogItems.selectFilter`) so AI agents can emit the JSON and get a live fl_select panel; selections are written back as a `Map<String, List<String>>` at `<id>.value`.

## Reference index

Read these on demand; do not guess APIs:

| Topic | File |
| --- | --- |
| Entry points (view, bar, button, dialog, sheet), controllers, callbacks | [references/entry-points.md](references/entry-points.md) |
| Delegates, per-category `layout`, shared delegate parameters | [references/delegates.md](references/delegates.md) |
| Entry tree (`SelectEntry` types, "Any", `immediate`, headers/footers) | [references/entries.md](references/entries.md) |
| Data loading (sync/async), initial selection, skeletons, search, serialization | [references/loading-search.md](references/loading-search.md) |
| Theming (`SelectThemeData`, theme extensions) and i18n | [references/theming-i18n.md](references/theming-i18n.md) |

Package: <https://pub.dev/packages/fl_select> · Playground: <https://flselect.zeaon.dev/>
