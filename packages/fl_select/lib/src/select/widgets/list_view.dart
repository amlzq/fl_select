import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_delegate.dart';
import '../select_entry.dart';
import 'constants.dart';
import 'custom_range_host.dart';
import 'list_tile.dart';
import 'skeleton_view.dart';

/// A list view that renders terminal-node [SelectEntry] entries as selectable
/// radio or checkbox tiles.
///
/// Handles all [SelectEntry] subtypes: [SelectTextEntry] and non-custom
/// [SelectRangeEntry] are rendered as tiles; a single custom
/// [SelectRangeEntry] is rendered as an input field at the header or footer.
///
/// This is the canonical render target for [SelectListLayout].
/// Only used in tabs or flatten; uses AutomaticKeepAliveClientMixin.
class SelectListView extends StatefulWidget {
  const SelectListView({
    super.key,
    this.category,
    required this.entries,
    this.selectedEntries,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
    this.selectionMode = SelectionMode.single,
    this.radioBuilder,
    this.checkboxBuilder,
    this.itemBuilder,
    this.showTitle = true,
    this.toText = '-',
  });

  /// The category this list belongs to, used to render its title.
  ///
  /// If provided and [showTitle] is true, the category's name is displayed as
  /// a header above the list. Otherwise no header is shown.
  final SelectCategoryEntry? category;

  /// The terminal-node entries to display as selectable list items.
  ///
  /// This list must be a terminal-node list (no further sub-categories). If it
  /// contains a range/custom entry, an input field is rendered at the header or
  /// footer.
  final List<SelectEntry> entries;

  /// The set of currently selected entries.
  ///
  /// An item is rendered as selected when it is contained in this set; the
  /// selection is reflected by the radio or checkbox tile.
  final SelectEntries? selectedEntries;

  /// Called when an item is tapped or a custom range value changes.
  ///
  /// The callback receives the affected item's index and its [SelectEntry].
  /// For custom range entries the view has already parsed and normalized the
  /// min/max values onto the entry before invoking this callback, so the
  /// listener only needs to update selection state.
  final OnChanged onChanged;

  /// The padding around the list content, including the title and input field.
  ///
  /// Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Determines whether a single or multiple items can be selected.
  ///
  /// Defaults to [SelectionMode.single], which renders radio tiles; when set to
  /// [SelectionMode.multiple], checkbox tiles are used instead.
  final SelectionMode selectionMode;

  /// Optional builder for the radio widget shown in [SelectionMode.single].
  final ToggleWidgetBuilder? radioBuilder;

  /// Optional builder for the checkbox widget shown in [SelectionMode.multiple].
  final ToggleWidgetBuilder? checkboxBuilder;

  /// Optional builder that fully replaces each list item's widget.
  ///
  /// When non-null, regular entries render as the returned widget instead of
  /// the radio/checkbox list tile; the builder renders its own selected-state
  /// visuals from `selected` and wires `onTap` (e.g. via [InkWell]) to its own
  /// gesture handler so taps keep flowing through this view's normal selection
  /// logic. Custom range entries still render as the built-in min/max input
  /// field.
  final SelectItemBuilder? itemBuilder;

  /// Whether to show the [category] name as a header above the list.
  ///
  /// Defaults to true. Has no effect when [category] is null.
  final bool showTitle;

  /// Text rendered between the two range input fields (default: `'-'`).
  final String toText;

  @override
  State<SelectListView> createState() => SelectListViewState();
}

class SelectListViewState extends State<SelectListView>
    with CustomRangeHost, AutomaticKeepAliveClientMixin {
  late List<SelectEntry> entriesWithoutCustom;

  late SelectEntries _selectedEntries;

  @override
  List<SelectEntry> get customRangeEntries => widget.entries;

  @override
  SelectEntry? get customRangeCategory => widget.category;

  @override
  SelectEntries get customRangeSelectedEntries => _selectedEntries;

  @override
  String get customRangeToText => widget.toText;

  @override
  void notifyCustomRangeChanged(int index, SelectEntry entry) =>
      widget.onChanged(index, entry);

  @override
  void initState() {
    super.initState();

    _selectedEntries = widget.selectedEntries ?? {};

    initCustomRange();

    entriesWithoutCustom = hasCustomRange
        ? widget.entries.where(testNotCustomItem).toList()
        : widget.entries;
  }

  @override
  void didUpdateWidget(covariant SelectListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _selectedEntries = widget.selectedEntries ?? {};

    // When the custom range was selected and is now removed (e.g. tapping a
    // preset or clicking reset), the shared host clears the input fields so
    // stale values are not left behind. It only reacts to this transition
    // (not every rebuild) to avoid clobbering text the user is actively
    // typing.
    updateCustomRange(oldSelectedEntries: oldWidget.selectedEntries ?? {});

    entriesWithoutCustom = hasCustomRange
        ? widget.entries.where(testNotCustomItem).toList()
        : widget.entries;
  }

  @override
  void dispose() {
    disposeCustomRange();

    super.dispose();
  }

  void _onItemTap(int index, SelectEntry entry) {
    // Clear custom input
    clearCustomRangeInput();
    widget.onChanged(index, entry);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showTitle = widget.showTitle && widget.category?.name != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category label
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleSmall ??
                  const TextStyle(fontSize: 16),
              child: Text(widget.category?.name ?? ''),
            ),
          ),
        // An input item at header
        if (firstCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: true,
            padding: const EdgeInsets.only(top: 10.0),
          ),
        // List of items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: entriesWithoutCustom.length,
          itemBuilder: (context, index) {
            final entry = entriesWithoutCustom[index];
            final selected = widget.selectedEntries?.contains(entry) ?? false;
            final customBuilder = widget.itemBuilder;
            if (customBuilder != null) {
              return customBuilder(
                context,
                entry,
                selected: selected,
                onTap: () => _onItemTap(index, entry),
              );
            }
            if (SelectionMode.single == widget.selectionMode) {
              return SelectRadioListTile(
                onTap: () => _onItemTap(index, entry),
                label: entry.name ?? '',
                selected: selected,
                radioBuilder: widget.radioBuilder,
              );
            } else {
              return SelectCheckboxListTile(
                onTap: () => _onItemTap(index, entry),
                label: entry.name ?? '',
                checked: selected,
                checkboxBuilder: widget.checkboxBuilder,
              );
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 6);
          },
        ),
        // An input item at footer
        if (lastCustomRange != null)
          buildCustomRangeFieldTile(
            isHeader: false,
            padding: const EdgeInsets.only(top: 10.0),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Loading skeleton for [SelectListView].
class SelectListSkeleton extends StatelessWidget {
  const SelectListSkeleton({super.key, required this.itemCount});

  /// The number of placeholder items to render in the skeleton.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final random = Random();
    return SkeletonView(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return SkeletonTile(
            random: random,
            widthUsed: 30,
            height: kSelectListTileHeight,
            borderRadius: BorderRadius.circular(4),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 6);
        },
      ),
    );
  }
}
