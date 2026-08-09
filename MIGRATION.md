# Migration Guide

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
