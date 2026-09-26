# Migration Guide

## MIGRATE TO Next

### `parentId` is derived from the tree structure

`SelectChildEntry.parentId` no longer has to be written by hand. Every
`parentId` parameter is now optional, and a child left with an empty
`parentId` is filled in with the id of its direct parent when the entries are
bound — or validated, since `SelectController.validateEntries` derives before
checking.

You can drop the parameter and let the plain constructors build a
two-level-or-deeper tree:

```diff
  SelectCategoryEntry(
    id: 'c1',
    name: 'Category 1',
    children: {
-     SelectTextEntry(parentId: 'c1', id: 'a', name: 'A'),
-     SelectTextEntry(parentId: 'c1', id: 'b', name: 'B'),
+     SelectTextEntry(id: 'a', name: 'A'),
+     SelectTextEntry(id: 'b', name: 'B'),
    },
  );
```

Derivation recurses with each node's own id, so a nested entry gets the id of
its **direct** parent, not of the category it ultimately belongs to.

What does **not** change:

- Existing code that passes a correct `parentId` keeps working unchanged; the
  parameter is only deprecated, not removed.
- The `.children` factory constructors (deprecated, see below) still inject the
  parent link themselves. For them the tree shape is authoritative, so a
  `parentId` set on a child inside `.children` is still replaced by the factory.
- Derivation covers every path the entries take into the library: binding the
  state tree, the entries the panel hands to the body widgets (so a tap
  resolves its category through the derived link), and `SelectEntryCodec`.
- An explicitly authored `parentId` is never relocated by derivation. It is
  validated against the tree instead, so a stale link still throws instead of
  being silently corrected:

```diff
  SelectCategoryEntry(
    id: 'c1',
    name: 'Category 1',
    children: {
-     // Stale, non-empty parentId: an ArgumentError on bind.
      SelectTextEntry(parentId: 'c2', id: 'a', name: 'A'),
    },
  );
```

Note that a child built with `SelectTextEntry(id: 'a', name: 'A')` and placed
under a category used to raise an `ArgumentError` (`parentId: ''` did not match
`'c1'`). Its `parentId` is now derived, so such a tree simply works; to keep
asserting an invalid tree, set a wrong non-empty `parentId` explicitly.

Passing `parentId` explicitly is **deprecated** in favour of the derived form
and will be removed in a future minor version, at which point the tree
structure becomes the only source of the parent link.

### The entry tree is no longer parameterized by `E`

A `SelectEntry<E>`'s `E` now types its `extra` payload alone. `children`,
`copyWith(children:)` and every `children:` parameter take a plain
`Set<SelectEntry>` — the `SelectEntries` shape — instead of
`Set<SelectEntry<E>>`, and `header`, `footer` and their `copyWith` parameters
take a plain `SelectEntry` instead of `SelectEntry<E>`.

This fixes a crash, not just a signature. A `Set<SelectEntry<E>>` is covariant
in `E`, and a container is checked as a whole, so the derived child set that
`SelectUtils` rebuilds on every bind was rejected by the typed `copyWith` it was
handed to:

```dart
// Threw on bind before:
// type '_Set<SelectEntry<dynamic>>' is not a subtype of type
// 'Set<SelectEntry<int>>?'
SelectCategoryEntry<int>(
  id: 'c1',
  name: 'Category 1',
  extra: 1,
  children: {
    SelectTextEntry<int>(id: 'a', name: 'A'), // parentId is derived
  },
);
```

The same widening happened for a `header`/`footer` that derivation rewrote into
a `SelectChildEntry`: recursed with `dynamic`, the rewritten entry was rejected
by the `SelectEntry<E>` slot of a typed category.

What does **not** change:

- Passing a typed set, header or footer still compiles exactly as before:
  `children: {SelectTextEntry<int>(id: 'a', name: 'A')}` and
  `header: SelectTextEntry<int>(id: 'h', name: 'H')` are accepted, because
  `Set<SelectTextEntry<int>>` is a subtype of `Set<SelectEntry>` and
  `SelectTextEntry<int>` is a subtype of `SelectEntry`.
- A header or footer is still the entry you put in: it is rebuilt through its own
  `copyWith`, so `category.header` reads back as the `SelectTextEntry<int>` it was
  built with, `extra` included.
- `extra` stays `E?`, so `SelectCategoryEntry<int>(extra: 1)` still reads back an
  `int`.

What needs updating is code that spelled those types out, or that leaned on them:

```diff
  class MyEntry<E> extends SelectTextEntry<E> {
    @override
    MyEntry<E> copyWith({
-     Set<SelectEntry<E>>? children,
+     Set<SelectEntry>? children,
      bool? enabled,
    }) => ...;
  }

  class MyCategoryEntry<E> extends SelectCategoryEntry<E> {
    @override
    MyCategoryEntry<E> copyWith({
-     SelectEntry<E>? header,
+     SelectEntry? header,
-     SelectEntry<E>? footer,
+     SelectEntry? footer,
      ...
    }) => ...;
  }
```

Reading `children`, `header` or `footer` off a typed entry now yields
`SelectEntry<dynamic>`, so the `extra` it carries is no longer part of the
inferred type — add the cast back where a target type needs it:

```diff
  final category = SelectCategoryEntry<int>(...);
- final List<int?> extras = category.children!.map((e) => e.extra).toList();
- final int? headerExtra = category.header!.extra;
+ final List<int?> extras = category.children!
+     .map((e) => (e as SelectEntry<int>).extra)
+     .toList();
+ final int? headerExtra = (category.header! as SelectEntry<int>).extra;
```

Unparameterized entries — `SelectEntry<dynamic>`, the shape of the library's own
`SelectEntries` and of every entry built without an explicit type argument — see
no difference at all.

### Named constructors converge on the plain constructors

The named constructors that only existed to spare the (now derived) parent link
are **deprecated** and will be removed in a future minor version. They keep
working unchanged — nothing has to be updated to compile — but new code should
use the plain constructors:

| Deprecated                            | Use instead                                                       |
| ------------------------------------- | ----------------------------------------------------------------- |
| `SelectTextEntry.id(id: 'a')`         | `SelectTextEntry(id: 'a', name: '')`                              |
| `SelectTextEntry.name(id: 'a', name: 'A')` | `SelectTextEntry(id: 'a', name: 'A')`                        |
| `SelectTextEntry.children(...)`       | `SelectTextEntry(...)` with `children:`                           |
| `SelectChildEntry.empty()`            | `SelectChildEntry(id: '')`                                        |
| `SelectChildEntry.children(...)`      | `SelectChildEntry(...)` with `children:`                          |
| `SelectCategoryEntry.children(...)`   | `SelectCategoryEntry(...)` with `children:` / `header:` / `footer:` |

```diff
  SelectCategoryEntry(
    id: 'c1',
    name: 'Category 1',
    children: {
-     SelectTextEntry.name(id: 'a', name: 'A'),
-     SelectTextEntry.children(
+     SelectTextEntry(id: 'a', name: 'A'),
+     SelectTextEntry(
        id: 'b',
        name: 'B',
        children: {
-         SelectTextEntry.name(id: 'b1', name: 'B1'),
+         SelectTextEntry(id: 'b1', name: 'B1'),
        },
      ),
    },
  );
```

What does **not** change:

- The deprecated constructors keep their exact behaviour. In particular the
  `.children` factories still inject the parent link eagerly, and they still
  overwrite a `parentId` set on a child, because the tree shape is authoritative
  for them — the plain constructors never touch it.
- The special-purpose constructors stay: `.any(...)` on the entry types,
  `SelectRangeEntry.custom(...)` and `SelectChildEntry.any(...)`. They express
  the `kAnyEntryId` / `kCustomEntryId` domain semantics rather than boilerplate.
- `SelectEntryCodec.fromJson` keeps returning fully wired entries: decoding
  derives the parent links itself, so a decoded tree reaches a delegate exactly
  like a hand-built one.

### Sibling ids must be unique

Entries that share a parent — top-level entries, the children of one node, and
the children of a header/footer — must carry distinct ids. A duplicate was
always a bug, but it used to fail silently in one of two ways, so
`SelectController.validateEntries` (and therefore binding) now reports it as an
`ArgumentError`:

- Siblings that compare equal — same runtime type, id and `parentId`, since
  `name` is deliberately not part of identity — collapse into one wherever they
  are held in a `Set`: the second entry was dropped without a word.
- Siblings that do **not** compare equal but still share an id — a
  `SelectTextEntry` next to a `SelectRangeEntry`, or two categories whose
  `selectionMode`/`layout` differ — both stayed, and then the lookup that
  resolves an entry from its id alone (`singleWhereOrNull((e) => e.id == ...)`,
  `StateTree.findEntry`) could no longer tell them apart: a tap on them was
  ignored.

Give one of the two a distinct id:

```diff
  SelectCategoryEntry(
    id: 'c1',
    name: 'Category 1',
    children: {
      SelectTextEntry(id: 'a', name: 'A'),
-     SelectTextEntry(id: 'a', name: 'A'),  // Duplicate id "a" under parent "c1"
+     SelectTextEntry(id: 'b', name: 'B'),
    },
  );
```

Only siblings are compared, so the same id may still be reused under
**different** parents; the built-in "Any" and "custom" entries rely on that. The
check runs on the entries as you authored them, before the parent links are
derived, so two siblings that would only become equal once an empty `parentId`
is filled in are reported as well.

Relatedly, `SelectCategoryEntry` no longer includes `name` in its identity
(`==`/`hashCode`). Like the name of a `SelectChildEntry` it is mutable
presentation state, so relabelling a category no longer makes it unfindable in
the sets it is stored in, and two categories that differ only in name count as
the same entry instead of sitting side by side with the same id.

### `SelectCategoryEntry` exposes its `extra` payload

A category could not carry a payload of its own: the plain constructor and the
deprecated `.children` factory had no `extra` parameter, so only the entries
below a category could carry one, and `copyWith` dropped it. Both constructors
now pass it through to the inherited `SelectEntry.extra`, and `copyWith` keeps
it:

```dart
SelectCategoryEntry<int>(
  id: 'c1',
  name: 'Category 1',
  extra: 1,
  children: {SelectTextEntry<int>(id: 'a', name: 'A')},
);
```

The payload survives a rebuild — including the one the parent-link derivation
performs — and the clones the changed/applied entry sets are built from (see
"Cloning and JSON round trips stop dropping entry data").

Like `name`, `extra` stays out of the category's identity (`(id,
selectionMode, layout)` is the whole of `==`/`hashCode`), and
`SelectEntryCodec` still does not serialize it.

### `findExtrasAtLevel` returns nullable payloads

`SelectEntriesExtension.findExtrasAtLevel` — and the
`SelectUtils.findExtrasAtLevel` behind it — now returns `List<String?>` /
`List<E?>` instead of `List<String>` / `List<E>`. An entry without an `extra`
payload is an ordinary node of the tree, but the old signature assumed every
node on the target level carried one, so asking for the payloads of a level that
holds a payload-less entry threw:

```dart
// Threw before: type 'Null' is not a subtype of type 'String'
SelectUtils.findExtrasAtLevel<String>(entry, 2);
```

A node that carries nothing now contributes `null`, which keeps the traversal
total and the position of every payload intact:

```diff
- final List<String> extras = entries.findExtrasAtLevel(entry, 2);
+ final List<String?> extras = entries.findExtrasAtLevel(entry, 2);
+ // Drop the payload-less nodes when the holes are not welcome:
+ final List<String> payloads = extras.whereType<String>().toList();
```

What does **not** change:

- Payloads keep their traversal order, holes included, so a payload keeps the
  index it had when every node on the level carried one.
- A non-`null` payload that is not assignable to `E` still throws; only `null`
  is tolerated now.
- A call site that already asked for a nullable or `dynamic` element type reads
  back exactly the same list.

### Cloning and JSON round trips stop dropping entry data

Two paths that rebuild entries no longer discard data:

- The cloning helpers behind the changed/applied entry sets — `SelectUtils`
  `deepCloneEntries` and `cloneTree`, which
  `StateTree.buildChangedEntries` / `buildAppliedEntries` call, along with the
  header/footer and without-children variants they delegate to — carried `extra`
  over for range and child entries but dropped it for text and category entries,
  whose clones came back with `extra: null`. Every built-in node now keeps its
  payload through a clone.
- `SelectEntryCodec` round-trips the `headerSelectionMode` and
  `footerSelectionMode` of a `SelectCategoryEntry`, which were neither emitted
  nor read back before. An explicit mode is emitted
  (`"headerSelectionMode": "multiple"`); a `null` one stays absent from the JSON,
  because `null` means *inherit the category's effective mode*, and flattening it
  into an explicit `SelectionMode.single` would change what the decoded tree
  selects.

What does **not** change:

- `SelectEntryCodec` still does not serialize `extra` or `parentId`, by design
  (see the "Limitations" section of the codec's own documentation).
- The two new keys are additive: a document written by an earlier version
  decodes unchanged, and a consumer that ignores the keys keeps working.
- Nothing moved in the signature of the cloning helpers or of the codec, so
  existing calls compile as they are.

### The ambient `SelectTheme` now styles a select

The panel resolves its base theme from the ambient `SelectTheme`, falling back
to a `SelectThemeData.fallback` derived from the Material `ThemeData` when none
is in scope, instead of receiving a resolved theme as an argument.
Delegate-level theme fields keep being merged field-wise on top of it.

What this changes:

- A `SelectTheme` wrapped around a select now styles it instead of being
  ignored.
- The popup triggers (`PopupSelectBar`, `PopupSelectButton`) inject the
  `selectTheme` they resolved around the overlay panel, because the overlay sits
  outside the trigger's subtree and cannot inherit the theme from there. A
  trigger-level `selectTheme` keeps reaching the panel.

No call site changes: the removed argument belonged to the internal
`SelectPanel` widget rather than to a public entry point.

## MIGRATE TO 0.14.0

### `SelectThemeData.chipBarThemeData` renamed to `chipBarTheme`

`SelectThemeData` now calls the chip-bar theme `chipBarTheme`, matching
`SelectDelegate.chipBarTheme` and its sibling `SelectThemeData.wrapViewTheme`.
Reading the old name keeps working through a deprecated getter, but the
`SelectThemeData(...)` factory and `SelectThemeData.raw(...)` only accept the
new name:

```diff
- SelectThemeData(ThemeData.light(), chipBarThemeData: const SelectChipBarTheme());
+ SelectThemeData(ThemeData.light(), chipBarTheme: const SelectChipBarTheme());
```

### `chipBarTheme` no longer styles the wrapping chip view

The wrap form resolves `wrapViewTheme` alone, so style its chips with
`SelectWrapViewTheme`:

```diff
- SelectThemeData(ThemeData.light(), chipBarTheme: const SelectChipBarTheme(chipColor: _tint));
+ SelectThemeData(ThemeData.light(), wrapViewTheme: const SelectWrapViewTheme(chipColor: _tint));
```

`chipBarTheme` is still folded into the wrap view theme as a lowest-priority
fallback, so existing wrap-chip styling keeps rendering unchanged. That bridge
is deprecated together with the shared-chip-theme model and will be dropped in
a future minor version; a field set on both is resolved from `wrapViewTheme`.

## MIGRATE TO 0.13.0

### `itemBuilder` on the category delegates

`TabNavSelectDelegate`, `SideNavSelectDelegate` and `ExpandableSelectDelegate`
now forward their `itemBuilder` to their categories laid out as a list, grid
or wrap, matching the flat-data delegates:

- The builder may return null to fall back to the default item widget, so you
  can customize only some entries or categories while keeping the built-in
  visuals elsewhere.
- Range-slider (`SelectRangeLayout`) and counter (`SelectCounterLayout`)
  category layouts keep their built-in controls.
- The builder does not cover a category's header/footer chips.
- `CascadingSelectDelegate` ignores the builder.

### `SelectItemBuilder` gains `categoryId` and returns `Widget?`

`SelectItemBuilder` now takes an optional named `String? categoryId` — the id
of the `SelectCategoryEntry` owning the entry on the category delegates, null
on the flat delegates, so one builder can serve both — and returns `Widget?`
instead of `Widget` (closures returning a non-null `Widget` keep compiling).

Existing builder closures must declare the new parameter; declare it bare
(no type annotation) when it is unused:

```diff
- itemBuilder: (context, entry, {required selected, required onTap}) =>
+ itemBuilder: (context, entry, {required selected, required onTap, categoryId}) =>
      MyTile(entry: entry, selected: selected, onTap: onTap),
```

### Select panel widgets internalized

`fl_select.dart` no longer re-exports the internal widgets barrel. The
built-in widgets are rendering targets of `SelectPanel`, driven by a
`SelectDelegate` plus `SelectLayout`s, and were not meant to be constructed
directly. Only the public surface they are configured through remains
exported:

- the widget themes (`SelectActionBarTheme`, `SelectTabBarTheme`,
  `SelectSideBarTheme`, `SelectGridTileTheme`, `SelectListTileTheme`,
  `SelectFieldTileTheme`, `SelectExpansionTileTheme`,
  `SelectRangeSliderTheme`, `SelectChipBarTheme`, `SelectSearchBarTheme`,
  `SelectPanelTheme`) and their enums (`SelectChipVariant`,
  `SelectGridTileVariant`, `SelectFieldTileVariant`,
  `SelectTabBarIndicatorSize`);
- `ToggleWidgetBuilder`, referenced by the themes and delegates;
- `SelectActionBar`, reusable inside a custom `actionBarBuilder`.

Every other symbol that used to leak through the barrel — the views
(`SelectListView`, `SelectGridView`, `SelectWrapView`, `SelectRangeView`,
`SelectSideBar`, `SelectTabBar`, `SelectChipBar`, `SelectSearchBar`,
`SelectCounter`), the tiles (`SelectListTile`, `SelectCheckboxListTile`,
`SelectRadioListTile`, `SelectGridTile`, `SelectFieldTile`,
`SelectExpansionTile`, `SelectRangeSlider`), the skeletons
(`Select*Skeleton`, `SkeletonView`, `SkeletonTile`), `SelectBadge`,
the panel host (`SelectPanel`), the chip host symbols (`SelectChip`,
`SelectChipBarStyle`, `resolveSelectChipBarStyle`),
`ChainingClampingScrollPhysics`, the
`OnChanged` typedef and the `kSelect*` constants — kept compiling through
a deprecated alias and **is removed in the Next release**.

Migration: build the UI through the public entry points (`SelectView`,
`showModalBottomSelect`, `showSelect`, `PopupSelectBar`,
`PopupSelectButton`), pick layouts via `SelectLayout`s on the delegate or
its categories, and style the built-in widgets through the themes listed
above.

### `SelectListViewState` / `SelectGridViewState` are private

The state classes were internal implementation details leaked by the
widgets barrel. Code referencing them directly must be updated:

```diff
-final key = GlobalKey<SelectListViewState>();
+final key = GlobalKey<State<dynamic>>();
```

## MIGRATE TO 0.12.0

### `SelectController.badgedCategories` renamed to `realSelectedCategories`

The getter is renamed to lead with its semantics — the categories holding a
"real" selection (at least one selected child that is not the "Any"
placeholder) — instead of the badge UI it happens to power. The old name is
kept as a deprecated forwarding getter and will be removed in a future minor
version.

```diff
-final categories = controller.badgedCategories;
+final categories = controller.realSelectedCategories;
```

### `SelectChipBar` split into `SelectChipBar` / `SelectWrapView`

The dual-form `SelectChipBar` is split into two single-purpose widgets: the
horizontal single-row bar keeps the `SelectChipBar` name, and the wrap form
(multi-row, height-adaptive) moves to the new `SelectWrapView`, which is now
the dedicated rendering target of `SelectWrapLayout`. The split applies to
the skeleton too: the wrap form of `SelectChipBarSkeleton` maps to the new
`SelectWrapViewSkeleton`.

Accordingly, the single-row bar keeps only its title-left layout:
`SelectChipBar.isWrapable` / `runSpacing` / `direction` — and the matching
`SelectChipBarSkeleton` parameters — are deprecated and keep working by
delegating to the new widgets; they **will be removed in a future minor
version**. The wrap form and the vertical (title-above) layout are both
served by `SelectWrapView` / `SelectWrapViewSkeleton`. Migration is a pure
rename.

```diff
- SelectChipBar(
+ SelectWrapView(
    entries: entries,
    selectedEntries: selectedEntries,
-   isWrapable: true,
    spacing: 8,
    runSpacing: 8,
  );

- SelectChipBarSkeleton(
+ SelectWrapViewSkeleton(
    itemCount: 8,
-   isWrapable: true,
  );

- SelectChipBar(
+ SelectWrapView(
    category: category,
    entries: entries,
-   direction: Axis.vertical, // title above the chips
    spacing: 8,
  );
```

Notes:

- Call sites passing `isWrapable: false` (or omitting it) and a horizontal
  `direction` (or omitting it) are unaffected — `SelectChipBar` keeps
  rendering the single-row bar.
- The split also exports `SelectChip` and
  `SelectChipBarStyle` / `resolveSelectChipBarStyle`, so custom
  `itemBuilder`s can reuse the built-in chip and its three-level style
  resolution.
- `SelectWrapView` (and the deprecated wrap delegation) always stacks the
  category title above the chips; the title-left layout remains exclusive to
  the single-row `SelectChipBar`.
- The built-in delegates (`WrapSelectDelegate`, the `TabNavSelectDelegate` /
  `ExpandableSelectDelegate` header/footer bars, and categories laid out by
  `SelectWrapLayout`) now render `SelectWrapView` internally, so widget tests
  asserting `find.byType(SelectChipBar)` on those trees should assert
  `SelectWrapView` instead.

## MIGRATE TO 0.11.0

The dual-mode delegates are split into single-purpose ones and the old
dual-mode entry points are deprecated: they keep working through forwarding
and will be removed in a future minor version. Likewise,
`SelectChipLayout` is renamed to `SelectWrapLayout`, with the old name kept
as a deprecated alias.

### Which mode am I using?

Check your `entries`: if the top level contains `SelectCategoryEntry` items
(two-level data), you are on a two-level mode; if it contains plain entries
such as `SelectTextEntry` (flat data), you are on a flat mode.

> Note: `CascadingSelectDelegate` is unrelated to this two-level/flat split — it
> navigates a multi-level cascade of unlimited depth.

### FlattenSelectDelegate (renamed)

```diff
- FlattenSelectDelegate(
+ SideNavSelectDelegate(
    entries: categoryEntries, // two-level data
  )

- FlattenSelectDelegate(
+ WrapSelectDelegate(
    entries: flatEntries, // flat data
  )
```

### GridSelectDelegate with two-level data

```diff
- GridSelectDelegate(
-   crossAxisCount: 4,
-   entries: categoryEntries, // two-level data
- )
+ TabNavSelectDelegate(
+   defaultLayout: const SelectGridLayout(crossAxisCount: 4),
+   entries: categoryEntries,
+ )
```

`GridSelectDelegate` with flat data is unaffected.

### ListSelectDelegate with two-level data

```diff
- ListSelectDelegate(
+ ExpandableSelectDelegate(
    entries: categoryEntries, // two-level data
  )
```

`ListSelectDelegate` with flat data is unaffected.

### `SelectChipLayout` renamed to `SelectWrapLayout`

`SelectChipLayout` is renamed to `SelectWrapLayout` to align the layout with
the wrapable chip bar it renders. The old name is kept as a deprecated
subclass of `SelectWrapLayout` for backward compatibility and will be
removed in a future minor version. The two are fully interchangeable —
equal values compare equal, render identically and encode to the same JSON
`kind: 'chip'` — so migration is a pure rename.

```diff
- layout: const SelectChipLayout(spacing: 8, runSpacing: 8),
+ layout: const SelectWrapLayout(spacing: 8, runSpacing: 8),
```

### Notes

- Each new delegate asserts on the data shape it does not support, so a
  mis-migration fails fast with a message pointing to the right delegate.
- Running the deprecated two-level paths prints a one-time warning naming
  the replacement.

## MIGRATE TO 0.10.0

### `FlattenSelectDelegate` grid parameters removed

The `FlattenSelectDelegate` grid parameters (`crossAxisCount`,
`mainAxisSpacing`, `crossAxisSpacing`, `childAspectRatio`) and the matching
`FlattenSelect` widget parameters — deprecated since 0.7.2 — are removed.
`FlattenSelect` falls back to `SelectChipLayout` when
`SelectCategoryEntry.layout` is null, so these parameters no longer affect
rendering; grid geometry now comes exclusively from the `SelectGridLayout`
set on each `SelectCategoryEntry.layout`.

`FlattenSelectSkeleton.crossAxisCount` becomes optional and defaults to `2`,
so the built-in skeleton keeps its previous look. Customize it via
`SelectDelegate.skeletonBuilder` if you need a different preview.

Migration: drop the removed parameters and set a `SelectGridLayout` on the
categories that should render as a grid.

```dart
// Before
FlattenSelectDelegate(
  crossAxisCount: 3,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 1.2,
);

// After
FlattenSelectDelegate();

final category = SelectCategoryEntry(
  id: 'brand',
  name: 'Brand',
  children: brands,
  layout: SelectGridLayout(
    crossAxisCount: 3,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.2,
  ),
);
```

### `SelectController` deprecated `previousSelected` / `resetSelected` aliases removed

The deprecated `SelectController` constructor parameters and getters
(`previousSelected`, `resetSelected`) — deprecated since 0.8.0 in favor of
`selectedEntries` / `resetEntries` — are removed.

Migration: pass `selectedEntries` / `resetEntries` instead.

```dart
// Before
SelectController(
  selectionMode: SelectionMode.single,
  previousSelected: { ... },
  resetSelected: { ... },
);

// After
SelectController(
  selectionMode: SelectionMode.single,
  selectedEntries: { ... },
  resetEntries: { ... },
);
```

## MIGRATE TO 0.9.0

### `PopupSelectButton` default variant changed to `text`

`PopupSelectButtonVariant` gains a `text` variant — a trigger with a
transparent background and no border, styled like `TextButton` — and the
`PopupSelectButton` default constructor now uses it as the default
`variant`, aligning the unnamed constructor with the least-emphasis
Material button. A new `PopupSelectButton.filled` named constructor
(mirroring the existing `.elevated` / `.outlined` constructors) preserves
the previous default look.

The public API is backward compatible: all existing enum values,
constructors and parameters keep working, and call sites that pass
`variant` explicitly render exactly as before. Only call sites that relied
on the old default without an explicit `variant` are affected — they now
render a text button.

Migration: pass an explicit `variant` — or use the matching named
constructor — at every call site that relies on the old filled default.

```dart
// Before
PopupSelectButton(
  label: 'Price',
  selectDelegate: priceDelegate,
  onApplied: (selected) { ... },
);

// After — keep the previous filled look
PopupSelectButton.filled(
  label: 'Price',
  selectDelegate: priceDelegate,
  onApplied: (selected) { ... },
);

// or
PopupSelectButton(
  variant: PopupSelectButtonVariant.filled,
  label: 'Price',
  selectDelegate: priceDelegate,
  onApplied: (selected) { ... },
);
```

### Category selection modes are nullable and inherit the delegate level

`SelectCategoryEntry.selectionMode`, `headerSelectionMode` and
`footerSelectionMode` are now nullable and default to null (inherit):

- a null `selectionMode` inherits the delegate-level
  `delegate.selectionMode` (which still defaults to `SelectionMode.single`);
- a null `headerSelectionMode` / `footerSelectionMode` inherits the
  category's effective selection mode (`selectionMode`, falling back to the
  delegate-level mode).

The public API is backward compatible: all existing constructors and
parameters keep working, explicitly passed modes keep their exact behavior,
and categories that omit the modes behave identically whenever the
delegate-level mode is single (its default). Only call sites that combine a
multi-mode delegate with categories that omit `selectionMode` change
behavior — those categories now inherit multiple instead of silently
defaulting to single, which also fixes tapping an already-selected leaf not
deselecting under a multi-mode delegate.

Migration: pass an explicit mode at every call site that must keep the old
implicit single default under a multi-mode delegate, and switch code that
reads the fields directly to the new `effectiveSelectionMode` /
`effectiveHeaderSelectionMode` / `effectiveFooterSelectionMode` extensions.

```dart
// Before — the implicit default was SelectionMode.single, so a category
// under a multiple delegate silently behaved as single.
final mode = category.selectionMode; // non-null, implicitly single

// After — unset modes are null (inherit); resolve the effective value.
final SelectionMode? configured = category.selectionMode;
final mode = category.effectiveSelectionMode(SelectionMode.multiple);

// Keep the old implicit single default under a multi-mode delegate.
SelectCategoryEntry(
  id: 'brand',
  name: 'Brand',
  selectionMode: SelectionMode.single,
  children: { ... },
);
```

## MIGRATE TO 0.8.0

### `previousSelected` / `resetSelected` renamed to `selectedEntries` / `resetEntries`

The `previousSelected` / `resetSelected` API surface has been renamed to
`selectedEntries` / `resetEntries` to align naming across the library. The
rename covers `SelectController`, `StateTree`, `SelectDelegate.buildBody` and
the four `Select*` widgets:

| Old name                                                | New name                                                 |
| ------------------------------------------------------- | -------------------------------------------------------- |
| `SelectController.previousSelected`                      | `SelectController.selectedEntries`                       |
| `SelectController.resetSelected`                         | `SelectController.resetEntries`                          |
| `SelectController.bindState(previousSelectedOverride:)`  | `SelectController.bindState(selectedEntriesOverride:)`   |
| `SelectController.bindState(resetSelectedOverride:)`     | `SelectController.bindState(resetEntriesOverride:)`      |
| `StateTree.previousSelected`                             | `StateTree.selectedEntries`                              |
| `StateTree.resetSelected`                                | `StateTree.resetEntries`                                 |
| `StateTree.bind(previousSelected:)`                      | `StateTree.bind(selectedEntries:)`                       |
| `StateTree.bind(resetSelected:)`                         | `StateTree.bind(resetEntries:)`                          |
| `SelectDelegate.buildBody(previousSelected)`             | `SelectDelegate.buildBody(selectedEntries)`              |
| `CascadingSelect.previousSelected`                       | `CascadingSelect.selectedEntries`                        |
| `ListSelect.previousSelected`                            | `ListSelect.selectedEntries`                             |
| `GridSelect.previousSelected`                            | `GridSelect.selectedEntries`                             |
| `FlattenSelect.previousSelected`                         | `FlattenSelect.selectedEntries`                          |

The old names were kept as deprecated aliases on the public-facing
`SelectController` constructor parameters and getters for backward
compatibility; they have since been **removed**. All other renamed members (on
`StateTree`, `bindState`, `SelectDelegate.buildBody`, and the four `Select*`
widgets) are internal and were renamed without aliases — update call sites
directly. No behavior changes.

> Note: `SelectDelegate.buildBody` is a positional parameter, so the rename is
> purely cosmetic for callers and overrides — existing override signatures keep
> working regardless of the parameter name they use.

Migration: replace each old name with its new counterpart at every call site.

```dart
// Before
SelectController(
  selectionMode: SelectionMode.single,
  previousSelected: { ... },
  resetSelected: { ... },
);

controller.bindState(
  entries,
  initializeAnyIfEmpty: false,
  previousSelectedOverride: { ... },
);

// After
SelectController(
  selectionMode: SelectionMode.single,
  selectedEntries: { ... },
  resetEntries: { ... },
);

controller.bindState(
  entries,
  initializeAnyIfEmpty: false,
  selectedEntriesOverride: { ... },
);
```

### Search filtering parameters on `SelectDelegate`

Every `SelectDelegate` accepts `searchEnabled`, `searchPredicate`,
`searchHintText` and `searchDebounceDuration`; when enabled, a
`SelectSearchBar` renders above the body and filters displayed entries
(debounced 300 ms by default) while preserving layout and selection state.
The search bar's look is customizable via `SelectSearchBarTheme`, per
delegate or globally via `SelectThemeData`.

```dart
ListSelectDelegate(
  searchEnabled: true,
  searchHintText: 'Search',
  searchPredicate: (entry, query) => entry.name.contains(query),
  searchDebounceDuration: const Duration(milliseconds: 300),
);
```

### `toQueryMap()` / `toQueryParameters()` on `SelectEntries`

Each category contributes key/value pairs keyed by its own id with the
deepest selected leaf ids as values; header/footer subtrees are keyed by
their own ids; an "any" leaf resolves to its parent id; and a custom
`SelectRangeEntry` formats as `min-max`.

- `toQueryMap()` returns a `Map<String, List<String>>` mirroring
  `Uri.queryParametersAll`, so repeated keys can be read back without losing
  values, or handed to HTTP clients that accept multi-value maps directly.
- `toQueryParameters({arrayFormat, delimiter, encode})` renders the map into
  a query string, with multi-value layouts selected by the `SelectArrayFormat`
  enum: `repeat` (default, `cate1=a&cate1=b`), `brackets` (`cate1[]=a`),
  `comma` (`cate1=a,b`), `indices` (`cate1[0]=a`), and `delimited`
  (`cate1=a|b` with a custom `delimiter`, covering OpenAPI
  `pipeDelimited`/`spaceDelimited`). Values are percent-encoded by default.

### Cascading selection state handling in `CascadingSelect`

Focusing a category no longer clears other categories' selections;
per-category single mode only clears selections within its own subtree;
header/footer selections are cleared across categories; deeper search matches
are auto-expanded; canceling a search restores the original unfiltered tree
entries.

### Cross-category clearing in two-level category trees

In `GridSelect`, `ListSelect` and `FlattenSelect`, selecting a leaf in one
category now clears every other category's selections when the delegate is in
single mode, mirroring the cascading behavior.

## MIGRATE TO 0.7.2

### `FlattenSelectDelegate` grid parameters deprecated

The `FlattenSelectDelegate` grid parameters — `crossAxisCount`,
`mainAxisSpacing`, `crossAxisSpacing`, `childAspectRatio` — and the matching
`FlattenSelect` widget parameters are deprecated. `FlattenSelect` now falls
back to a wrapable chip bar when `SelectCategoryEntry.layout` is null, so
these parameters no longer affect rendering; grid geometry comes exclusively
from the `SelectGridLayout` set on each `SelectCategoryEntry.layout`.

The old names keep working (they are simply ignored) and **will be removed in
a future minor version**. No behavior changes for call sites that already set
a layout, and call sites that relied on the old grid fall back to the chip bar
instead of the grid.

Migration: drop the deprecated parameters and set a `SelectGridLayout` on the
categories that should render as a grid.

```dart
// Before
FlattenSelectDelegate(
  crossAxisCount: 3,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 1.2,
);

// After
FlattenSelectDelegate();

SelectCategoryEntry(
  id: 'brand',
  name: 'Brand',
  children: brands,
  layout: const SelectGridLayout(
    crossAxisCount: 3,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.2,
  ),
);
```

## MIGRATE TO 0.7.0

### Selector lifecycle callbacks renamed to `onSelect*` on `PopupSelectBar` / `PopupSelectButton`

The selector lifecycle callbacks on [`PopupSelectBar`] and [`PopupSelectButton`]
have been renamed from `onSelector*` to `onSelect*` for consistency with the
surrounding `Select*` / `PopupSelect*` naming:

| Old name                               | New name                             |
| -------------------------------------- | ------------------------------------ |
| `PopupSelectBar.onSelectorShowed`      | `PopupSelectBar.onSelectShowed`      |
| `PopupSelectBar.onSelectorHidden`      | `PopupSelectBar.onSelectHidden`      |
| `PopupSelectBar.onSelectorWillShow`    | `PopupSelectBar.onSelectWillShow`    |
| `PopupSelectBar.onSelectorWillHide`    | `PopupSelectBar.onSelectWillHide`    |
| `PopupSelectButton.onSelectorShowed`   | `PopupSelectButton.onSelectShowed`   |
| `PopupSelectButton.onSelectorHidden`   | `PopupSelectButton.onSelectHidden`   |
| `PopupSelectButton.onSelectorWillShow` | `PopupSelectButton.onSelectWillShow` |
| `PopupSelectButton.onSelectorWillHide` | `PopupSelectButton.onSelectWillHide` |

The old names are kept as deprecated constructor parameters and getters that
delegate to the new names for backward compatibility and **will be removed in a
future minor version**. Passing both the old and the new callback at the same
call site triggers an `assert`. No behavior changes.

Migration: replace each old name with its new counterpart at every call site.

```dart
// Before
PopupSelectBar(
  onSelectorWillShow: (tabData) async { ... },
  onSelectorShowed: (tabData) { ... },
  onSelectorWillHide: (tabData) async { ... },
  onSelectorHidden: (tabData) { ... },
);

// After
PopupSelectBar(
  onSelectWillShow: (tabData) async { ... },
  onSelectShowed: (tabData) { ... },
  onSelectWillHide: (tabData) async { ... },
  onSelectHidden: (tabData) { ... },
);
```

```dart
// Before
PopupSelectButton(
  onSelectorWillShow: () async { ... },
  onSelectorShowed: () { ... },
  onSelectorWillHide: () async { ... },
  onSelectorHidden: () { ... },
);

// After
PopupSelectButton(
  onSelectWillShow: () async { ... },
  onSelectShowed: () { ... },
  onSelectWillHide: () async { ... },
  onSelectHidden: () { ... },
);
```

### `PopupSelectController` lifecycle members renamed to `*Select*`

The selector overlay visibility members on [`PopupSelectController`] have been
renamed to drop the redundant `Selector` wording for consistency with the
surrounding `Select*` / `PopupSelect*` naming:

| Old member                                  | New member                                |
| ------------------------------------------- | ----------------------------------------- |
| `PopupSelectController.hideSelector(...)`   | `PopupSelectController.hideSelect(...)`   |
| `PopupSelectController.toggleSelector(...)` | `PopupSelectController.toggleSelect(...)` |
| `PopupSelectController.isSelectorShowing`   | `PopupSelectController.isSelectShowing`   |

The old names are kept as deprecated methods / getters that delegate to the new
names for backward compatibility and **will be removed in a future minor
version**. No behavior changes.

Migration: replace each old name with its new counterpart at every call site.

```dart
// Before
controller.toggleSelector(index: 0);
if (controller.isSelectorShowing) {
  controller.hideSelector();
}

// After
controller.toggleSelect(index: 0);
if (controller.isSelectShowing) {
  controller.hideSelect();
}
```

### `SelectDelegate.entriesLoader` and `SelectView.onChanged` are now required

[`SelectDelegate.entriesLoader`] and [`SelectView.onChanged`] are now **required**
named parameters (previously optional / nullable).

**Description**

- `SelectDelegate.entriesLoader` is now a non-nullable `Future<SelectEntries>
Function()`. Every delegate — including custom subclasses — must supply an
  `entriesLoader`. The `data` getter now calls `entriesLoader()` directly
  instead of `entriesLoader?.call()`.
- `SelectView.onChanged` is now a non-nullable `SelectCallback`. Every
  `SelectView` must supply an `onChanged` callback.

This is a **breaking change**: call sites that previously omitted either
parameter no longer compile and must pass an explicit value.

**Before → After**

```dart
// Before
ListSelectDelegate(
  selectionMode: SelectionMode.multiple,
);

// After
ListSelectDelegate(
  selectionMode: SelectionMode.multiple,
  entriesLoader: () async => fetchEntries(),
);
```

```dart
// Before
SelectView(
  delegate: delegate,
);

// After
SelectView(
  delegate: delegate,
  onChanged: (selected) { /* ... */ },
);
```

The same applies to the other concrete delegates (`CascadingSelectDelegate`,
`GridSelectDelegate`, `FlattenSelectDelegate`) and to custom
`SelectDelegate` subclasses, whose constructors must forward the now-required
`entriesLoader` argument to `super`.
