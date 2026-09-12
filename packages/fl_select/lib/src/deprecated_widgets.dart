// Backward-compatible aliases for select widgets internalized from the
// public API.
//
// The widgets below are the select panel (`SelectPanel`) and its rendering
// targets, driven by a `SelectDelegate` + `SelectLayout` (or skeletons the
// delegates show while entries load). They are not meant to be constructed
// directly by apps, so
// `fl_select.dart` no longer re-exports their files. Each class here is a
// deprecated type alias (constants and functions are forwarded) that keeps
// existing code compiling with a warning.
//
// Delete this file (and its export in `fl_select.dart`) once the removal
// lands in a future minor release.
library;

import 'package:flutter/material.dart';

import 'select/select_entry.dart';
import 'select/select_panel.dart' as p;
import 'select/widgets/chip_host.dart' as h;
import 'select/widgets/widgets.dart' as w;

const String _removalNote = 'This will be removed in a future minor release.';

/// Scroll physics that chain inner scrollables to the enclosing page scroll.
@Deprecated(
  'ChainingClampingScrollPhysics is no longer part of the public API; the '
  'select widgets apply it internally. $_removalNote',
)
typedef ChainingClampingScrollPhysics = w.ChainingClampingScrollPhysics;

/// The default height of the single-row chip bar.
@Deprecated(
  'kSelectChipBarHeight is no longer part of the public API; it is applied '
  'internally by the chip bar. $_removalNote',
)
const double kSelectChipBarHeight = w.kSelectChipBarHeight;

/// The default expand/collapse animation duration of the expansion tile.
@Deprecated(
  'kSelectExpansionTileAnimationDuration is no longer part of the public '
  'API. $_removalNote',
)
const Duration kSelectExpansionTileAnimationDuration =
    w.kSelectExpansionTileAnimationDuration;

/// The default height of a select list tile.
@Deprecated(
  'kSelectListTileHeight is no longer part of the public API. $_removalNote',
)
const double kSelectListTileHeight = w.kSelectListTileHeight;

/// The default width of the side bar.
@Deprecated(
  'kSelectSideBarWidth is no longer part of the public API; set the width '
  'via SelectSideBarTheme.width instead. $_removalNote',
)
const double kSelectSideBarWidth = w.kSelectSideBarWidth;

/// Signature for selection-change callbacks used by the internal views.
@Deprecated(
  'OnChanged is no longer part of the public API; it moved to the internal '
  'widgets barrel. $_removalNote',
)
typedef OnChanged<T extends SelectEntry> = w.OnChanged<T>;

/// Resolves the chip visual configuration from the surrounding theme.
@Deprecated(
  'resolveSelectChipBarStyle is no longer part of the public API; resolve '
  'chip visuals from SelectChipBarTheme in your own code. $_removalNote',
)
SelectChipBarStyle resolveSelectChipBarStyle(
  BuildContext context, {
  w.SelectChipVariant? variant,
  Color? backgroundColor,
  EdgeInsetsGeometry? padding,
  Color? chipColor,
  Color? selectedChipColor,
  TextStyle? labelStyle,
  TextStyle? selectedLabelStyle,
}) {
  return h.resolveSelectChipBarStyle(
    context,
    variant: variant,
    backgroundColor: backgroundColor,
    padding: padding,
    chipColor: chipColor,
    selectedChipColor: selectedChipColor,
    labelStyle: labelStyle,
    selectedLabelStyle: selectedLabelStyle,
  );
}

/// Loading skeleton for [SelectActionBar] shown while entries load.
@Deprecated(
  'SelectActionBarSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectActionBarSkeleton = w.SelectActionBarSkeleton;

/// A small circular badge dot.
@Deprecated(
  'SelectBadge is no longer part of the public API; badges are styled via '
  'the select themes. $_removalNote',
)
typedef SelectBadge = w.SelectBadge;

/// A list tile with a trailing checkbox.
@Deprecated(
  'SelectCheckboxListTile is no longer part of the public API; use a select '
  'delegate with multiple selection to render checkbox tiles. $_removalNote',
)
typedef SelectCheckboxListTile = w.SelectCheckboxListTile;

/// A single selectable chip as rendered by the internal chip views.
@Deprecated(
  'SelectChip is no longer part of the public API; build custom chips in '
  'your itemBuilder, styled to match SelectChipBarTheme. $_removalNote',
)
typedef SelectChip = h.SelectChip;

/// A single-row bar of chips for the selected entries.
@Deprecated(
  'SelectChipBar is no longer part of the public API; it is rendered by '
  'SelectPanel via SelectDelegate. Style it with SelectChipBarTheme. '
  '$_removalNote',
)
typedef SelectChipBar = w.SelectChipBar;

/// Loading skeleton for [SelectChipBar].
@Deprecated(
  'SelectChipBarSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectChipBarSkeleton = w.SelectChipBarSkeleton;

/// The fully-resolved visual configuration of a chip view.
@Deprecated(
  'SelectChipBarStyle is no longer part of the public API. $_removalNote',
)
typedef SelectChipBarStyle = h.SelectChipBarStyle;

/// A spin-box counter stepping through a category's text entries.
@Deprecated(
  'SelectCounter is no longer part of the public API; drop a '
  'SelectCounterLayout on the category instead. $_removalNote',
)
typedef SelectCounter = w.SelectCounter;

/// An expandable tile that hosts nested categories.
@Deprecated(
  'SelectExpansionTile is no longer part of the public API; it is rendered '
  'by ExpandableSelectDelegate. $_removalNote',
)
typedef SelectExpansionTile = w.SelectExpansionTile;

/// An input tile for a custom min/max range entry.
@Deprecated(
  'SelectFieldTile is no longer part of the public API; it is rendered for '
  'custom SelectRangeEntry values. Style it with SelectFieldTileTheme. '
  '$_removalNote',
)
typedef SelectFieldTile = w.SelectFieldTile;

/// Loading skeleton for [SelectGridView].
@Deprecated(
  'SelectGridSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectGridSkeleton = w.SelectGridSkeleton;

/// A selectable tile used by grid layouts.
@Deprecated(
  'SelectGridTile is no longer part of the public API; it is rendered by '
  'grid layouts. Style it with SelectGridTileTheme. $_removalNote',
)
typedef SelectGridTile = w.SelectGridTile;

/// A grid of selectable entries.
@Deprecated(
  'SelectGridView is no longer part of the public API; it is rendered by '
  'SelectPanel via SelectDelegate with a SelectGridLayout. $_removalNote',
)
typedef SelectGridView = w.SelectGridView;

/// Loading skeleton for [SelectListView].
@Deprecated(
  'SelectListSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectListSkeleton = w.SelectListSkeleton;

/// A selectable list tile with an optional leading toggle.
@Deprecated(
  'SelectListTile is no longer part of the public API; it is rendered by '
  'list layouts. Style it with SelectListTileTheme. $_removalNote',
)
typedef SelectListTile = w.SelectListTile;

/// A list of selectable entries.
@Deprecated(
  'SelectListView is no longer part of the public API; it is rendered by '
  'SelectPanel via SelectDelegate with a SelectListLayout. $_removalNote',
)
typedef SelectListView = w.SelectListView;

/// A widget that renders a [SelectDelegate] and manages its selection state.
@Deprecated(
  'SelectPanel is no longer part of the public API; embed a SelectView, or '
  'open a modal via showSelect / showModalBottomSelect / PopupSelectBar. '
  '$_removalNote',
)
typedef SelectPanel = p.SelectPanel;

/// A list tile with a trailing radio.
@Deprecated(
  'SelectRadioListTile is no longer part of the public API; use a select '
  'delegate with single selection to render radio tiles. $_removalNote',
)
typedef SelectRadioListTile = w.SelectRadioListTile;

/// Loading skeleton for [SelectRangeView].
@Deprecated(
  'SelectRangeSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectRangeSkeleton = w.SelectRangeSkeleton;

/// A range slider for a custom range entry.
@Deprecated(
  'SelectRangeSlider is no longer part of the public API; it is rendered '
  'for custom SelectRangeEntry values. Style it with '
  'SelectRangeSliderTheme. $_removalNote',
)
typedef SelectRangeSlider = w.SelectRangeSlider;

/// A view hosting the range slider and its presets.
@Deprecated(
  'SelectRangeView is no longer part of the public API; drop a '
  'SelectRangeLayout on the category instead. $_removalNote',
)
typedef SelectRangeView = w.SelectRangeView;

/// The search bar shown at the top of searchable panels.
@Deprecated(
  'SelectSearchBar is no longer part of the public API; enable search on '
  'the delegate instead. Style it with SelectSearchBarTheme. $_removalNote',
)
typedef SelectSearchBar = w.SelectSearchBar;

/// The vertical category navigation bar.
@Deprecated(
  'SelectSideBar is no longer part of the public API; it is rendered by '
  'SideNavSelectDelegate. Style it with SelectSideBarTheme. $_removalNote',
)
typedef SelectSideBar = w.SelectSideBar;

/// Loading skeleton for [SelectSideBar].
@Deprecated(
  'SelectSideBarSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectSideBarSkeleton = w.SelectSideBarSkeleton;

/// The category tab bar.
@Deprecated(
  'SelectTabBar is no longer part of the public API; it is rendered by '
  'TabNavSelectDelegate. Style it with SelectTabBarTheme. $_removalNote',
)
typedef SelectTabBar = w.SelectTabBar;

/// Loading skeleton for [SelectTabBar].
@Deprecated(
  'SelectTabBarSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectTabBarSkeleton = w.SelectTabBarSkeleton;

/// A wrap of selectable entries.
@Deprecated(
  'SelectWrapView is no longer part of the public API; it is rendered by '
  'SelectPanel via SelectDelegate with a SelectWrapLayout. $_removalNote',
)
typedef SelectWrapView = w.SelectWrapView;

/// Loading skeleton for [SelectWrapView].
@Deprecated(
  'SelectWrapViewSkeleton is no longer part of the public API; delegates '
  'provide skeletons while entries load. $_removalNote',
)
typedef SelectWrapViewSkeleton = w.SelectWrapViewSkeleton;

/// A single placeholder tile inside a skeleton.
@Deprecated('SkeletonTile is no longer part of the public API. $_removalNote')
typedef SkeletonTile = w.SkeletonTile;

/// A shimmering placeholder shown while entries load.
@Deprecated('SkeletonView is no longer part of the public API. $_removalNote')
typedef SkeletonView = w.SkeletonView;
