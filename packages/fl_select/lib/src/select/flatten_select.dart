// Deprecated compatibility host; see FlattenSelectDelegate.
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_search_filter.dart';
import 'side_nav_select.dart';
import 'wrap_select.dart';

/// Deprecated compatibility host for the former "flatten" select.
///
/// - Flat (parentless) entries are rendered by [WrapSelect].
/// - Two-level (category) data is rendered by [SideNavSelect].
///
/// See [FlattenSelectDelegate] for the deprecation notes.
@Deprecated(
  'Use SideNavSelectDelegate for two-level data or WrapSelectDelegate for '
  'flat data. Will be removed in a future minor version.',
)
class FlattenSelect extends StatefulWidget {
  final FlattenSelectDelegate delegate;
  final List<SelectEntry> entries;
  final Set<SelectEntry>? selectedEntries;
  final String searchQuery;
  final SelectSearchPredicate? searchPredicate;

  const FlattenSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  @override
  State<FlattenSelect> createState() => _FlattenSelectState();
}

// ignore: deprecated_member_use_from_same_package
class _FlattenSelectState extends State<FlattenSelect> {
  static bool _warned = false;

  void _warn(String replacement) {
    if (_warned) {
      return;
    }
    _warned = true;
    debugPrint(
      'FlattenSelectDelegate is deprecated; use $replacement instead. '
      'It will be removed in a future minor version.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCategoryTree = widget.entries.firstOrNull is SelectCategoryEntry;
    if (isCategoryTree) {
      _warn('SideNavSelectDelegate');
      return SideNavSelect(
        delegate: widget.delegate.toSideNav(),
        entries: widget.entries,
        selectedEntries: widget.selectedEntries,
        searchQuery: widget.searchQuery,
        searchPredicate: widget.searchPredicate,
      );
    }
    _warn('WrapSelectDelegate');
    return WrapSelect(
      delegate: widget.delegate.toWrap(),
      entries: widget.entries,
      selectedEntries: widget.selectedEntries,
      searchQuery: widget.searchQuery,
      searchPredicate: widget.searchPredicate,
    );
  }
}
