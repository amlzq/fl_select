import 'package:flutter/material.dart';

import 'action_bar_visibility.dart';
import 'constants.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_search_filter.dart';
import 'widgets/widgets.dart';

/// Standard list view.
///
/// Renders flat entries in a single list. For two-level (category) data
/// with expandable groups, use [ExpandableSelect] via
/// [ExpandableSelectDelegate].
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

    controller?.toggleFlatEntry(
      item,
      selectionMode: delegate.selectionMode,
      isCategoryTree: false,
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
          child: SelectListView(
            entries: _displayEntries,
            selectedEntries: controller?.selectedEntriesAtLevel(0) ?? {},
            onChanged: (_, entry) =>
                _onTerminalItemTap(entry as SelectChildEntry),
            selectionMode: delegate.selectionMode,
            radioBuilder: delegate.radioBuilder,
            checkboxBuilder: delegate.checkboxBuilder,
            itemBuilder: delegate.itemBuilder,
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
