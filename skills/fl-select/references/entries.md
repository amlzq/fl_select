# Entries — the data tree

Selections and data are a tree of `SelectEntry` nodes:

- `SelectCategoryEntry` — root node; a category. Holds `children` and the `selectionMode` for them.
- `SelectChildEntry` — any non-root node, identified by its `parentId`.
- `SelectEntries` — the selection/result type: `Set<SelectEntry>` (the deepest selected nodes, not the whole tree).

## Entry types

| Entry | Purpose |
| --- | --- |
| `SelectTextEntry` | Plain text leaf. `.any(...)` builds the "Any" (clear) entry; `.name(...)` builds a parentless leaf for flat lists. |
| `SelectRangeEntry<N extends num, E>` | Numeric range leaf (`min`/`max`). `.any(...)` for "Any"; `.custom(...)` for a user-input range. `SelectIntEntry<E>` = `SelectRangeEntry<int, E>`. |

Common fields on every entry: `id`, `name`, `parentId`, `extra` (free-form payload, any type — attach your domain object here), `enabled` (defaults `true`; `false` renders the entry disabled), and `children` (nesting — see below).

## Building a tree

```dart
Future<SelectEntries> fetch() async => {
      // Single-selection category. The factory injects parentId into children.
      SelectCategoryEntry(
        id: 'price',
        name: 'Price',
        children: {
          SelectIntEntry.any(parentId: 'price', name: 'Any'),
          SelectIntEntry(parentId: 'price', id: '0-100', name: '0-100', min: 0, max: 100),
          SelectIntEntry.custom(parentId: 'price', name: 'Custom'),
        },
      ),
      // Multi-selection category
      SelectCategoryEntry(
        id: 'more',
        name: 'More',
        selectionMode: SelectionMode.multiple,
        children: {
          SelectTextEntry.any(parentId: 'more', name: 'Any'),
          SelectTextEntry(parentId: 'more', id: 'near_subway', name: 'Near subway'),
        },
      ),
      // Parentless leaves — flat single-level list (e.g. for ListSelectDelegate sort)
      SelectTextEntry.name(id: 'default', name: 'Default'),
      SelectTextEntry.name(id: 'newest', name: 'Newest'),
    };
```

Prefer the `SelectCategoryEntry(children: {...})` factory — it injects `parentId` automatically, so children can't be wired to the wrong parent.

Cascading menus: `children` lives on the `SelectEntry` base class, so any entry — not just categories — can nest its own `children` set, and `CascadingSelectDelegate` walks these nested levels:

```dart
SelectCategoryEntry(
  id: 'region',
  name: 'Region',
  children: {
    SelectTextEntry(
      parentId: 'region',
      id: 'jp',
      name: 'Japan',
      children: {
        SelectTextEntry(parentId: 'jp', id: 'tokyo', name: 'Tokyo'),
        SelectTextEntry(parentId: 'jp', id: 'osaka', name: 'Osaka'),
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

- **"Any" entry** (`.any(...)`): selecting it clears the category. In `toQueryMap()` an "Any" leaf resolves to its parent id (e.g. `price: [price]`).
- **`immediate: true`** (multi-selection): the entry applies on tap, skipping the action bar — e.g. "Apply all"/date-shortcut entries.
- **Custom range** (`SelectIntEntry.custom(...)`): renders as min/max text input; serializes as `min-max`.
- **`extra`**: attach any payload (enum, id, whole model) for use in callbacks.

## Category headers and footers

A `SelectCategoryEntry` can pin extra rows to the top/bottom of its children:

```dart
SelectCategoryEntry(
  id: 'more',
  name: 'More',
  header: SelectTextEntry(parentId: 'more', id: 'select_all', name: 'Select all'),
  headerSelectionMode: SelectionMode.multiple, // how the header itself selects
  footer: SelectTextEntry(parentId: 'more', id: 'clear', name: 'Clear', immediate: true),
  footerSelectionMode: SelectionMode.multiple,
  children: { ... },
);
```

`header`/`footer` are `SelectChildEntry`s rendered alongside (but separately from) `children`; `headerSelectionMode`/`footerSelectionMode` control their selection behavior (default: inherit the category's effective mode).
