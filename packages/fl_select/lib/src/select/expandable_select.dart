import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'action_bar_visibility.dart';
import 'constants.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_layout.dart';
import 'select_search_filter.dart';
import 'widgets/select_category_content.dart';
import 'widgets/widgets.dart';

/// Expandable grouped layout for two-level (category) data: each category
/// renders as an expandable tile whose children are laid out by the
/// category's `layout` (defaulting to the delegate's [defaultLayout], then
/// to a list layout).
///
/// Flat (parentless) structures are not supported; use [ListSelect] via
/// [ListSelectDelegate] for flat data.
///
/// Behavior notes:
/// - At most two levels are rendered; use [CascadingSelect] for multi-level
///   (cascading) data.
/// - When an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
/// - In multi-selection mode, the action bar is shown and "Apply" produces
///   the final clipped selection tree.
class ExpandableSelect extends StatefulWidget {
  final ExpandableSelectDelegate delegate;
  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  const ExpandableSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  @override
  State<ExpandableSelect> createState() => _ExpandableSelectState();
}

class _ExpandableSelectState extends State<ExpandableSelect> {
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
  void didUpdateWidget(covariant ExpandableSelect oldWidget) {
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

  ExpandableSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
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

    final categoryEntry =
        widget.entries.singleWhereOrNull((e) => e.id == item.parentId);
    if (categoryEntry is! SelectCategoryEntry) {
      assert(() {
        debugPrint(
          'ExpandableSelect: child entry "${item.id}" has a parentId of '
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
      selectionMode: delegate.selectionMode,
      isCategoryTree: true,
      category: category,
    );
    _setStateOrImmediateApply(item);
  }

  void _setStateOrImmediateApply(SelectChildEntry item) {
    if (controller?.hasMultipleMode != true || item.immediate) {
      // No need to tap "Apply"; return result immediately
      _onApplyTap();
    } else {
      // Update UI state
      setState(() {});
      controller?.emitChangeFromState();
    }
  }

  SelectEntries _headerSelectedFor(String categoryId) =>
      controller?.selectedHeaderEntriesFor(categoryId) ?? <SelectEntry>{};

  SelectEntries _footerSelectedFor(String categoryId) =>
      controller?.selectedFooterEntriesFor(categoryId) ?? <SelectEntry>{};

  void _onHeaderOrFooterItemTap(
    SelectCategoryEntry category,
    bool isHeader,
    int chipIndex,
    SelectChildEntry entry,
  ) {
    // Every category is visible at once here, so the tapped header/footer
    // entry is resolved against its owning category.
    final delegateMode = controller?.selectionMode ?? SelectionMode.single;
    final selectionMode = isHeader
        ? category.effectiveHeaderSelectionMode(delegateMode)
        : category.effectiveFooterSelectionMode(delegateMode);
    controller?.toggleHeaderOrFooterEntry(
      categoryId: category.id,
      entry: entry,
      selectionMode: selectionMode,
      isHeader: isHeader,
    );

    _setStateOrImmediateApply(entry);
  }

  void _onResetTap() {
    controller?.resetState(initializeAnyIfEmpty: true);
    setState(() {});
    controller?.reset();
  }

  void _onApplyTap() {
    controller?.applyFromState();
  }

  @override
  Widget build(BuildContext context) {
    final selectionMode = controller?.selectionMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            // Touch drags (and flings) the body cannot consume at its edges
            // chain to the nearest same-direction ancestor scrollable,
            // mimicking native nested scrolling. Pointer-wheel chaining is
            // handled by the framework itself.
            physics: const ChainingClampingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_displayEntries.length, (index) {
                final category = _displayEntries[index] as SelectCategoryEntry;
                final content = SelectCategoryContentView(
                  category: category,
                  index: index,
                  selectedEntries: controller?.selectedEntriesAtLevel(1) ?? {},
                  fallbackLayout:
                      delegate.defaultLayout ?? const SelectListLayout(),
                  delegate: delegate,
                  onTerminalItemTap: _onTerminalItemTap,
                );

                final categoryHeader = category.header;
                final categoryFooter = category.footer;
                final hasHeader =
                    categoryHeader != null && categoryHeader.children != null;
                final hasFooter =
                    categoryFooter != null && categoryFooter.children != null;

                return SelectExpansionTile(
                  title: category.name ?? '',
                  titlePadding: const EdgeInsets.symmetric(vertical: 10),
                  initiallyExpanded: true,
                  child: hasHeader || hasFooter
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasHeader)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SelectChipBar(
                                  category: categoryHeader,
                                  entries: categoryHeader.children!.toList(),
                                  selectedEntries:
                                      _headerSelectedFor(category.id),
                                  variant: SelectChipVariant.filled,
                                  isWrapable: true,
                                  spacing: 12.0,
                                  runSpacing: 12.0,
                                  onChanged: (index, entry) =>
                                      _onHeaderOrFooterItemTap.call(
                                          category,
                                          true,
                                          index,
                                          entry as SelectChildEntry),
                                ),
                              ),
                            content,
                            if (hasFooter)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SelectChipBar(
                                  category: categoryFooter,
                                  entries: categoryFooter.children!.toList(),
                                  selectedEntries:
                                      _footerSelectedFor(category.id),
                                  variant: SelectChipVariant.filled,
                                  isWrapable: true,
                                  spacing: 12.0,
                                  runSpacing: 12.0,
                                  onChanged: (index, entry) =>
                                      _onHeaderOrFooterItemTap.call(
                                          category,
                                          false,
                                          index,
                                          entry as SelectChildEntry),
                                ),
                              ),
                          ],
                        )
                      : content,
                );
              }),
            ),
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

class ExpandableSelectSkeleton extends StatelessWidget {
  final SelectionMode selectionMode;

  const ExpandableSelectSkeleton({
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
