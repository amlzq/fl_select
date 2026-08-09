import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_entry.dart';
import 'constants.dart';
import 'field_tile.dart';
import 'list_tile.dart';
import 'skeleton_view.dart';

/// A list view that can include a single input item.
/// Must be a terminal-node list.
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
        .any((e) => e is SelectRangeEntry && e.isCustom);
    final newHasCustom =
        _selectedEntries.any((e) => e is SelectRangeEntry && e.isCustom);
    if (oldHadCustom && !newHasCustom) {
      _clearAllInput();
      _unfocusAllInput();
    }
  }

  void _restoreCustomSelectionToInputs() {
    final selectedCustom = _selectedEntries
        .whereType<SelectRangeEntry>()
        .firstWhereOrNull((e) => e.isCustom);
    // Temporarily remove listeners to avoid triggering _inputListener during
    // build phase (e.g. when called from didUpdateWidget), which would cause
    // setState() or markNeedsBuild() called during build.
    _minController?.removeListener(_inputListener);
    _maxController?.removeListener(_inputListener);
    _minController?.text = selectedCustom?.min?.toString() ?? '';
    _maxController?.text = selectedCustom?.max?.toString() ?? '';
    _minController?.addListener(_inputListener);
    _maxController?.addListener(_inputListener);
  }

  @override
  void dispose() {
    _minController?.removeListener(_inputListener);
    _maxController?.removeListener(_inputListener);
    _minFocusNode?.removeListener(_onFocusChanged);
    _maxFocusNode?.removeListener(_onFocusChanged);

    _minController?.dispose();
    _maxController?.dispose();

    _minFocusNode?.dispose();
    _maxFocusNode?.dispose();

    super.dispose();
  }

  void _initializeInput() {
    if (_minController == null) {
      _minController = TextEditingController();
      _minController?.addListener(_inputListener);
    }
    if (_maxController == null) {
      _maxController = TextEditingController();
      _maxController?.addListener(_inputListener);
    }
    _minFocusNode ??= FocusNode();
    _maxFocusNode ??= FocusNode();
    _minFocusNode?.addListener(_onFocusChanged);
    _maxFocusNode?.addListener(_onFocusChanged);
  }

  /// Parses the current min/max input, normalizes it onto [custom], and notifies
  /// the listener via [OnChanged].
  void _commitCustomRange(SelectRangeEntry? custom) {
    if (custom == null) return;
    var minInt = int.tryParse(_minController!.text) ?? 0;
    var maxInt = int.tryParse(_maxController!.text) ?? 0;
    if (minInt > maxInt) {
      final temp = minInt;
      minInt = maxInt;
      maxInt = temp;
    }
    custom.min = (minInt == 0) ? null : minInt;
    custom.max = (maxInt == 0) ? null : maxInt;
    final index = widget.entries.indexOf(custom);
    widget.onChanged(index, custom);
  }

  /// Listens to input fields; once the user types, clears selected items and
  /// commits the (possibly partial) range to the listener.
  void _inputListener() {
    if (widget.selectedEntries?.isNotEmpty ?? false) {
      setState(() {
        widget.selectedEntries?.clear();
      });
    }
    _commitCustomRange(firstCustomEntry);
    _commitCustomRange(lastCustomEntry);
  }

  /// When the range input loses focus, commit the final normalized values.
  void _onFocusChanged() {
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
      _minController?.removeListener(_inputListener);
      _maxController?.removeListener(_inputListener);
      _minController?.clear();
      _maxController?.clear();
      _minController?.addListener(_inputListener);
      _maxController?.addListener(_inputListener);
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
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category label
          if (widget.category != null && widget.showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                widget.category?.name ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
