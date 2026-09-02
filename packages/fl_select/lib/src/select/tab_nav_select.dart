import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../i18n/select_localizations.dart';
import 'action_bar_visibility.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_layout.dart';
import 'select_search_filter.dart';
import 'widgets/select_category_content.dart';
import 'widgets/widgets.dart';

/// Two-level layout: category tabs on top and the focused category's
/// children below.
///
/// Behavior notes:
/// - Category tabs drive which category's children are shown below, laid
///   out by the category's `layout` (defaulting to
///   [TabNavSelectDelegate.defaultLayout], then to a 3-column grid).
/// - When only one category is available, the tab bar is hidden.
/// - At most two levels are rendered; levels nested deeper than the second
///   are not rendered.
/// - If a category contains an "Any" child entry, it may be selected by
///   default.
/// - A category's `header`/`footer` entries (if any) are rendered as chip
///   bars above/below the focused category's content, mirroring
///   [CascadingSelect].
/// - If a category contains a custom range entry ([SelectRangeEntry.custom]),
///   two numeric fields are shown for min/max input.
/// - When an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
/// - A category tab renders a small badge dot in the top-right corner of its
///   label while the category holds a "real" selection (at least one selected
///   child that is not the "Any" placeholder), so selections made in the
///   other tabs stay visible.
/// - In multi-selection mode, the action bar is shown and "Apply" produces
///   the final clipped selection tree.
class TabNavSelect extends StatefulWidget {
  final TabNavSelectDelegate delegate;
  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  const TabNavSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  @override
  State<TabNavSelect> createState() => TabNavSelectState();
}

class TabNavSelectState extends State<TabNavSelect> {
  /// Focused category entry.
  SelectCategoryEntry? _focusedCategory;

  SelectController? controller;
  bool _didInitCategoryFromState = false;

  bool get _isSearching => widget.searchQuery.isNotEmpty;

  List<SelectEntry> get _displayEntries => _isSearching
      ? filterEntriesForSearch(widget.entries, widget.searchQuery,
          predicate: widget.searchPredicate)
      : widget.entries;

  /// Returns the focused category when it still exists in [_displayEntries],
  /// or falls back to the first available category.
  SelectCategoryEntry? get _effectiveFocusedCategory {
    final cats = _displayEntries.whereType<SelectCategoryEntry>();
    if (_focusedCategory != null &&
        cats.any((c) => c.id == _focusedCategory!.id)) {
      return _focusedCategory;
    }
    return cats.firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    final first = widget.entries.firstOrNull;
    _focusedCategory = first is SelectCategoryEntry ? first : null;
  }

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
  void didUpdateWidget(covariant TabNavSelect oldWidget) {
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
    if (!_didInitCategoryFromState) {
      final selectedCategory = controller
          ?.selectedEntriesAtLevel(0)
          .whereType<SelectCategoryEntry>()
          .firstOrNull;
      if (selectedCategory != null) {
        _focusedCategory = selectedCategory;
      }
      _didInitCategoryFromState = true;
    }
  }

  TabNavSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
  }

  void _onCategoryItemTap(SelectCategoryEntry entry) {
    if (entry == _focusedCategory) return;
    _focusedCategory = entry;
    controller?.focusCategoryEntry(
      entry,
      selectionMode: delegate.selectionMode,
    );
    setState(() {});
  }

  void _onTerminalItemTap(SelectChildEntry entry) {
    final category = widget.entries
        .whereType<SelectCategoryEntry>()
        .singleWhereOrNull((e) => e.id == entry.parentId);
    if (category == null) {
      assert(() {
        debugPrint(
          'TabNavSelect: child entry "${entry.id}" has a parentId of '
          '"${entry.parentId}" that does not match any category; the tap was '
          'ignored. Check that the child\'s parentId points to its owning '
          'category id (a two-level structure).',
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
        selectionMode: delegate.selectionMode,
        isCategoryTree: true,
        category: category,
      );
    }

    _setStateOrImmediateApply(entry);
  }

  void _setStateOrImmediateApply(SelectChildEntry entry) {
    if (controller?.hasMultipleMode != true || entry.immediate) {
      // No need to tap "Apply"; return result immediately
      _onApplyTap();
    } else {
      setState(() {});
      controller?.emitChangeFromState();
    }
  }

  SelectEntries _headerSelectedFor(String categoryId) =>
      controller?.selectedHeaderEntriesFor(categoryId) ?? <SelectEntry>{};

  SelectEntries _footerSelectedFor(String categoryId) =>
      controller?.selectedFooterEntriesFor(categoryId) ?? <SelectEntry>{};

  void _onHeaderOrFooterItemTap(
    bool isHeader,
    int chipIndex,
    SelectChildEntry entry,
  ) {
    final category = _effectiveFocusedCategory;
    if (category == null) return;

    final selectionMode = isHeader
        ? category.effectiveHeaderSelectionMode(delegate.selectionMode)
        : category.effectiveFooterSelectionMode(delegate.selectionMode);
    controller?.toggleHeaderOrFooterEntry(
      categoryId: category.id,
      entry: entry,
      selectionMode: selectionMode,
      isHeader: isHeader,
    );

    _setStateOrImmediateApply(entry);
  }

  void _onResetTap() {
    // Reset only the currently focused category (tab) rather than every
    // category, so selections in the other tabs are preserved.
    controller?.resetCategoryState(
      _focusedCategory!,
      initializeAnyIfEmpty: true,
    );
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
    return SelectCategoryContentView(
      category: category,
      index: index,
      selectedEntries:
          controller?.selectedEntriesForParent(category.id, level: 1) ?? {},
      fallbackLayout:
          delegate.defaultLayout ?? const SelectGridLayout(crossAxisCount: 3),
      delegate: delegate,
      radioBuilder: delegate.radioBuilder,
      checkboxBuilder: delegate.checkboxBuilder,
      onTerminalItemTap: _onTerminalItemTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = _effectiveFocusedCategory;
    if (category == null) {
      // No categories match the search query.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Center(
              child: Text(
                  SelectLocalizations.of(context)?.noResults ?? 'No results'),
            ),
          ),
          if (controller?.hasMultipleMode == true &&
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
    final focusedCategoryIndex = _displayEntries.indexOf(category);

    // A category badge should only appear when it has a "real" selection,
    // i.e. at least one selected child that is not the "Any" placeholder.
    // Selecting only "Any" must not trigger the badge.
    final selectedCategories = controller?.badgedCategories ?? <SelectEntry>{};

    final categoryHeader = category.header;
    final categoryFooter = category.footer;
    final headerSelected = _headerSelectedFor(category.id);
    final footerSelected = _footerSelectedFor(category.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_displayEntries.length > 1)
          SelectTabBar(
            isScrollable: delegate.isScrollable,
            onChanged: (_, item) =>
                _onCategoryItemTap(item as SelectCategoryEntry),
            entries: _displayEntries,
            selectedCategories: selectedCategories,
            focusedIndex: focusedCategoryIndex,
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categoryHeader != null && categoryHeader.children != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SelectChipBar(
                      category: categoryHeader,
                      entries: categoryHeader.children!.toList(),
                      selectedEntries: headerSelected,
                      variant: SelectChipVariant.filled,
                      isWrapable: true,
                      spacing: 12.0,
                      runSpacing: 12.0,
                      onChanged: (index, entry) => _onHeaderOrFooterItemTap
                          .call(true, index, entry as SelectChildEntry),
                    ),
                  ),
                Flexible(
                  child: _buildCategoryView(
                    category,
                    index: focusedCategoryIndex,
                  ),
                ),
                if (categoryFooter != null && categoryFooter.children != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SelectChipBar(
                      category: categoryFooter,
                      entries: categoryFooter.children!.toList(),
                      selectedEntries: footerSelected,
                      variant: SelectChipVariant.filled,
                      isWrapable: true,
                      spacing: 12.0,
                      runSpacing: 12.0,
                      onChanged: (index, entry) => _onHeaderOrFooterItemTap
                          .call(false, index, entry as SelectChildEntry),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (controller?.hasMultipleMode == true &&
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

/// Loading skeleton for [TabNavSelect].
class TabNavSelectSkeleton extends StatelessWidget {
  const TabNavSelectSkeleton({
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
