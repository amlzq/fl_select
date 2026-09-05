# Migration Guide

## MIGRATE TO Next

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
