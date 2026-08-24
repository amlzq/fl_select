import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_entry.dart';
import 'constants.dart';
import 'field_tile.dart';
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
    with AutomaticKeepAliveClientMixin {
  SelectRangeEntry? firstCustomEntry;
  SelectRangeEntry? lastCustomEntry;

  late List<SelectEntry> entriesWithoutCustom;

  TextEditingController? _minController;
  TextEditingController? _maxController;

  FocusNode? _minFocusNode;
  FocusNode? _maxFocusNode;

  late SelectEntries _selectedEntries;

  @override
  void initState() {
    super.initState();

    _selectedEntries = widget.selectedEntries ?? {};

    firstCustomEntry = widget.entries.firstCustomOrNull;
    lastCustomEntry = widget.entries.lastCustomOrNull;

    entriesWithoutCustom = widget.entries;
    if (firstCustomEntry != null || lastCustomEntry != null) {
      entriesWithoutCustom = widget.entries.where(testNotCustomItem).toList();
      _initializeInput();
      _restoreCustomSelectionToInputs();
    }
  }

  @override
  void didUpdateWidget(covariant SelectListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedEntries = widget.selectedEntries ?? {};

    firstCustomEntry = widget.entries.firstCustomOrNull;
    lastCustomEntry = widget.entries.lastCustomOrNull;

    entriesWithoutCustom = widget.entries;
    if (firstCustomEntry != null || lastCustomEntry != null) {
      entriesWithoutCustom = widget.entries.where(testNotCustomItem).toList();
      _initializeInput();
      _restoreCustomSelectionToInputs();
    }

    // When the custom range was selected and is now removed (e.g. tapping a
    // preset or clicking reset), clear the input fields so stale values are not
    // left behind, mirroring [SelectGridViewState.didUpdateWidget]. We only
    // react to this transition (not every rebuild) to avoid clobbering text the
    // user is actively typing.
    final oldHadCustom = (oldWidget.selectedEntries ?? {})
        .whereType<SelectRangeEntry>()
        .any(_isOwnCustom);
    final newHasCustom =
        _selectedEntries.whereType<SelectRangeEntry>().any(_isOwnCustom);
    if (oldHadCustom && !newHasCustom) {
      _clearAllInput();
      _unfocusAllInput();
    }
  }

  /// Whether [e] is this view's own custom range entry.
  ///
  /// In a multi-category tree, every category shares the same level-1
  /// selection set and custom entries all use the same id (`custom`). We must
  /// therefore scope restoration to the entry owned by this category
  /// ([widget.category].id) so a value committed in one category never leaks
  /// into another category's input fields.
  bool _isOwnCustom(SelectRangeEntry e) {
    final categoryId = widget.category?.id;
    if (categoryId == null) return e.isCustom;
    return e.isCustom && e.parentId == categoryId;
  }

  void _restoreCustomSelectionToInputs() {
    final selectedCustom = _selectedEntries
        .whereType<SelectRangeEntry>()
        .where(_isOwnCustom)
        .firstWhereOrNull((e) => e.isCustom);
    _minController?.text = selectedCustom?.min?.toString() ?? '';
    _maxController?.text = selectedCustom?.max?.toString() ?? '';
  }

  @override
  void dispose() {
    _minFocusNode?.removeListener(_focusListener);
    _maxFocusNode?.removeListener(_focusListener);

    _minController?.dispose();
    _maxController?.dispose();

    _minFocusNode?.dispose();
    _maxFocusNode?.dispose();

    super.dispose();
  }

  void _initializeInput() {
    _minController ??= TextEditingController();
    _maxController ??= TextEditingController();
    _minFocusNode ??= FocusNode();
    _maxFocusNode ??= FocusNode();
    _minFocusNode?.addListener(_focusListener);
    _maxFocusNode?.addListener(_focusListener);
  }

  /// Commits the current min/max input to [custom].
  ///
  /// Mirrors [SelectGridViewState]'s behavior: it is only invoked on focus loss
  /// (from [_onFocusChanged]), never on every keystroke, so an inverted range is
  /// always swapped and written back without clobbering in-progress typing.
  void _commitCustomRange(SelectRangeEntry? custom) {
    if (custom == null) return;
    final minText = _minController!.text;
    final maxText = _maxController!.text;
    var minInt = int.tryParse(minText) ?? 0;
    var maxInt = int.tryParse(maxText) ?? 0;
    // Only normalize an inverted range when both bounds have actually been
    // entered. Otherwise an empty field (parsed as 0) would spuriously trigger
    // a swap and push a freshly-typed min value into the max field (or clear
    // the min field), losing the user's input.
    final bothEntered = minText.isNotEmpty && maxText.isNotEmpty;
    final swapped = bothEntered && minInt > maxInt;
    if (swapped) {
      final temp = minInt;
      minInt = maxInt;
      maxInt = temp;
    }
    custom.min = (minInt == 0) ? null : minInt;
    custom.max = (maxInt == 0) ? null : maxInt;
    // Reflect the canonical (swapped) order back into the fields so the display
    // immediately shows "left small, right big" instead of the raw typed order.
    if (swapped) {
      _minController?.text = custom.min?.toString() ?? '';
      _maxController?.text = custom.max?.toString() ?? '';
    }
    final index = widget.entries.indexOf(custom);
    widget.onChanged(index, custom);
  }

  /// When the range input loses focus, commit the final normalized values.
  void _focusListener() {
    if (!(_minFocusNode?.hasFocus ?? false) &&
        !(_maxFocusNode?.hasFocus ?? false)) {
      _commitCustomRange(firstCustomEntry);
      _commitCustomRange(lastCustomEntry);
    }
  }

  bool get inputNotEmpty =>
      (_minController?.text.isNotEmpty ?? false) ||
      (_maxController?.text.isNotEmpty ?? false);

  void _clearAllInput() {
    if (inputNotEmpty) {
      _minController?.clear();
      _maxController?.clear();
    }
  }

  bool get inputHasFocus =>
      (_minFocusNode?.hasFocus ?? false) || (_maxFocusNode?.hasFocus ?? false);

  void _unfocusAllInput() {
    if (inputHasFocus) {
      _minFocusNode?.unfocus();
      _maxFocusNode?.unfocus();
    }
  }

  void _onItemTap(int index, SelectEntry entry) {
    // Clear custom input
    _clearAllInput();
    _unfocusAllInput();
    widget.onChanged(index, entry);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showTitle = widget.showTitle && widget.category?.name != null;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: widget.padding,
      child: Column(
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
          if (firstCustomEntry != null)
            SelectFieldTile(
              firstCustomEntry!,
              padding: const EdgeInsets.only(top: 10.0),
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              separator: widget.toText,
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
          if (lastCustomEntry != null)
            SelectFieldTile(
              lastCustomEntry!,
              padding: const EdgeInsets.only(top: 10.0),
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              separator: widget.toText,
            ),
        ],
      ),
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
