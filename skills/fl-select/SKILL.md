---
name: fl-select
description: A customizable Flutter select widget (the fl_select package) for filter bars, cascading menus, and pickers with single/multiple selection, async loading, search filtering, theming, and i18n. Use this skill when building filter UIs, dropdown menus with categories, cascading/grid/list/chip selects, range pickers, or whenever working with fl_select APIs (SelectView, PopupSelectBar, PopupSelectButton, showSelect, showModalBottomSelect, SelectDelegate, SelectEntry).
---

# fl_select

A Flutter package for building filter bars, cascading menus, and pickers.

## Mental model (two orthogonal layers)

1. **Entry points** decide *where* the select appears:
   `SelectView` (inline) · `PopupSelectBar` (filter-bar tabs) · `PopupSelectButton` (single trigger) · `showSelect` (dialog) · `showModalBottomSelect` (bottom sheet).
2. **Delegates** decide *how* entries are laid out:
   `CascadingSelectDelegate` · `GridSelectDelegate` · `ListSelectDelegate` · `FlattenSelectDelegate`.

Any delegate plugs into any entry point — there is exactly one delegate parameter, no per-entry-point variants. Custom layouts come from subclassing `SelectDelegate`, not from new entry points.

Data always loads through the delegate's `entriesLoader` (async-first): `Future<SelectEntries> Function()` where `SelectEntries` is `Set<SelectEntry>`.

## Selection semantics (memorize)

- `SelectionMode.single` (default): tapping an item **applies immediately** (dialogs/sheets close and return the selection).
- `SelectionMode.multiple`: the action bar's "Apply" confirms; "Reset" clears without closing. An entry with `immediate: true` applies on tap and skips the action bar.
- `SelectionMode` is set per category (`SelectCategoryEntry.selectionMode`) or as a delegate-level fallback (`delegate.selectionMode`).

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
  delegate: FlattenSelectDelegate(entriesLoader: _fetchPrice),
  title: const Text('Price'),
);
```

## Common pitfalls

- `GridSelectDelegate` requires `crossAxisCount`.
- Only `CascadingSelectDelegate` navigates a tree; the other three delegates lay out each category's `children` according to `category.layout` (list / grid / chips / range slider / counter).
- `SelectChildEntry` is identified by its `parentId`. Prefer the `SelectCategoryEntry(children: {...})` factory, which injects `parentId` automatically.
- Use `SelectTextEntry.name(...)` / `SelectIntEntry.name(...)` (parentless leaves) for flat single-level lists.
- An "Any" entry (`.any(...)`) clears its category; in `toQueryMap()` it resolves to the parent id.
- Serialize results with `selected.toQueryMap()` / `selected.toQueryParameters(arrayFormat: ...)` — do not hand-walk the tree.

## Reference index

Read these on demand; do not guess APIs:

| Topic | File |
| --- | --- |
| Entry points (view, bar, button, dialog, sheet), controllers, callbacks | [references/entry-points.md](references/entry-points.md) |
| Delegates, per-category `layout`, shared delegate parameters | [references/delegates.md](references/delegates.md) |
| Entry tree (`SelectEntry` types, "Any", `immediate`, headers/footers) | [references/entries.md](references/entries.md) |
| Async loading, initial selection, skeletons, search, serialization | [references/async-search.md](references/async-search.md) |
| Theming (`SelectThemeData`, theme extensions) and i18n | [references/theming-i18n.md](references/theming-i18n.md) |

Package: <https://pub.dev/packages/fl_select> · Playground: <https://flselect.zeaon.dev/>
