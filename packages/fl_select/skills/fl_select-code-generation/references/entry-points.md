# Entry points

Five ways to show a select. All take any `SelectDelegate`; the delegate controls data loading and body rendering. Import once:

```dart
import 'package:fl_select/fl_select.dart';
```

## SelectView — inline

Embeds a select directly in a page or dialog body.

```dart
SelectView(
  delegate: CascadingSelectDelegate(entriesLoader: _fetchNeighborhood),
  onChanged: (selected) { /* fires on every selection change */ },
)
```

Constructor parameters: `delegate` (required) · `onChanged` (required, `void Function(SelectEntries)`) · `controller` (`SelectController`, for external control) · `maxHeightFactor` (default `0.5` — caps the body height as a fraction of available height; the body then scrolls internally) · `padding`, `decoration`, `margin`, `width`, `height`, `constraints` (sizing/outer decoration).

## PopupSelectBar — filter-bar tabs

A `PreferredSizeWidget` tab bar (use it as `AppBar.bottom`) that opens an overlay select when a tab is tapped. Provide `tabs` and a matching `selectDelegates` list — one delegate per tab, in order.

```dart
PopupSelectBar(
  tabs: const [
    PopupTab(label: 'Neighborhood'),
    PopupTab(label: 'Price'),
    PopupTab(label: 'Rooms'),
  ],
  selectDelegates: [
    CascadingSelectDelegate(entriesLoader: _fetchNeighborhood),
    GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchPrice),
    SideNavSelectDelegate(entriesLoader: _fetchRooms),
  ],
  onApplied: (tabData, selected) { /* PopupTabData + SelectEntries */ },
);
```

Key parameters: `tabs` / `selectDelegates` (required, lengths must match) · `onApplied` (required, `void Function(PopupTabData, SelectEntries)`) · `onChanged`, `onReset` · `controller` (`PopupSelectController`) · `initialIndex` · `selectTheme` (a `SelectThemeData` applied to every tab's delegate) · `direction` (`PopupSelectDirection.below` / `.above`) · bar styling: `height`, `isScrollable`, `backgroundColor`, `elevation`, `labelColor`, `unselectedLabelColor`, `labelStyle`, `unselectedLabelStyle`, `indicator`, `unselectedIndicator`, `overlayStyle` · overlay lifecycle hooks `onSelectShowed/Hidden/WillShow/WillHide`.

`PopupTab` fields: `label`, `labelLoader` (async label), `child` (fully custom tab), `tag`.

The selected tab label is derived from the applied selection automatically (falls back to `SelectLocalizations.multiple`, e.g. "Multiple", when more than one entry is selected). An applied selection that is empty or holds only "Any" entries restores the tab's original `label` — a `labelLoader` is skipped for an empty selection (0.11.2/0.12.0). When `isScrollable` is true, the tapped or focused tab scrolls to the center of the bar (0.11.0).

## PopupSelectButton — single trigger

Opens a select overlay on tap, like `PopupMenuButton`. Takes one `selectDelegate` plus `label` (or a custom `child`).

```dart
PopupSelectButton(
  label: 'Neighborhood',
  selectDelegate: GridSelectDelegate(crossAxisCount: 3, entriesLoader: _fetchNeighborhood),
  onApplied: (selected) { /* SelectEntries */ },
);

PopupSelectButton.elevated(label: 'Price', selectDelegate: ..., onApplied: ...);
PopupSelectButton.outlined(
  label: 'Rooms',
  icon: const Icon(Icons.filter_alt_outlined),
  selectDelegate: ...,
  onApplied: ...,
);
```

Variants: default constructor (filled), `.elevated(...)`, `.outlined(...)` (or pass `variant: PopupSelectButtonVariant.filled/elevated/outlined`). Other parameters mirror `PopupSelectBar`: `onApplied` (required, `void Function(SelectEntries)`), `onChanged`, `onReset`, `labelLoader`, `icon`, `direction`, `overlayStyle`, and the `onSelect*` lifecycle hooks.

## showSelect — modal dialog

```dart
final SelectEntries? selected = await showSelect(
  context: context,
  delegate: SideNavSelectDelegate(entriesLoader: _fetchRooms),
  title: const Text('Rooms'),
);
```

Returns the selected `SelectEntries` when applied, `null` when dismissed. Interaction mirrors `showTimePicker`: single-selection taps apply and close immediately; multi-selection requires "Apply", and "Reset" only clears.

Parameters: `context`, `delegate` (required) · `title`, `leading`, `trailing`, `centerTitle` (header row; `centerTitle` defaults platform-dependent — `true` on Android) · `barrierDismissible` (default `true`), `barrierColor`, `useRootNavigator` (default `true`), `builder`, `routeSettings`, `anchorPoint` · `elevation`, `shape`, `clipBehavior` (outer `Dialog` decoration; panel decoration is `delegate.panelTheme`). The dialog honors the ambient `DialogTheme.insetPadding` (0.11.3).

## showModalBottomSelect — modal bottom sheet

```dart
final SelectEntries? selected = await showModalBottomSelect(
  context: context,
  delegate: ListSelectDelegate(
    selectionMode: SelectionMode.multiple,
    entriesLoader: _fetchMore,
  ),
  title: const Text('More'),
);
```

Same return value and interaction as `showSelect`. Standard `showModalBottomSheet` parameters are forwarded: `isScrollControlled`, `isDismissible`, `enableDrag`, `showDragHandle`, `constraints`, `backgroundColor`, `elevation`, `shape`, `clipBehavior`, `barrierColor`, `useSafeArea`, `useRootNavigator`, `routeSettings`, `anchorPoint`. Header parameters (`title`/`leading`/`trailing`/`centerTitle`) are identical to `showSelect`.

Height behavior: the body is shrink-wrapped with internal scrolling; unless `constraints` is provided, a max height of 90% of the screen is applied automatically so tall content cannot push the action bar off-screen.

## SelectController

Pass a `controller` to `SelectView` (or a `PopupSelectController` to the popup entry points) for external control. Useful members:

- `realSelectedCategories` (`SelectEntries`) — top-level categories holding at least one non-"Any" selected child. Drives the category badges on `TabNavSelectDelegate` / `SideNavSelectDelegate` / `ExpandableSelectDelegate` and TabNavSelect's initial tab focus. Renamed from `badgedCategories` in 0.12.0; the old name is kept as a deprecated alias.
- `hasMultipleMode` — true when the delegate-level mode is multiple or any top-level category opts into multiple; drives the action bar visibility (see [entries.md](entries.md)).

## Choosing an entry point

| Need | Use |
| --- | --- |
| Select embedded in the page body | `SelectView` |
| Zillow/Airbnb-style filter bar under an AppBar | `PopupSelectBar` |
| One standalone trigger button | `PopupSelectButton` |
| Center-screen modal | `showSelect` |
| Mobile bottom sheet | `showModalBottomSelect` |
