import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'action_bar_visibility.dart';
import 'constants.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_layout.dart';
import 'select_search_filter.dart';
import 'widgets/widgets.dart';

/// Vertical layout: category tabs on top and a grid of items below.
/// Supports both one-dimensional (flat entries) and two-dimensional
/// (category -> children) structured data.
///
/// Behavior notes:
/// - In a flat 1D structure, the top-level entries are rendered directly as a
///   grid and no category tabs are shown.
/// - In a two-level structure, category tabs drive which children are shown.
/// - If a category contains an "Any" child entry, it may be selected by default.
/// - If a category contains a custom range entry ([SelectRangeEntry.custom]),
///   two numeric fields are shown for min/max input.
/// - When an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
/// - In multi-selection mode, the action bar is shown and "Apply" produces the
///   final clipped selection tree.
class GridSelect extends StatefulWidget {
  final GridSelectDelegate delegate;
  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  const GridSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  @override
  State<GridSelect> createState() => GridSelectState();
}

class GridSelectState extends State<GridSelect> {
  /// Focused category entry (only used in a 2D structure).
  SelectCategoryEntry? _tempSelectedCategory;

  SelectController? controller;
  bool _didInitCategoryFromState = false;

  bool get _isSearching => widget.searchQuery.isNotEmpty;

  List<SelectEntry> get _displayEntries => _isSearching
      ? filterEntriesForSearch(widget.entries, widget.searchQuery,
          predicate: widget.searchPredicate)
      : widget.entries;

  /// Returns the currently selected category that exists in [_displayEntries],
  /// or falls back to the first available category.
  SelectCategoryEntry? get _effectiveSelectedCategory {
    final cats = _displayEntries.whereType<SelectCategoryEntry>();
    if (_tempSelectedCategory != null &&
        cats.any((c) => c.id == _tempSelectedCategory!.id)) {
      return _tempSelectedCategory;
    }
    return cats.firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    final first = widget.entries.firstOrNull;
    _tempSelectedCategory = first is SelectCategoryEntry ? first : null;
  }

  /// Whether the entries form a two-dimensional (category -> children) tree.
  bool get _isCategoryTree => widget.entries.firstOrNull is SelectCategoryEntry;

  @override
  void dispose() {
    controller?.removeListener(_handleSelectControllerTick);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectController(context);
  }

  @override
  void didUpdateWidget(covariant GridSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSelectController(context);
  }

  void _updateSelectController(BuildContext context) {
    if (controller == null) {
      controller = SelectController.of(context)!;
      controller?.addListener(_handleSelectControllerTick);
    }
    controller?.bindState(
      widget.entries,
      initializeAnyIfEmpty: true,
      selectedEntriesOverride: widget.selectedEntries,
    );
    if (_isCategoryTree && !_didInitCategoryFromState) {
      final selectedCategory = controller
          ?.selectedEntriesAtLevel(0)
          .whereType<SelectCategoryEntry>()
          .firstOrNull;
      if (selectedCategory != null) {
        _tempSelectedCategory = selectedCategory;
      }
      _didInitCategoryFromState = true;
    }
  }

  GridSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
  }

  /// Selection Mode for category entries
  SelectionMode? get categorySelectionMode => delegate.selectionMode;

  /// Selection Mode for the selected category sub-items
  SelectionMode get childrenSelectionMode =>
      _tempSelectedCategory?.selectionMode ?? SelectionMode.single;

  /// Selection Mode for delegate.
  /// It is jointly determined by the category selection mode and the sub-item selection mode.
  SelectionMode? get selectSelectionMode {
    if (SelectionMode.multiple == categorySelectionMode) {
      return SelectionMode.multiple;
    }
    if (widget.entries.firstWhereOrNull(testMultipleElement) != null) {
      return SelectionMode.multiple;
    }
    return SelectionMode.single;
  }

  void _onCategoryItemTap(SelectCategoryEntry entry) {
    if (entry == _tempSelectedCategory) return;
    _tempSelectedCategory = entry;
    controller?.focusCategoryEntry(
      entry,
      selectionMode: categorySelectionMode ?? SelectionMode.single,
    );
    setState(() {});
  }

  void _onTerminalItemTap(SelectChildEntry entry) {
    if (!_isCategoryTree) {
      if (entry is SelectRangeEntry && entry.isCustom) {
        final hasRange = entry.min != null || entry.max != null;
        if (hasRange) {
          controller?.select(entry.id, parentId: entry.parentId);
        } else {
          controller?.unselect(entry.id, parentId: entry.parentId);
        }
      } else {
        controller?.toggleFlatEntry(
          entry,
          selectionMode: selectSelectionMode ?? SelectionMode.single,
          isCategoryTree: false,
        );
      }
      _setStateOrImmediateApply(entry);
      return;
    }

    final category = widget.entries
        .whereType<SelectCategoryEntry>()
        .singleWhereOrNull((e) => e.id == entry.parentId);
    if (category == null) {
      assert(() {
        debugPrint(
          'GridSelect: child entry "${entry.id}" has a parentId of '
          '"${entry.parentId}" that does not match any category; the tap was '
          'ignored. Check that the child\'s parentId points to its owning '
          'category id (a 2D-or-deeper structure).',
        );
        return true;
      }());
      return;
    }

    if (entry is SelectRangeEntry && entry.isCustom) {
      final hasRange = entry.min != null || entry.max != null;
      if (hasRange) {
        controller?.select(entry.id, parentId: entry.parentId);
      } else {
        controller?.unselect(entry.id, parentId: entry.parentId);
      }
    } else {
      controller?.toggleFlatEntry(
        entry,
        // Cross-category clearing must follow the delegate-level mode. The
        // mixed [selectSelectionMode] reports multiple as soon as any
        // category opts into multiple, which would disable the clearing.
        selectionMode: categorySelectionMode ?? SelectionMode.single,
        isCategoryTree: true,
        category: category,
      );
    }

    _setStateOrImmediateApply(entry);
  }

  void _setStateOrImmediateApply(SelectChildEntry entry) {
    if (SelectionMode.single == selectSelectionMode || entry.immediate) {
      // No need to tap "Apply"; return result immediately
      _onApplyTap();
    } else {
      setState(() {});
      controller?.emitChangeFromState();
    }
  }

  void _onResetTap() {
    if (!_isCategoryTree) {
      controller?.resetState(initializeAnyIfEmpty: true);
    } else {
      // Reset only the currently focused category (tab) rather than every
      // category, so selections in the other tabs are preserved.
      controller?.resetCategoryState(
        _tempSelectedCategory!,
        initializeAnyIfEmpty: true,
      );
    }
    setState(() {});
    controller?.reset();
  }

  void _onApplyTap() {
    controller?.applyFromState();
  }

  Widget _buildCategoryView(
    SelectCategoryEntry category, {
    required int index,
  }) {
    final entries = category.children?.toList() ?? [];
    final selectedEntries =
        controller?.selectedEntriesForParent(category.id, level: 1) ?? {};
    final layout = category.layout ??
        SelectGridLayout(
          crossAxisCount: delegate.crossAxisCount,
          childAspectRatio: delegate.childAspectRatio,
          mainAxisSpacing: delegate.mainAxisSpacing,
          crossAxisSpacing: delegate.crossAxisSpacing,
        );

    return switch (layout) {
      SelectListLayout(:final toText) => SelectListView(
          key: ValueKey('category_$index'),
          category: category,
          showTitle: false,
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: (_, entry) =>
              _onTerminalItemTap(entry as SelectChildEntry),
          toText: toText,
          radioBuilder: delegate.radioBuilder,
          checkboxBuilder: delegate.checkboxBuilder,
        ),
      SelectGridLayout(
        :final crossAxisCount,
        :final mainAxisSpacing,
        :final crossAxisSpacing,
        :final childAspectRatio,
        :final toText,
      ) =>
        SelectGridView(
          key: ValueKey('category_$index'),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          tileVariant: delegate.gridTileTheme?.variant,
          fieldVariant: delegate.fieldTileTheme?.variant,
          category: category,
          showTitle: false,
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: (_, entry) =>
              _onTerminalItemTap(entry as SelectChildEntry),
          toText: toText,
        ),
      SelectChipLayout(
        :final spacing,
        :final runSpacing,
      ) =>
        SelectChipBar(
          key: ValueKey('category_$index'),
          category: category,
          entries: entries,
          selectedEntries: selectedEntries,
          showTitle: false,
          isWrapable: true,
          spacing: spacing,
          runSpacing: runSpacing,
          backgroundColor: delegate.chipBarTheme?.backgroundColor,
          padding: delegate.chipBarTheme?.padding,
          variant: delegate.chipBarTheme?.variant,
          chipColor: delegate.chipBarTheme?.chipColor,
          selectedChipColor: delegate.chipBarTheme?.selectedChipColor,
          labelStyle: delegate.chipBarTheme?.labelStyle,
          selectedLabelStyle: delegate.chipBarTheme?.selectedLabelStyle,
          onChanged: (_, item) => _onTerminalItemTap(item as SelectChildEntry),
        ),
      SelectRangeLayout(:final toText) => SelectRangeView(
          key: ValueKey('category_$index'),
          category: category,
          showTitle: false,
          toText: toText,
          entries: entries,
          selectedEntries: selectedEntries,
          fieldVariant: delegate.fieldTileTheme?.variant,
          onChanged: (_, entry) =>
              _onTerminalItemTap(entry as SelectChildEntry),
        ),
      SelectCounterLayout() => SelectCounter(
          key: ValueKey('category_$index'),
          category: category,
          showTitle: false,
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: (_, entry) =>
              _onTerminalItemTap(entry as SelectChildEntry),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // In a flat 1D structure there are no categories, so no tab bar is shown
    // and the top-level entries are rendered directly as a grid.
    if (!_isCategoryTree) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: SelectGridView(
                crossAxisCount: delegate.crossAxisCount,
                mainAxisSpacing: delegate.mainAxisSpacing,
                crossAxisSpacing: delegate.crossAxisSpacing,
                childAspectRatio: delegate.childAspectRatio,
                tileVariant: delegate.gridTileTheme?.variant,
                fieldVariant: delegate.fieldTileTheme?.variant,
                entries: _displayEntries,
                selectedEntries: controller?.selectedEntriesAtLevel(0) ?? {},
                onChanged: (_, entry) =>
                    _onTerminalItemTap(entry as SelectChildEntry),
              ),
            ),
          ),
          if (SelectionMode.multiple == selectSelectionMode &&
              !SelectActionBarVisibility.isHidden(context))
            delegate.actionBarBuilder?.call(
                  context,
                  onResetTap: _onResetTap,
                  onApplyTap: _onApplyTap,
                ) ??
                SelectActionBar(
                  resetText: delegate.resetText,
                  applyText: delegate.applyText,
                  resetFlex: delegate.actionBarTheme?.resetFlex,
                  applyFlex: delegate.actionBarTheme?.applyFlex,
                  onResetTap: _onResetTap,
                  onApplyTap: _onApplyTap,
                ),
        ],
      );
    }

    final category = _effectiveSelectedCategory;
    if (category == null) {
      // No categories match the search query.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Flexible(child: Center(child: Text('No results'))),
          if (SelectionMode.multiple == selectSelectionMode &&
              !SelectActionBarVisibility.isHidden(context))
            delegate.actionBarBuilder?.call(
                  context,
                  onResetTap: _onResetTap,
                  onApplyTap: _onApplyTap,
                ) ??
                SelectActionBar(
                  resetText: delegate.resetText,
                  applyText: delegate.applyText,
                  resetFlex: delegate.actionBarTheme?.resetFlex,
                  applyFlex: delegate.actionBarTheme?.applyFlex,
                  onResetTap: _onResetTap,
                  onApplyTap: _onApplyTap,
                ),
        ],
      );
    }

    /// Focused category index
    final tempSelectedCategoryIndex = _displayEntries.indexOf(category);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_displayEntries.length > 1)
          SelectTabBar(
            isScrollable: false,
            onChanged: (_, item) =>
                _onCategoryItemTap(item as SelectCategoryEntry),
            entries: _displayEntries,
            selectedCategories: {category},
            focusedIndex: tempSelectedCategoryIndex,
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: _buildCategoryView(
              category,
              index: tempSelectedCategoryIndex,
            ),
          ),
        ),
        if (SelectionMode.multiple == selectSelectionMode &&
            !SelectActionBarVisibility.isHidden(context))
          delegate.actionBarBuilder?.call(
                context,
                onResetTap: _onResetTap,
                onApplyTap: _onApplyTap,
              ) ??
              SelectActionBar(
                resetText: delegate.resetText,
                applyText: delegate.applyText,
                resetFlex: delegate.actionBarTheme?.resetFlex,
                applyFlex: delegate.actionBarTheme?.applyFlex,
                onResetTap: _onResetTap,
                onApplyTap: _onApplyTap,
              ),
      ],
    );
  }
}

class GridSelectSkeleton extends StatelessWidget {
  /// Loading skeleton for [GridSelect].
  const GridSelectSkeleton({
    super.key,
    required this.itemCount,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  });

  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SelectTabBarSkeleton(),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SelectGridSkeleton(
              itemCount: itemCount,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SelectActionBarSkeleton(),
      ],
    );
  }
}
