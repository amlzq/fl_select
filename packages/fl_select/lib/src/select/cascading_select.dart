import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../i18n/select_localizations.dart';
import 'action_bar_visibility.dart';
import 'constants.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_search_filter.dart';
import 'select_theme.dart';
import 'select_utils.dart';
import 'widgets/widgets.dart';

/// Horizontal layout: category list on the left and cascading item lists on
/// the right.
///
/// Requires a category structure: the top level must be [SelectCategoryEntry]
/// roots. Renders one column per level, supporting arbitrary depth
/// (category -> child -> grandchild -> ...); a column's entries may be plain
/// leaves or branch entries carrying `children`.
///
/// The focused category decides the selection mode of its children (falling
/// back to the delegate's), and its `layout` is ignored.
///
/// Behavior notes:
/// - Maintains a focused item per level to drive the cascade columns.
/// - Selection state is stored per level; in multi-selection mode an action bar
///   may be used to apply the final selection.
/// - If an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
class CascadingSelect extends StatefulWidget {
  const CascadingSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  final CascadingSelectDelegate delegate;

  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  @override
  State<CascadingSelect> createState() => CascadingSelectState();
}

class CascadingSelectState extends State<CascadingSelect> {
  /// The category currently focused in the sidebar.
  ///
  /// It drives the sidebar highlight, the header/footer chips and the child
  /// selection mode. The cascading columns are owned by the inner
  /// [CascadingView], which receives this category as the root of its focused
  /// path.
  SelectCategoryEntry? _focusedCategory;

  /// Token bumped whenever the cascading columns must be rebuilt from scratch
  /// (category switch, reset, search change).
  ///
  /// It is part of the [CascadingView] key, so a new value hands the view a
  /// clean state instead of trying to patch the previously focused path.
  int _cascadeRebuildToken = 0;

  /// Whether the cascading columns should re-expand the deepest selected path
  /// below the focused category when they are rebuilt.
  ///
  /// A category switch collapses the cascade to the new category's children,
  /// which is the behaviour the cascade had before [CascadingView] was
  /// extracted.
  bool _restoreCascadePath = true;

  SelectController? controller;

  /// The ends of the background ramp, shared by the category sidebar (level 0)
  /// and the cascading columns.
  late Color _startBackgroundColor;
  late Color _endBackgroundColor;

  /// The background ramp the sidebar samples: index 0 is the category level and
  /// index 1 the first children column.
  late List<Color> _backgroundColors;

  bool get _isSearching => widget.searchQuery.isNotEmpty;

  List<SelectEntry> get _displayEntries => _isSearching
      ? filterEntriesForSearch(
          widget.entries,
          widget.searchQuery,
          predicate: widget.searchPredicate,
        )
      : widget.entries;

  /// Entries used to drive the cascading state: filtered when searching,
  /// otherwise the full [widget.entries].
  List<SelectEntry> get _effectiveEntries =>
      _isSearching ? _displayEntries : widget.entries;

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(covariant CascadingSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild the selection state when the data actually changes.
    // In playground's SelectView mode, the ancestor EntryPointScreen calls
    // setState on every onChanged, which causes didUpdateWidget to fire on
    // every tap — even though entries and selectedEntries are unchanged.
    // Unconditionally calling _updateSelectController (which calls
    // _rebuildSelectionState) bumps the cascading rebuild token, so the inner
    // CascadingView discards its in-memory focused path and rebuilds it from
    // the state tree.
    // While that rebuild is usually correct, it is unnecessary work and can
    // cause the UI to jump to a different category under certain timing
    // conditions. Guarding the call avoids the extra rebuild.
    final sameEntries = const ListEquality<SelectEntry>().equals(
      widget.entries,
      oldWidget.entries,
    );
    final samePrevious = const SetEquality<SelectEntry>().equals(
      widget.selectedEntries ?? const {},
      oldWidget.selectedEntries ?? const {},
    );
    final sameSearchQuery = widget.searchQuery == oldWidget.searchQuery;
    if (!sameEntries || !samePrevious) {
      _updateSelectController(context);
    } else if (!sameSearchQuery) {
      // Search query changed without data change — rebuild cascading state
      // from filtered entries and refresh the UI.
      _rebuildSelectionState();
      setState(() {});
    }
  }

  void _updateSelectController(BuildContext context) {
    if (controller == null) {
      controller = SelectController.of(context)!;
      controller?.addListener(_handleSelectControllerTick);
    }
    // Gradient colors depend on the ambient theme, so they must be recomputed
    // whenever the theme changes (e.g. light/dark switch), not only on first init.
    final theme = SelectTheme.of(context);
    // The sidebar is flush against the first column, so the sidebar paints the
    // level-0 surface the cascade starts from: both sides read one resolved
    // color, which is why it is handed to the view as its ramp start.
    _startBackgroundColor = SelectSideBarTheme.resolveBackgroundColor(
      context,
      // ignore: deprecated_member_use_from_same_package
      fallback: delegate.categoryBackgroundColor,
    );
    _endBackgroundColor =
        theme.cascadingViewTheme.endBackgroundColor ??
        // ignore: deprecated_member_use_from_same_package
        delegate.terminalBackgroundColor ??
        theme.backgroundColorHighest;
    // The cascading UI always renders at least two levels (the category
    // sidebar plus one children column), so the ramp must span at least
    // two steps even for depth-1 trees (categories without children).
    final maxDepth = max(2, SelectUtils.maxDepth(widget.entries.toSet(), 1));
    // The sidebar shares the category level (0) with the columns, so it ramps
    // over the same ends and both stay in sync.
    _backgroundColors = SelectUtils.gradientColors(
      maxDepth,
      _startBackgroundColor,
      _endBackgroundColor,
    );

    controller?.bindState(
      widget.entries,
      initializeAnyIfEmpty: true,
      selectedEntriesOverride: widget.selectedEntries,
    );
    _rebuildSelectionState();
  }

  void _handleSelectControllerTick() {
    if (!mounted) return;
    setState(() {});
  }

  CascadingSelectDelegate get delegate => widget.delegate;

  void _rebuildSelectionState() {
    // Capture the currently focused category before switching, so a search
    // rebuild can keep focusing it when it still matches the filter.
    final previousFocusedCategoryId = _focusedCategory?.id;

    SelectCategoryEntry? focused;
    var restorePath = true;
    if (_isSearching) {
      // When searching, resolve the focused category from the filtered tree.
      // Keep the previously focused category when it still matches, otherwise
      // fall back to the first matching category.
      final entries = _effectiveEntries;
      if (previousFocusedCategoryId != null) {
        focused = entries.whereType<SelectCategoryEntry>().firstWhereOrNull(
          (c) => c.id == previousFocusedCategoryId,
        );
      }
      focused ??= entries.whereType<SelectCategoryEntry>().firstOrNull;
      // While searching, the view expands along the first branch that still
      // has children instead of restoring the selected path.
      restorePath = false;
    } else {
      // Resume on the category that owns the deepest selection, falling back
      // to the first category when nothing is selected yet.
      focused =
          _pickFocusedCategoryFromSelection() ??
          widget.entries.whereType<SelectCategoryEntry>().firstOrNull;
    }

    if (focused == null) {
      _focusedCategory = null;
      return;
    }
    _applyFocusedCategory(focused, restorePath: restorePath);
  }

  /// Switches the focused category and requests a clean rebuild of the
  /// cascading columns.
  void _applyFocusedCategory(
    SelectCategoryEntry category, {
    required bool restorePath,
  }) {
    _focusedCategory = category;
    _restoreCascadePath = restorePath;
    _cascadeRebuildToken++;
  }

  /// Picks the focused category from the selection state.
  SelectCategoryEntry? _pickFocusedCategoryFromSelection() =>
      SelectUtils.pickFocusedEntry(
            (level) => controller?.selectedEntriesAtLevel(level) ?? {},
            null,
            0,
          )
          as SelectCategoryEntry?;

  SelectEntries _headerSelectedFor(String categoryId) =>
      controller?.selectedHeaderEntriesFor(categoryId) ?? <SelectEntry>{};

  SelectEntries _footerSelectedFor(String categoryId) =>
      controller?.selectedFooterEntriesFor(categoryId) ?? <SelectEntry>{};

  /// The focused category: the root of the cascading columns.
  SelectCategoryEntry get focusedCategory => _focusedCategory!;

  /// Selection Mode for the focused category's sub-items
  SelectionMode get childrenSelectionMode =>
      focusedCategory.effectiveSelectionMode(delegate.selectionMode);

  /// Tap handler for a category item
  void _onCategoryItemTap(SelectCategoryEntry newCategoryEntry) {
    // Switching categories collapses the cascade back to the new category's
    // children: the previous focused path is intentionally not restored, and
    // any previous selection outside this category is kept.
    _applyFocusedCategory(newCategoryEntry, restorePath: false);
    controller?.focusCategoryEntry(
      newCategoryEntry,
      selectionMode: controller?.selectionMode ?? SelectionMode.single,
    );
    setState(() {});
  }

  void _onHeaderOrFooterItemTap(
    bool isHeader,
    int chipIndex,
    SelectChildEntry entry,
  ) {
    final selectionMode = isHeader
        ? focusedCategory.effectiveHeaderSelectionMode(delegate.selectionMode)
        : focusedCategory.effectiveFooterSelectionMode(delegate.selectionMode);
    controller?.toggleHeaderOrFooterEntry(
      categoryId: focusedCategory.id,
      entry: entry,
      selectionMode: selectionMode,
      isHeader: isHeader,
    );

    _setStateOrImmediateApply(entry);
  }

  void _onApplyTap() {
    controller?.applyFromState();
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
    final previousFocusedCategoryId = focusedCategory.id;
    controller?.resetState(initializeAnyIfEmpty: false);
    _rebuildSelectionState();
    final newCategory =
        _effectiveEntries.firstWhereOrNull(
              (e) => e.id == previousFocusedCategoryId,
            )
            as SelectCategoryEntry?;
    if (newCategory != null) {
      _onCategoryItemTap(newCategory);
    }
    setState(() {});
    controller?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SelectTheme.of(context);
    final isScrollable = delegate.isScrollable == true;

    // Empty-state guard: when searching yields no results, show a placeholder.
    if (_isSearching && _effectiveEntries.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Center(
              child: Text(
                SelectLocalizations.of(context)?.noResults ?? 'No results',
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
                  onResetTap: _onResetTap,
                  onApplyTap: _onApplyTap,
                ),
        ],
      );
    }

    /// Maximum level for the current category
    // final maxLevel = focusedCategory.maxLevel;
    // final isMultipleSelectionMode =
    //     SelectionMode.multiple == focusedCategory.selectionMode;

    // Neither header nor footer children support a custom range entry: both
    // rows render as chips and SelectChipBar throws on a custom entry.
    final categoryHeader = focusedCategory.header;
    final categoryFooter = focusedCategory.footer;
    final headerSelected = _headerSelectedFor(focusedCategory.id);
    final footerSelected = _footerSelectedFor(focusedCategory.id);

    // The sidebar paints the level-0 surface of the ramp it shares with the
    // columns, so it takes the ramp's start.
    final categoryBackgroundColor = _startBackgroundColor;
    // Get selected item color (background color of next level); the ramp always
    // spans at least the category level plus one column.
    final selectedTileColor = _backgroundColors[1];

    final effectiveSelectedColor = theme.selectedColor;

    final focusedCategoryIndex = _effectiveEntries.indexOf(focusedCategory);

    // A category badge should only appear when it has a "real" selection,
    // i.e. at least one selected child that is not the "Any" placeholder.
    // Selecting only "Any" must not trigger the badge.
    final selectedCategories =
        controller?.realSelectedCategories ?? <SelectEntry>{};

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category list (left)
              SelectSideBar(
                isScrollable: true,
                backgroundColor: categoryBackgroundColor,
                selectedColor: effectiveSelectedColor,
                selectedTileColor: selectedTileColor,
                entries: _effectiveEntries,
                selectedCategories: selectedCategories,
                focusedIndex: focusedCategoryIndex,
                onChanged: (_, entry) =>
                    _onCategoryItemTap(entry as SelectCategoryEntry),
              ),
              // Children lists (right)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryHeader != null &&
                        categoryHeader.children != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SelectChipBar(
                          category: categoryHeader,
                          entries: categoryHeader.children!.toList(),
                          selectedEntries: headerSelected,
                          spacing: 12.0,
                          onChanged: (index, entry) => _onHeaderOrFooterItemTap
                              .call(true, index, entry as SelectChildEntry),
                        ),
                      ),
                    Expanded(
                      child: CascadingView(
                        key: ValueKey(
                          'cascade_${focusedCategory.id}_$_cascadeRebuildToken',
                        ),
                        entries: focusedCategory.children?.toList() ?? [],
                        category: focusedCategory,
                        showTitle: false,
                        selectionMode: childrenSelectionMode,
                        isScrollable: isScrollable,
                        restoreSelectionPath: _restoreCascadePath,
                        autoExpandFirstBranch: _isSearching,
                        startBackgroundColor: _startBackgroundColor,
                        endBackgroundColor: _endBackgroundColor,
                        radioBuilder: delegate.radioBuilder,
                        checkboxBuilder: delegate.checkboxBuilder,
                      ),
                    ),
                    if (categoryFooter != null &&
                        categoryFooter.children != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SelectChipBar(
                          category: categoryFooter,
                          entries: categoryFooter.children!.toList(),
                          selectedEntries: footerSelected,
                          spacing: 12.0,
                          onChanged: (index, entry) => _onHeaderOrFooterItemTap
                              .call(false, index, entry as SelectChildEntry),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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
                onResetTap: _onResetTap,
                onApplyTap: _onApplyTap,
              ),
      ],
    );
  }
}

class CascadingSelectSkeleton extends StatelessWidget {
  const CascadingSelectSkeleton({
    super.key,
    this.backgroundColor,
    this.sideBarWidth,
  });

  final Color? backgroundColor;
  final double? sideBarWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? SelectTheme.of(context).backgroundColor;
    final effectiveSideBarWidth = sideBarWidth ?? kSelectSideBarWidth;
    final random = Random();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: effectiveSideBarWidth,
                color: effectiveBackgroundColor,
                child: SkeletonView(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return SkeletonTile(
                        height: kSelectListTileHeight,
                        borderRadius: BorderRadius.circular(4),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 6);
                    },
                  ),
                ),
              ),
              Flexible(
                child: ColoredBox(
                  color: effectiveBackgroundColor,
                  child: SkeletonView(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return SkeletonTile(
                          random: random,
                          widthUsed: effectiveSideBarWidth + 30,
                          height: kSelectListTileHeight,
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 6);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SelectActionBarSkeleton(),
      ],
    );
  }
}
