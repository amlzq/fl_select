import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'action_bar_visibility.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_layout.dart';
import 'select_search_filter.dart';
import 'select_theme.dart';
import 'widgets/widgets.dart';

/// Horizontal layout: category navigation on the left and a flattened item list on the right.
/// Tapping the left side drives scrolling on the right; scrolling the right side highlights the left side.
/// Supports both flat (parentless entries) and two-level
/// (category -> children) structured data.
///
/// Behavior notes:
/// - In a flat structure, the top-level entries are rendered directly as a
///   wrapable [SelectChipBar] and no category sidebar is shown.
/// - In a two-level structure, the sidebar drives which category's children
///   are shown; each category's children are laid out by the category's
///   `layout` (defaulting to a wrapable [SelectChipBar]).
/// - At most two levels are rendered; levels nested deeper than the second
///   are not rendered.
/// - A category's `header`/`footer` entries (if any) are rendered as chip
///   bars above/below that category's content, mirroring [CascadingSelect].
/// - Each category's name is rendered as a single title above its content by
///   the view itself; the inner layout views are created with
///   `showTitle: false` so titles never duplicate.
/// - Child selection mode is determined per category by [SelectCategoryEntry.selectionMode].
/// - The right-side content is scroll-synced with the left category list.
/// - Custom range entries ([SelectRangeEntry.custom]) are rendered as an input
///   row; typing clears existing child selections for that category.
/// - When an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
/// - In multi-selection mode, the action bar is shown and "Apply" produces the
///   final clipped selection tree.
class FlattenSelect extends StatefulWidget {
  const FlattenSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  final FlattenSelectDelegate delegate;

  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  @override
  State<FlattenSelect> createState() => FlattenSelectState();
}

class FlattenSelectState extends State<FlattenSelect> {
  /// Focused category entry
  int _tempSelectedCategoryIndex = 0;

  var _isScrollingProgrammatically = false;

  final GlobalKey _scrollViewKey = GlobalKey();

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
  void didUpdateWidget(covariant FlattenSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSelectController(context);
    // Clamp the selected category index when search results reduce the number
    // of categories.
    if (_tempSelectedCategoryIndex >= _displayEntries.length) {
      _tempSelectedCategoryIndex =
          _displayEntries.isEmpty ? 0 : _displayEntries.length - 1;
    }
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

  FlattenSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
  }

  /// Whether the entries form a two-level (category -> children) tree.
  bool get _isCategoryTree => widget.entries.firstOrNull is SelectCategoryEntry;

  SelectCategoryEntry? get selectedCategory {
    final entry = _displayEntries.elementAtOrNull(_tempSelectedCategoryIndex);
    return entry is SelectCategoryEntry ? entry : null;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // If this scroll was triggered programmatically, ignore it
    if (_isScrollingProgrammatically) return false;

    // Only handle scroll update notifications
    // Only handle scroll update notifications
    if (notification is! ScrollUpdateNotification) return false;

    _observeVisibleItems();

    return false;
  }

  void _observeVisibleItems() {
    // 1. Get the RenderBox of the ListView
    final RenderBox? scrollBox =
        _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (scrollBox == null || !scrollBox.attached) return;

    // 2. Get the viewport's absolute position on screen (for coordinate conversion)
    final scrollOffset = scrollBox.localToGlobal(Offset.zero);

    int? firstVisibleIndex;
    // double minTopGap = double.infinity;

    // 3. Traverse children (based on the core idea of scrollview_observer)
    // Each child is given a ValueKey('category_$index') so we can find it.
    for (int i = 0; i < _displayEntries.length; i++) {
      // Key point: find the child's RenderObject directly from the current context.
      // This has overhead for huge lists, but is efficient and robust for a category select (limited size).
      final childKey = ValueKey('category_$i');

      // Note: due to ListView caching, off-screen children may not be found via context.
      // This matches our requirement: we only need visible items.
      final childElement = _findChildElement(scrollBox, childKey);
      if (childElement == null) continue;

      final RenderBox? childRenderBox = childElement.renderObject as RenderBox?;
      if (childRenderBox == null || !childRenderBox.attached) continue;

      // 4. Compute the child's distance relative to the viewport top
      final childOffset = childRenderBox.localToGlobal(Offset.zero);
      final relativeTop = childOffset.dy - scrollOffset.dy;

      // Idea: find the first item that is closest to the viewport top and not fully out of bounds.
      // Threshold: the item's top is within 5px above the viewport top, or inside the viewport.
      if (relativeTop <= 5 && relativeTop > -childRenderBox.size.height + 5) {
        firstVisibleIndex = i;
        break;
      }
    }

    if (firstVisibleIndex != null &&
        firstVisibleIndex != _tempSelectedCategoryIndex) {
      setState(() {
        _tempSelectedCategoryIndex = firstVisibleIndex!;
      });
    }
  }

  /// Helper: find an Element with a specific Key in the RenderObject tree
  /// Note: visitChildElements has a performance cost
  Element? _findChildElement(RenderObject parent, Key key) {
    Element? target;
    _scrollViewKey.currentContext?.visitChildElements((element) {
      // This visit traverses direct children of the ListView (i.e., SelectGridView)
      void visitor(Element e) {
        if (e.widget.key == key) {
          target = e;
          return;
        }
        e.visitChildElements(visitor);
      }

      visitor(element);
    });
    return target;
  }

  void _onCategoryItemTap(int index) {
    if (_tempSelectedCategoryIndex == index) return;

    final category = _displayEntries[index] as SelectCategoryEntry;
    controller?.focusCategoryEntry(
      category,
      selectionMode: delegate.selectionMode,
    );

    setState(() {
      _tempSelectedCategoryIndex = index;
    });

    final childKey = ValueKey('category_$index');
    final targetElement = _findChildElement(
        _scrollViewKey.currentContext!.findRenderObject()!, childKey);

    if (targetElement == null) return;

    _isScrollingProgrammatically = true;

    // Scroll safely
    Scrollable.ensureVisible(
      targetElement,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.0,
    ).then((_) {
      // After scrolling ends, reset the flag with a short delay
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _isScrollingProgrammatically = false;
        }
      });
    }).catchError((error) {
      // Handle any errors during scrolling
      if (mounted) {
        _isScrollingProgrammatically = false;
      }
    });
  }

  void _onTerminalItemTap(SelectChildEntry item) {
    // Flat structure: no category owner, toggle the entry directly at the
    // top level.
    if (!_isCategoryTree) {
      if (item is SelectRangeEntry && item.isCustom) {
        final hasRange = item.min != null || item.max != null;
        if (hasRange) {
          controller?.select(item.id, parentId: item.parentId);
        } else {
          controller?.unselect(item.id, parentId: item.parentId);
        }
      } else {
        controller?.toggleFlatEntry(
          item,
          selectionMode: delegate.selectionMode,
          isCategoryTree: false,
        );
      }
      _setStateOrImmediateApply(item);
      return;
    }

    final categoryEntry =
        widget.entries.singleWhereOrNull((e) => e.id == item.parentId);
    if (categoryEntry is! SelectCategoryEntry) {
      assert(() {
        debugPrint(
          'FlattenSelect: child entry "${item.id}" has a parentId of '
          '"${item.parentId}" that does not match any category; the tap was '
          'ignored. Check that the child\'s parentId points to its owning '
          'category id (a two-level-or-deeper structure).',
        );
        return true;
      }());
      return;
    }
    final category = categoryEntry;

    if (item is SelectRangeEntry && item.isCustom) {
      final hasRange = item.min != null || item.max != null;
      if (hasRange) {
        controller?.select(item.id, parentId: item.parentId);
      } else {
        controller?.unselect(item.id, parentId: item.parentId);
      }
    } else {
      controller?.toggleFlatEntry(
        item,
        selectionMode: delegate.selectionMode,
        isCategoryTree: true,
        category: category,
      );
    }

    _setStateOrImmediateApply(item);
  }

  void _setStateOrImmediateApply(SelectChildEntry item) {
    if (controller?.hasMultipleMode != true || item.immediate) {
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

  /// Renders the category name above each category's content.
  ///
  /// The inner layout views are created with `showTitle: false` so the title
  /// is rendered exactly once by this method, with a single consistent style
  /// regardless of the category's layout.
  Widget? _buildCategoryTitle(SelectCategoryEntry category) {
    final name = category.name;
    if (name == null) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DefaultTextStyle.merge(
        style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600) ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
        child: Text(name),
      ),
    );
  }

  void _onHeaderOrFooterItemTap(
    SelectCategoryEntry category,
    bool isHeader,
    int chipIndex,
    SelectChildEntry entry,
  ) {
    // Unlike [GridSelect], every category is visible at once here, so the
    // tapped header/footer entry is resolved against its owning category
    // instead of the focused one.
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
    controller?.resetState(initializeAnyIfEmpty: true);
    _tempSelectedCategoryIndex = 0;
    setState(() {});
    controller?.reset();
  }

  void _onApplyTap() {
    controller?.applyFromState();
  }

  /// Builds the right-side content for a single category by exhaustively
  /// consuming [SelectCategoryEntry.layout].
  /// When a category has no layout, it falls back to a wrapable [SelectChipBar].
  Widget _buildCategoryView(
    SelectCategoryEntry category, {
    required int index,
    required bool isLast,
  }) {
    final entries = category.children?.toList() ?? [];
    final selectedEntries =
        controller?.selectedEntriesForParent(category.id, level: 1) ?? {};
    final layout = category.layout ?? const SelectChipLayout();

    final view = switch (layout) {
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
          direction: Axis.vertical,
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

    final categoryTitle = _buildCategoryTitle(category);
    final categoryHeader = category.header;
    final categoryFooter = category.footer;
    final hasHeader = categoryHeader != null && categoryHeader.children != null;
    final hasFooter = categoryFooter != null && categoryFooter.children != null;

    // The outer ListView handles vertical scrolling; the inner view must not
    // add another vertical scrollable in the same axis. Every branch above
    // either is non-scrollable (chip/range/counter) or self-sizes its internal
    // scroll view (list/grid), so nesting is safe.
    return Padding(
      padding: EdgeInsets.only(top: 18, bottom: isLast ? 18 : 0),
      child: (categoryTitle != null || hasHeader || hasFooter)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (categoryTitle != null) categoryTitle,
                if (hasHeader)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SelectChipBar(
                      category: categoryHeader,
                      entries: categoryHeader.children!.toList(),
                      selectedEntries: _headerSelectedFor(category.id),
                      variant: SelectChipVariant.filled,
                      isWrapable: false,
                      onChanged: (index, entry) =>
                          _onHeaderOrFooterItemTap.call(
                              category, true, index, entry as SelectChildEntry),
                    ),
                  ),
                view,
                if (hasFooter)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SelectChipBar(
                      category: categoryFooter,
                      entries: categoryFooter.children!.toList(),
                      selectedEntries: _footerSelectedFor(category.id),
                      variant: SelectChipVariant.filled,
                      isWrapable: false,
                      onChanged: (index, entry) =>
                          _onHeaderOrFooterItemTap.call(category, false, index,
                              entry as SelectChildEntry),
                    ),
                  ),
              ],
            )
          : view,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = SelectTheme.of(context);

    final actionBar = controller?.hasMultipleMode == true &&
            !SelectActionBarVisibility.isHidden(context)
        ? (delegate.actionBarBuilder?.call(
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
            ))
        : null;

    // Flat structure: no category sidebar, render the top-level entries
    // directly as a wrapable chip bar.
    if (!_isCategoryTree) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              child: SelectChipBar(
                entries: _displayEntries,
                selectedEntries: controller?.selectedEntriesAtLevel(0) ?? {},
                isWrapable: true,
                backgroundColor: delegate.chipBarTheme?.backgroundColor,
                padding: delegate.chipBarTheme?.padding,
                variant: delegate.chipBarTheme?.variant,
                chipColor: delegate.chipBarTheme?.chipColor,
                selectedChipColor: delegate.chipBarTheme?.selectedChipColor,
                labelStyle: delegate.chipBarTheme?.labelStyle,
                selectedLabelStyle: delegate.chipBarTheme?.selectedLabelStyle,
                onChanged: (_, item) =>
                    _onTerminalItemTap(item as SelectChildEntry),
              ),
            ),
          ),
          if (actionBar != null) actionBar,
        ],
      );
    }

    // A category badge should only appear when it has a "real" selection,
    // i.e. at least one selected child that is not the "Any" placeholder.
    // Selecting only "Any" must not trigger the badge.
    final rawSelectedCategories = controller?.selectedEntriesAtLevel(0) ?? {};
    final selectedCategories = rawSelectedCategories.where((entry) {
      if (entry is! SelectCategoryEntry) return false;
      final children =
          controller?.selectedEntriesForParent(entry.id, level: 1) ?? {};
      return children.any((e) => e is SelectChildEntry && !e.isAny);
    }).toSet();

    final categoryBackgroundColor = theme.backgroundColor;
    final terminalBackgroundColor = theme.backgroundColorHigh;

    final effectiveSelectedColor =
        delegate.selectedColor ?? theme.selectedColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left category list
              SelectSideBar(
                isScrollable: true,
                width: delegate.sideBarTheme?.width,
                backgroundColor: categoryBackgroundColor,
                selectedColor: effectiveSelectedColor,
                selectedTileColor: terminalBackgroundColor,
                entries: _displayEntries,
                selectedCategories: selectedCategories,
                focusedIndex: _tempSelectedCategoryIndex,
                onChanged: (index, entry) => _onCategoryItemTap(index),
              ),
              // Right content area with NotificationListener
              Expanded(
                child: ColoredBox(
                  color: terminalBackgroundColor,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: ListView(
                      key:
                          _scrollViewKey, // Add key to get scroll view position
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      // shrinkWrap: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
                          .onDrag, // Automatically dismiss the soft keyboard while dragging.
                      children: _displayEntries.mapIndexed((index, item) {
                        final category =
                            _displayEntries[index] as SelectCategoryEntry;
                        final isLast = item == _displayEntries.last;
                        return _buildCategoryView(
                          category,
                          index: index,
                          isLast: isLast,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actionBar != null) actionBar,
      ],
    );
  }
}

class FlattenSelectSkeleton extends StatelessWidget {
  /// Loading skeleton for [FlattenSelect].
  const FlattenSelectSkeleton({
    super.key,
    this.sideBarWidth,
    this.categoryBackgroundColor,
  });

  final double? sideBarWidth;

  final Color? categoryBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = SelectTheme.of(context);

    final categoryBackgroundColor = theme.backgroundColor;

    return ColoredBox(
      color: categoryBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectSideBarSkeleton(
                  width: sideBarWidth,
                  backgroundColor: categoryBackgroundColor,
                ),
                Flexible(
                  child: SelectChipBarSkeleton(
                    itemCount: 16,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ],
            ),
          ),
          const SelectActionBarSkeleton(),
        ],
      ),
    );
  }
}
