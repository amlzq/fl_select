# Entries — the data tree

Selections and data are a tree of `SelectEntry` nodes:

- `SelectCategoryEntry` — root node; a category. Holds `children` and the `selectionMode` for them.
- `SelectChildEntry` — any non-root node; it lives in its parent's `children` set, so nesting alone wires the tree.
- `SelectEntries` — the selection/result type: `Set<SelectEntry>` (the deepest selected nodes, not the whole tree).

## Entry types

| Entry | Purpose |
| --- | --- |
| `SelectTextEntry` | Plain text leaf, flat or nested (pass `children`). `.any(...)` builds the "Any" (clear) entry. |
| `SelectRangeEntry<N, E>` | Range leaf (`min` / `max`). `.any(...)` for "Any"; `.custom(...)` for a user-input range. `SelectIntEntry<E>` = `SelectRangeEntry<int, E>`. |

Common fields on every entry: `id`, `name`, `extra` (free-form payload, any type — attach your domain object here), `enabled` (defaults `true`; `false` renders the entry disabled), and `children` (nesting — see below).

## Building a tree

```dart
Future<SelectEntries> fetch() async => {
      // Single-selection category — children are wired by nesting alone.
      SelectCategoryEntry(
        id: 'price',
        name: 'Price',
        children: {
          SelectIntEntry.any(name: 'Any'),
          SelectIntEntry(id: '0-100', name: '0-100', min: 0, max: 100),
          SelectIntEntry.custom(name: 'Custom'),
        },
      ),
      // Multi-selection category
      SelectCategoryEntry(
        id: 'more',
        name: 'More',
        selectionMode: SelectionMode.multiple,
        children: {
          SelectTextEntry.any(name: 'Any'),
          SelectTextEntry(id: 'near_subway', name: 'Near subway'),
        },
      ),
      // Top-level leaves — flat single-level list (e.g. for ListSelectDelegate sort)
      SelectTextEntry(id: 'default', name: 'Default'),
      SelectTextEntry(id: 'newest', name: 'Newest'),
    };
```

Nest entries with `children` and let binding derive the links — a child can never be wired to the wrong parent, because you never name a parent at all.

Cascading menus: `children` lives on the `SelectEntry` base class, so any entry — not just categories — can nest its own `children` set, and `CascadingSelectDelegate` walks these nested levels:

```dart
SelectCategoryEntry(
  id: 'region',
  name: 'Region',
  children: {
    SelectTextEntry(
      id: 'jp',
      name: 'Japan',
      children: {
        SelectTextEntry(id: 'tokyo', name: 'Tokyo'),
        SelectTextEntry(id: 'osaka', name: 'Osaka'),
      },
    ),
  },
);
```

## Selection mode

- `SelectCategoryEntry.selectionMode` — per category; nullable.
- `delegate.selectionMode` — fallback for categories that leave it null.
- Default (null): inherit the delegate-level mode; an explicit value overrides it for the category's subtree.
- Headers/footers: null inherits the category's effective mode (its `selectionMode`, or the delegate-level mode).
- Resolve the effective (non-null) mode with `category.effectiveSelectionMode(delegate.selectionMode)` (also `effectiveHeaderSelectionMode` / `effectiveFooterSelectionMode`).
- Panel-wide: `controller.hasMultipleMode` — true when the delegate-level mode is multiple or any top-level category opts into multiple; drives the action bar visibility and apply-immediately behavior.

## Special behaviors

- **"Any" entry** (`.any(...)`): selecting it clears the category. In `toQueryMap()` an "Any" leaf resolves to its parent id (e.g. `price: [price]`). An "Any"-only selection is not a "real" selection: it shows no category badge, does not steal TabNavSelect's initial tab focus, and the trigger label falls back to its original text. On flat delegates in multiple mode, unselecting the last item falls back to the "Any" entry as the placeholder.
- **`immediate: true`** (multi-selection): the entry applies on tap, skipping the action bar — e.g. "Apply all"/date-shortcut entries.
- **Custom range** (`SelectIntEntry.custom(...)`): renders as min/max text input; serializes as `min-max`. It needs a view with room for an input field, so the single-row chip bar — including a category's header/footer rows — does not support it and throws if it gets one; use the wrap, list or grid layout for it.
- **`extra`**: attach any payload (enum, id, whole model) for use in callbacks.

## Category headers and footers

A `SelectCategoryEntry` can pin extra rows to the top/bottom of its children:

```dart
SelectCategoryEntry(
  id: 'more',
  name: 'More',
  header: SelectTextEntry(id: 'select_all', name: 'Select all'),
  headerSelectionMode: SelectionMode.multiple, // how the header itself selects
  footer: SelectTextEntry(id: 'clear', name: 'Clear', immediate: true),
  footerSelectionMode: SelectionMode.multiple,
  children: { ... },
);
```

`header`/`footer` are `SelectChildEntry`s rendered alongside (but separately from) `children`; `headerSelectionMode`/`footerSelectionMode` control their selection behavior (default: inherit the category's effective mode). Both are laid out as a single row of chips, so their `children` must not contain a custom range entry — it has no chip representation and makes the chip bar throw a `FlutterError`.
