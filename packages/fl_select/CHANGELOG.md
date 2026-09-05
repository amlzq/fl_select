## 0.12.0

- **FEATURE** the flat-data delegates now accept an `itemBuilder` to customize item rendering.

- **BUGFIX** selecting "Any" no longer surfaces as a real selection; the trigger label falls back to its original text.

- **BUGFIX** unselecting the last item in multiple mode now falls back to the "Any" placeholder on flat-data delegates.

- **BUGFIX** a category whose only selection is "Any" no longer steals the initial tab focus in `TabNavSelect`.

- **BUGFIX** the remaining scrollable bodies now chain touch-drag scrolling to the enclosing page-level scrollable.

- **DEPRECATION** rename `SelectController.badgedCategories` to `realSelectedCategories` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0120)).

- **DEPRECATION** split the dual-form `SelectChipBar` into the single-row `SelectChipBar` and the wrap-form `SelectWrapView` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0120)).

## 0.11.3

- **BUGFIX** unify the action bar visibility on `SelectController.hasMultipleMode` across all layouts.

- **BUGFIX** `showSelect` no longer ignores the ambient dialog theme's `insetPadding`.

- **FEATURE** `ExpandableSelect` now badges a category tile whose category holds a real selection.

- **FEATURE** `TabNavSelect` now badges a category tab whose category holds a real selection.

## 0.11.2

- **FEATURE** localize all built-in widget labels via `SelectLocalizations`.

- **BUGFIX** an empty applied selection now restores the trigger's original `label` even when a `labelLoader` is set.

## 0.11.1

- **BUGFIX** fix list tiles ignoring the effective selection mode: the resolved `selectionMode` and `ExpandableSelectDelegate`'s `radioBuilder` / `checkboxBuilder` are now forwarded to the body, so categories inherit the delegate's mode instead of always rendering radios.

- **BUGFIX** `ExpandableSelect` now chains touch-drag scrolling to the enclosing page like `SideNavSelect`, via a shared internal clamping-physics implementation.

- **BUGFIX** `SideNavSelect` now chains touch-drag scrolling to the enclosing page's scrollable instead of stopping dead at its edges, via a `ClampingScrollPhysics` subclass with no changes required on hosting pages.

- **BUGFIX** `SideNavSelect` now scrolls the tapped category's full section (including its top padding) to the top of the right column, and long-content jumps animate instead of teleporting.

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

- **FEATURE** add `toQueryMap()` and `toQueryParameters()` extensions on `SelectEntries` to serialize a selection tree into URL query parameters ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-080)).

- **BUGFIX** fix cascading selection state handling around search and cross-category clearing in `CascadingSelect` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-080)).

- **BUGFIX** fix cross-category clearing in two-level category trees ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-080)).

- **FEATURE** add search filtering to the select panel ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-080)).

- **DEPRECATION** rename the `previousSelected` / `resetSelected` API surface to `selectedEntries` / `resetEntries` to align naming across the library ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-080)).

## 0.7.2

- **BUGFIX** fix custom range input handling across `SelectListView`, `SelectGridView` and `SelectRangeView` — normalization, min-value loss, premature swapping and cross-category contamination.

- **BUGFIX** fix `SelectController.select` / `unselect` not affecting root-level entries in a flat structure.

- **BUGFIX** route malformed entry structures to the error UI instead of hanging the frame during the build phase.

- **DEPRECATION** deprecate the `FlattenSelectDelegate` / `FlattenSelect` grid parameters in favor of `SelectGridLayout` on `SelectCategoryEntry.layout` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-072)).

- **FEATURE** `FlattenSelect` now falls back to a wrapable `SelectChipBar` when `SelectCategoryEntry.layout` is null.

- **FEATURE** add the `children` factory constructors on `SelectCategoryEntry`, `SelectChildEntry` and `SelectTextEntry`, which inject their own `id` as every child's `parentId`.

## 0.7.1

- **FEATURE** `showSelect` now accepts optional `leading`, `trailing` and `centerTitle` widgets for its header row, mirroring `showModalBottomSelect`.

## 0.7.0

- **BREAKING** make `PopupSelectBar.selectDelegates` and `PopupSelectBar.onApplied` required.

- **BREAKING** make `PopupSelectButton.selectDelegate` and `PopupSelectButton.onApplied` required.

- **BREAKING** make `SelectDelegate.entriesLoader` and `SelectView.onChanged` required ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-070)).

- **BREAKING** remove all deprecated aliases, parameters, getters and methods introduced in 0.5.0 by the `Select*` / `PopupSelect*` renaming; use the `Select*` / `PopupSelect*` names instead ([Migration guide](https://github.com/amlzq/criteria_selector/blob/main/MIGRATION.md#migrate-to-050)).

- **DEPRECATION** rename the `onSelector*` lifecycle callbacks on `PopupSelectBar` and `PopupSelectButton` to `onSelect*`, with the old names kept as deprecated aliases ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-070)).

- **DEPRECATION** rename the `PopupSelectController` `*Selector*` lifecycle members to `*Select*`, with the old names kept as deprecated aliases ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-070)).

- **FEATURE** `FlattenSelect` now renders each category according to its `SelectCategoryEntry.layout`, matching `ListSelect` / `GridSelect`.
