## Next

- **BUGFIX** `ExpandableSelect` now chains touch-drag scrolling to the enclosing page the same way `SideNavSelect` does: drags past the body's edges hand the unconsumed distance to the nearest same-direction ancestor scrollable (e.g. the page's `SingleChildScrollView`), reverse drags unwind the ancestor's chained offset first, and flings released at an edge transfer their momentum. The chaining physics now live in a shared internal implementation reused by both selects.

- **BUGFIX** `SideNavSelect` now chains touch-drag scrolling to the enclosing page: dragging the right column past its start/end edge hands the unconsumed drag to the nearest same-direction ancestor scrollable (e.g. the page's `SingleChildScrollView`), dragging back first unwinds the ancestor's chained offset before the column scrolls again, and a fling released while the column rests at an edge hands its momentum to the ancestor. This matches the framework's built-in pointer-wheel chaining and the native nested-scrolling behavior of iOS `UIScrollView` and Android `NestedScrollingParent`, instead of the column stopping dead at its edge while the page behind stayed stuck. Implemented via a `ClampingScrollPhysics` subclass that falls back to plain clamping behavior when no scrollable ancestor is found, requiring no changes to hosting pages.

- **BUGFIX** `SideNavSelect` now aligns the tapped category's section (instead of its bare title) with the top of the right column, keeping the section's top padding as breathing room and sharing one geometric anchor with the scroll-linked highlight. The right column prefetches sections eagerly (finite 10000px cache extent), so taps scroll in one continuous animation; the estimate-then-jump fallback for extremely long content now animates instead of teleporting.

## 0.11.0

- **DEPRECATION** the dual-mode delegates (`FlattenSelectDelegate`, `GridSelectDelegate`, `ListSelectDelegate` with two-level data) are deprecated in favor of the single-purpose ones above and **will be removed in a future minor version** ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0110)).

- **DEPRECATION** rename `SelectChipLayout` to `SelectWrapLayout`; the old name is kept as a deprecated alias and **will be removed in a future minor version** ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0110)).

- **FEATURE** add `TabNavSelectDelegate` — a two-level select with category tabs on top driving the content below, split out of `GridSelectDelegate`'s two-level mode. Category layouts default to the delegate's `defaultLayout` (a 3-column grid) instead of being derived from grid parameters.

- **FEATURE** add `SideNavSelectDelegate` — the renamed two-level "flatten" select: a category sidebar on the left scrolls the single right column to the matching section, with scroll-linked highlighting.

- **FEATURE** add `WrapSelectDelegate` — a flat select whose parentless entries render directly as a wrapable chip bar, split out of `FlattenSelectDelegate`'s flat mode.

- **FEATURE** add `ExpandableSelectDelegate` — a two-level select with one expandable group per category, split out of `ListSelectDelegate`'s two-level mode.

- **FEATURE** `PopupSelectBar`, `SelectTabBar` and `SelectSideBar` now scroll the tapped or focused tab to the center when `isScrollable` is true.

## 0.10.0

- **FEATURE** add `SelectEntryCodec` — declarative JSON import/export for entry trees (`fromJson` / `toJson`), powering the new GenUI bridge package [`fl_select_genui`](https://github.com/amlzq/fl_select/tree/main/packages/fl_select_genui).

- **BREAKING** remove the deprecated `FlattenSelectDelegate` grid parameters and the matching `FlattenSelect` widget parameters (no effect since 0.7.2); set a `SelectGridLayout` on `SelectCategoryEntry.layout` instead ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0100)).

- **BREAKING** remove the deprecated `SelectController` `previousSelected` / `resetSelected` aliases (deprecated since 0.8.0); pass `selectedEntries` / `resetEntries` instead ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0100)).

## 0.9.0

- **BREAKING** remove the deprecated `onSelector*` lifecycle aliases and `PopupSelectController` `hideSelector` / `toggleSelector` / `isSelectorShowing` members; use the `onSelect*` names and `hideSelect` / `toggleSelect` / `isSelectShowing` instead ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-070)).

- **BREAKING** change the default `variant` of `PopupSelectButton` from `filled` to `text`; use `PopupSelectButton.filled` for the previous default look ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-090)).

- **BREAKING** make `SelectCategoryEntry` selection modes nullable and inheriting — `selectionMode` / `headerSelectionMode` / `footerSelectionMode` now default to null and inherit the delegate-level mode instead of defaulting to `SelectionMode.single` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-090)).

- **FEATURE** add `PopupSelectButtonVariant.text` and the `PopupSelectButton.filled` named constructor.

- **FEATURE** add synchronous data support to `SelectDelegate` via `entries` / `selectedEntries` / `resetEntries` as alternatives to the loader callbacks.

- **BUGFIX** export `PopupSelectDirection` from the public API.

- **BUGFIX** make `SelectPanel` shrink-wrap its height to the content again in dialogs and bottom sheets.

## 0.8.0

- **FEATURE** add `toQueryMap()` and `toQueryParameters()` extensions on `SelectEntries` to serialize a selection tree into URL query parameters. Each category contributes key/value pairs keyed by its own id with the deepest selected leaf ids as values; header/footer subtrees are keyed by their own ids; an "any" leaf resolves to its parent id; and a custom `SelectRangeEntry` formats as `min-max`.
  - `toQueryMap()` returns a `Map<String, List<String>>` mirroring `Uri.queryParametersAll`, so repeated keys can be read back without losing values, or handed to HTTP clients that accept multi-value maps directly.
  - `toQueryParameters({arrayFormat, delimiter, encode})` renders the map into a query string, with multi-value layouts selected by the new `SelectArrayFormat` enum: `repeat` (default, `cate1=a&cate1=b`), `brackets` (`cate1[]=a`), `comma` (`cate1=a,b`), `indices` (`cate1[0]=a`), and `delimited` (`cate1=a|b` with a custom `delimiter`, covering OpenAPI `pipeDelimited`/`spaceDelimited`). Values are percent-encoded by default.

- **BUGFIX** fix cascading selection state handling around search and cross-category clearing in `CascadingSelect`: focusing a category no longer clears other categories' selections; per-category single mode only clears selections within its own subtree; header/footer selections are cleared across categories; deeper search matches are auto-expanded; canceling a search restores the original unfiltered tree entries.

- **BUGFIX** fix cross-category clearing in two-level category trees (`GridSelect`, `ListSelect`, `FlattenSelect`): selecting a leaf in one category now clears every other category's selections when the delegate is in single mode, mirroring the cascading behavior.

- **FEATURE** add search filtering to the select panel. Every `SelectDelegate` accepts `searchEnabled`, `searchPredicate`, `searchHintText` and `searchDebounceDuration`; when enabled, a `SelectSearchBar` renders above the body and filters displayed entries (debounced 300 ms by default) while preserving layout and selection state. The search bar's look is customizable via the new `SelectSearchBarTheme`, per delegate or globally via `SelectThemeData`.

- **DEPRECATION** rename the `previousSelected` / `resetSelected` API surface to `selectedEntries` / `resetEntries` to align naming across the library. Only the public API keeps the old names as deprecated aliases for backward compatibility; they **will be removed in a future minor version**. No behavior changes.

## 0.7.2

- **BUGFIX** fix custom range input handling across `SelectListView`, `SelectGridView` and `SelectRangeView`:
  - **values not refreshing after normalization** — `_commitCustomRange` now writes the canonical (min ≤ max) order back into the min/max fields, so entering an inverted range (e.g. min `222` / max `100`) immediately reflects `100` / `222` on screen.
  - **min value being lost** — an inverted range is only swapped when both fields are non-empty; an empty field (parsed as `0`) no longer spuriously triggers a swap that clears the min field while typing min first.
  - **premature swap while typing** — `SelectListView` now listens only to the focus nodes and commits on focus loss (matching `SelectGridView`), instead of committing on every keystroke, so typing `222` then starting `111` no longer flips the fields before the user finishes.
  - **cross-category contamination** — when multiple `SelectCategoryEntry`s each own a `SelectRangeEntry.custom()` (all sharing the same `custom` id) inside a `ListSelect` tree, restoring the slider/fields now scopes to the entry whose `parentId` matches the current category, so committing a value in one category no longer leaks into another category's inputs or slider.

- **BUGFIX** fix `SelectController.select` / `unselect` not affecting root-level entries in a flat structure. `findPath` returns a single-element path for such entries, so the flat-handling branch (which required `path.isEmpty`) was never reached and `select`/`unselect` silently no-op'd. The flat branch now also matches when the path's first element is not a `SelectCategoryEntry`. This fixes committing a custom range in single mode not deselecting the previously selected option.

- **BUGFIX** harden against build-phase crashes that previously froze the UI with no console output: `SelectController.validateEntries` now additionally asserts that every top-level entry is a `SelectCategoryEntry` in a two-level-or-deeper structure, so `SelectPanel` routes malformed structures to the error UI instead of hanging the frame. The four `as SelectCategoryEntry` casts in `GridSelect`/`ListSelect`/`FlattenSelect`/`CascadingSelect` were replaced with `is`-checked safe conversions as a second line of defense.

- **DEPRECATION** mark `FlattenSelectDelegate.crossAxisCount`, `FlattenSelectDelegate.mainAxisSpacing`, `FlattenSelectDelegate.crossAxisSpacing` and `FlattenSelectDelegate.childAspectRatio` as deprecated. `FlattenSelect` now falls back to `SelectChipLayout` when `SelectCategoryEntry.layout` is null, so these delegate grid parameters no longer affect rendering. Set a `SelectGridLayout` on `SelectCategoryEntry.layout` instead.

- **FEATURE** when `SelectCategoryEntry.layout` is null, `FlattenSelect` now falls back to a wrapable `SelectChipBar` (`SelectChipLayout`) instead of a grid built from the widget's own cross-axis parameters.

- **FEATURE** add the `children` factory constructors on `SelectCategoryEntry`, `SelectChildEntry` and `SelectTextEntry`. Each automatically injects its own `id` as the `SelectChildEntry.parentId` of every child (recursively), so you never need to write `parentId` on children by hand when building two-level-or-deeper trees — `SelectCategoryEntry.children` covers the category (root) level, while `SelectChildEntry.children` (and the type-preserving `SelectTextEntry.children`) cover deeper (non-root) levels. All share the injection logic via a common `_injectParentId` helper.

## 0.7.1

- **FEATURE** `showSelect` now accepts optional `leading`, `trailing` and `centerTitle` widgets to attach to the header row, mirroring `showModalBottomSelect`. Both entries now share a common `SelectHeader` widget that lays the title out with an outer `Stack` so the title stays truly centered across the full header width even when `leading` / `trailing` are asymmetrical.

## 0.7.0

- **BREAKING** make `PopupSelectBar.selectDelegates` required — it is now a non-nullable `List<SelectDelegate>` and must be provided to `PopupSelectBar`. `PopupSelectBar.onApplied` is likewise now required (`PopupSelectBarResultCallback`, non-nullable). Update call sites that previously omitted either parameter to pass them explicitly.

- **BREAKING** make `PopupSelectButton.selectDelegate` required — it is now a non-nullable `SelectDelegate` and must be provided to every `PopupSelectButton` constructor. `PopupSelectButton.onApplied` is likewise now required (`PopupSelectButtonResultCallback`, non-nullable). Update call sites that previously omitted either parameter to pass them explicitly.

- **BREAKING** make `SelectDelegate.entriesLoader` required — it is now a non-nullable `Future<SelectEntries> Function()` and must be provided by every delegate. `SelectView.onChanged` is likewise now required (`SelectCallback`, non-nullable). Update call sites that previously omitted either parameter to pass them explicitly.

- **BREAKING** remove all deprecated aliases, parameters, getters and methods introduced in 0.5.0 by the `Select*` / `PopupSelect*` renaming. This includes: the `Selector*Entry*` / `SelectorEntries` aliases, `SelectorBox`, `showSelector`, `showModalBottomSelector`, `SelectorTheme` / `SelectorThemeData`, `SelectorPanelTheme`, `SelectorDelegate` / `CascadingSelectorDelegate` / `ListSelectorDelegate` / `GridSelectorDelegate` / `FlattenSelectorDelegate`, `SelectorController` / `SelectorControllerProvider`, `SelectorCallback`, `SelectorLayout` / `SelectorListLayout` / `SelectorGridLayout` / `SelectorChipLayout` / `SelectorRangeLayout`, `SelectorLocalizations` / `SelectorLocalizationsDelegate`, `SelectorLabelLoader` / `SelectorLabelState`, `DropdownOverlayStyle`, `kSelectorListTileHeight`, the `DropdownSelector*` → `PopupSelect*` aliases (`DropdownSelectorBar`, `DropdownTab`, `DropdownSelectController`, `DropdownTabData`, `DropdownSelectControllerProvider`, `DropdownSelectorBarTheme`, `DropdownSelectorButton`, `DropdownSelectorButtonTheme`, `DropdownSelectorButtonVariant`, `DropdownSelectorButtonResultCallback`, `DropdownSelectorButtonWillToggleCallback`, `kDropdownSelectorButtonHeight`, `DropdownSelectorDirection`), and the `selectorDelegates` / `selectorTheme` / `selectorDelegate` parameters and getters, `previousSelectorDelegate`, `selectorController` and `attachSelectorDelegates` members. Use the `Select*` / `PopupSelect*` names instead; see the [Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-050) for the full old → new tables.

- **DEPRECATION** rename the selector lifecycle callbacks on `PopupSelectBar` and `PopupSelectButton` — `onSelectorShowed` / `onSelectorHidden` / `onSelectorWillShow` / `onSelectorWillHide` → `onSelectShowed` / `onSelectHidden` / `onSelectWillShow` / `onSelectWillHide`. The old names are retained as deprecated constructor parameters and getters that delegate to the new names (passing both at the same call site triggers an assertion) and will be removed in a future minor version.

- **DEPRECATION** rename `PopupSelectController.hideSelector` → `hideSelect`, `toggleSelector` → `toggleSelect`, and `isSelectorShowing` → `isSelectShowing` to drop the redundant `Selector` wording. The old names are retained as deprecated methods / getters that delegate to the new names and will be removed in a future minor version.

- **FEATURE** `FlattenSelect` now consumes `SelectCategoryEntry.layout` via an exhaustive `switch (layout)`, matching the behavior already present in `ListSelect` / `GridSelect`. Each category's right-side content renders as a `SelectListView`, `SelectGridView`, `SelectChipBar`, `SelectRangeView`, or `SelectCounter` depending on its layout, with the grid/list/counter/range layout-specific parameters (`crossAxisCount`, spacing, `childAspectRatio`, `toText`, etc.) and the delegate theme overrides (grid/field/chip) honored. When `layout` is null, it falls back to the grid using the widget's own `crossAxisCount` / `mainAxisSpacing` / `crossAxisSpacing` / `childAspectRatio`, so existing default behavior is unchanged.
