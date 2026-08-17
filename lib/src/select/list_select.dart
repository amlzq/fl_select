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

/// Standard list view.
///
/// Renders flat entries in a single list, or two-level entries as one
/// expandable group per category whose children are laid out by the
/// category's `layout` (defaulting to a list). Levels deeper than the
/// second are not rendered.
class ListSelect extends StatefulWidget {
  final ListSelectDelegate delegate;
  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  const ListSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  @override
  State<ListSelect> createState() => ListSelectState();
}

class ListSelectState extends State<ListSelect> {
  /// Focused category entry
  int _tempSelectedCategoryIndex = 0;

  SelectController? controller;

  bool get _isSearching => widget.searchQuery.isNotEmpty;

  List<SelectEntry> get _displayEntries => _isSearching
      ? filterEntriesForSearch(widget.entries, widget.searchQuery,
          predicate: widget.searchPredicate)
      : widget.entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectController(context);
  }

  @override
  void didUpdateWidget(covariant ListSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSelectController(context);
  }

  @override
  void dispose() {
    controller?.removeListener(_handleSelectControllerTick);
    super.dispose();
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
  }

  ListSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
  }

  SelectionMode? get selectSelectionMode {
    if (SelectionMode.multiple == categorySelectionMode) {
      return SelectionMode.multiple;
    }
    if (widget.entries.firstWhereOrNull(testMultipleElement) != null) {
      return SelectionMode.multiple;
    }
    return SelectionMode.single;
  }

  SelectionMode? get categorySelectionMode => controller?.selectionMode;

  SelectCategoryEntry? get selectedCategory {
    final entry = widget.entries.elementAtOrNull(_tempSelectedCategoryIndex);
    return entry is SelectCategoryEntry ? entry : null;
  }

  void _onTerminalItemTap(SelectChildEntry item) {
    if (item is SelectRangeEntry && item.isCustom) {
      final hasRange = item.min != null || item.max != null;
      if (hasRange) {
        controller?.select(item.id, parentId: item.parentId);
      } else {
        controller?.unselect(item.id, parentId: item.parentId);
      }
      _setStateOrImmediateApply(item);
      return;
    }

    final isCategoryTree = widget.entries.firstOrNull is SelectCategoryEntry;
    if (!isCategoryTree) {
      controller?.toggleFlatEntry(
        item,
        selectionMode: selectSelectionMode ?? SelectionMode.single,
        isCategoryTree: false,
      );
      _setStateOrImmediateApply(item);
      return;
    }

    final categoryEntry =
        widget.entries.singleWhereOrNull((e) => e.id == item.parentId);
    if (categoryEntry is! SelectCategoryEntry) {
      assert(() {
        debugPrint(
          'ListSelect: child entry "${item.id}" has a parentId of '
          '"${item.parentId}" that does not match any category; the tap was '
          'ignored. Check that the child\'s parentId points to its owning '
          'category id (a two-level-or-deeper structure).',
        );
        return true;
      }());
      return;
    }
    final category = categoryEntry;
    controller?.toggleFlatEntry(
      item,
      // Cross-category clearing must follow the delegate-level mode. The
      // mixed [selectSelectionMode] reports multiple as soon as any
      // category opts into multiple, which would disable the clearing.
      selectionMode: categorySelectionMode ?? SelectionMode.single,
      isCategoryTree: true,
      category: category,
    );
    _setStateOrImmediateApply(item);
  }

  void _setStateOrImmediateApply(SelectChildEntry item) {
    if (SelectionMode.single == selectSelectionMode || item.immediate) {
      // No need to tap "Apply"; return result immediately
      _onApplyTap();
    } else {
      // Update UI state
      setState(() {});
      controller?.emitChangeFromState();
    }
  }

  void _onResetTap() {
    controller?.resetState(initializeAnyIfEmpty: true);
    _tempSelectedCategoryIndex = 0;
    setState(() {});
    controller?.reset();
  }

  void _onApplyTap() {
    controller?.applyFromState();
  }

  @override
  Widget build(BuildContext context) {
    final selectionMode = controller?.selectionMode;

    // final listTileTheme = select?.listTileTheme;
    // final gridTileTheme = select?.gridTileTheme;
    final chipBarTheme = delegate.chipBarTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _displayEntries.firstOrNull is SelectCategoryEntry
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_displayEntries.length, (index) {
                      final category =
                          _displayEntries[index] as SelectCategoryEntry;
                      final selectedEntries =
                          controller?.selectedEntriesAtLevel(1) ?? {};
                      final entries = category.children?.toList() ?? [];
                      final layout =
                          category.layout ?? const SelectListLayout();
                      return SelectExpansionTile(
                        title: category.name ?? '',
                        titlePadding: const EdgeInsets.symmetric(vertical: 10),
                        initiallyExpanded: true,
                        child: switch (layout) {
                          SelectListLayout(:final toText) => SelectListView(
                              key: ValueKey('category_$index'),
                              category: category,
                              showTitle: false,
                              entries: entries,
                              selectedEntries: selectedEntries,
                              onChanged: (_, entry) =>
                                  _onTerminalItemTap(entry as SelectChildEntry),
                              toText: toText,
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
                              backgroundColor: chipBarTheme?.backgroundColor,
                              padding: chipBarTheme?.padding,
                              variant: chipBarTheme?.variant,
                              chipColor: chipBarTheme?.chipColor,
                              selectedChipColor:
                                  chipBarTheme?.selectedChipColor,
                              labelStyle: chipBarTheme?.labelStyle,
                              selectedLabelStyle:
                                  chipBarTheme?.selectedLabelStyle,
                              onChanged: (_, item) =>
                                  _onTerminalItemTap(item as SelectChildEntry),
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
                        },
                      );
                    }),
                  ),
                )
              : SelectListView(
                  entries: _displayEntries,
                  selectedEntries: controller?.selectedEntriesAtLevel(0) ?? {},
                  onChanged: (_, entry) =>
                      _onTerminalItemTap(entry as SelectChildEntry),
                  radioBuilder: delegate.radioBuilder,
                  checkboxBuilder: delegate.checkboxBuilder,
                ),
        ),
        if (SelectionMode.multiple == selectionMode &&
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

class ListSelectSkeleton extends StatelessWidget {
  final SelectionMode selectionMode;

  const ListSelectSkeleton({
    super.key,
    this.selectionMode = SelectionMode.single,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Flexible(child: SelectListSkeleton(itemCount: 6)),
        if (SelectionMode.multiple == selectionMode)
          const SelectActionBarSkeleton(),
      ],
    );
  }
}
