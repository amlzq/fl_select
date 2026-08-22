# Migration Guide

## MIGRATE TO Next

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

Only the public-facing `SelectController` constructor parameters and getters
retain the old names as deprecated aliases for backward compatibility; they
**will be removed in a future minor version**. All other renamed members (on
`StateTree`, `bindState`, `SelectDelegate.buildBody`, and the four `Select*`
widgets) are internal and have been renamed without aliases — update call sites
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
