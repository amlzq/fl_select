import 'package:flutter/material.dart';

import 'action_bar_visibility.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_search_filter.dart';
import 'widgets/widgets.dart';

/// Flat layout: the top-level (parentless) entries render directly as a
/// wrapable chip bar.
///
/// Only flat (single-level) structured data is supported; use
/// [SideNavSelectDelegate] for two-level (category) data.
///
/// Behavior notes:
/// - At most one level is rendered; use [SideNavSelect] for two-level data
///   and [CascadingSelect] for multi-level (cascading) data.
/// - If the data contains a custom range entry ([SelectRangeEntry.custom]),
///   two numeric fields are shown for min/max input.
/// - When an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
/// - In multi-selection mode, the action bar is shown and "Apply" produces
///   the final clipped selection tree.
class WrapSelect extends StatefulWidget {
  final WrapSelectDelegate delegate;
  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  const WrapSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  @override
  State<WrapSelect> createState() => WrapSelectState();
}

class WrapSelectState extends State<WrapSelect> {
  SelectController? controller;

  bool get _isSearching => widget.searchQuery.isNotEmpty;

  List<SelectEntry> get _displayEntries => _isSearching
      ? filterEntriesForSearch(widget.entries, widget.searchQuery,
          predicate: widget.searchPredicate)
      : widget.entries;

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
  void didUpdateWidget(covariant WrapSelect oldWidget) {
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
  }

  WrapSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
  }

  void _onTerminalItemTap(SelectChildEntry entry) {
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
        isCategoryTree: false,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SelectChipBar(
              entries: _displayEntries,
              selectedEntries: controller?.selectedEntriesAtLevel(0) ?? {},
              isWrapable: true,
              spacing: delegate.spacing,
              runSpacing: delegate.runSpacing,
              backgroundColor: delegate.chipBarTheme?.backgroundColor,
              padding: delegate.chipBarTheme?.padding,
              variant: delegate.chipBarTheme?.variant,
              chipColor: delegate.chipBarTheme?.chipColor,
              selectedChipColor: delegate.chipBarTheme?.selectedChipColor,
              labelStyle: delegate.chipBarTheme?.labelStyle,
              selectedLabelStyle: delegate.chipBarTheme?.selectedLabelStyle,
              itemBuilder: delegate.itemBuilder,
              onChanged: (_, entry) =>
                  _onTerminalItemTap(entry as SelectChildEntry),
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

/// Loading skeleton for [WrapSelect].
class WrapSelectSkeleton extends StatelessWidget {
  const WrapSelectSkeleton({
    super.key,
    this.itemCount = 16,
    this.padding,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
  });

  final int itemCount;
  final EdgeInsets? padding;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SelectChipBarSkeleton(
              itemCount: itemCount,
              padding: padding,
              spacing: spacing,
              runSpacing: runSpacing,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SelectActionBarSkeleton(),
      ],
    );
  }
}
