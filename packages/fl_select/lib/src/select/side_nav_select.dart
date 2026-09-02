import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import 'action_bar_visibility.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_layout.dart';
import 'select_search_filter.dart';
import 'select_theme.dart';
import 'widgets/select_category_content.dart';
import 'widgets/widgets.dart';

/// Prefetch extent (in logical pixels) for the right column's ListView.
///
/// Large enough to inflate every section of a typical two-level filter
/// panel up front, so any category can be scrolled to with one continuous
/// animation and the scroll-linked highlight can observe every section.
/// Kept finite because an infinite cache extent produces non-finite
/// semantics rects when accessibility services are active.
const double _kRightColumnCacheExtent = 10000.0;

/// Two-level layout: category navigation on the left and a flattened item
/// list on the right.
/// Tapping the left side drives scrolling on the right; scrolling the right side highlights the left side.
/// Only two-level (category -> children) structured data is supported.
///
/// Behavior notes:
/// - The sidebar drives which category's children
///   are shown; each category's children are laid out by the category's
///   `layout` (defaulting to [SideNavSelectDelegate.defaultLayout], then
///   to a wrapable [SelectChipBar]).
/// - At most two levels are rendered; levels nested deeper than the second
///   are not rendered.
/// - A category's `header`/`footer` entries (if any) are rendered as chip
///   bars above/below that category's content, mirroring [CascadingSelect].
/// - Each category's name is rendered as a single title above its content by
///   the view itself; the inner layout views are created with
///   `showTitle: false` so titles never duplicate.
/// - Child selection mode is determined per category by [SelectCategoryEntry.selectionMode].
/// - The right-side content is scroll-synced with the left category list:
///   tapping a category aligns its section (the outer box including its top
///   padding) with the top of the right column in one continuous animation,
///   and scrolling the right column re-highlights the sidebar using the same
///   section box as the geometric anchor.
/// - Custom range entries ([SelectRangeEntry.custom]) are rendered as an input
///   row; typing clears existing child selections for that category.
/// - When an entry's `immediate` is true, selection is applied immediately
///   without requiring the action bar.
/// - In multi-selection mode, the action bar is shown and "Apply" produces the
///   final clipped selection tree.
class SideNavSelect extends StatefulWidget {
  const SideNavSelect({
    super.key,
    required this.delegate,
    required this.entries,
    this.selectedEntries,
    this.searchQuery = '',
    this.searchPredicate,
  });

  final SideNavSelectDelegate delegate;

  final List<SelectEntry> entries;

  /// The previously applied selection to restore, if any.
  final Set<SelectEntry>? selectedEntries;

  /// The current search query. When non-empty, [entries] is filtered for
  /// display using [searchPredicate].
  final String searchQuery;

  /// Custom predicate for search filtering.
  final SelectSearchPredicate? searchPredicate;

  @override
  State<SideNavSelect> createState() => SideNavSelectState();
}

class SideNavSelectState extends State<SideNavSelect> {
  /// Focused category entry
  int _tempSelectedCategoryIndex = 0;

  var _isScrollingProgrammatically = false;

  final GlobalKey _scrollViewKey = GlobalKey();

  /// Drives the right column's ListView so sections beyond the (finite)
  /// prefetch extent can still be scrolled to before their elements are
  /// inflated.
  final ScrollController _scrollController = ScrollController();

  SelectController? controller;

  bool get _isSearching => widget.searchQuery.isNotEmpty;

  List<SelectEntry> get _displayEntries => _isSearching
      ? filterEntriesForSearch(widget.entries, widget.searchQuery,
          predicate: widget.searchPredicate)
      : widget.entries;

  @override
  void dispose() {
    _scrollController.dispose();
    controller?.removeListener(_handleSelectControllerTick);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectController(context);
  }

  @override
  void didUpdateWidget(covariant SideNavSelect oldWidget) {
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

  SideNavSelectDelegate get delegate => widget.delegate;

  void _handleSelectControllerTick() {
    if (mounted) setState(() {});
  }

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
      final childKey = ValueKey('sidenav_section_$i');

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

    // With the right column's generous prefetch extent (see build), the
    // section element is almost always inflated already and can be scrolled
    // to with one continuous animation.
    final sectionKey = ValueKey('sidenav_section_$index');
    final targetElement = _findChildElement(
      _scrollViewKey.currentContext!.findRenderObject()!,
      sectionKey,
    );
    if (targetElement != null) {
      _animateToElement(targetElement);
      return;
    }

    // Fallback for sections still beyond the prefetch extent (extremely
    // long content): animate — never jump — to a deliberately conservative
    // estimate first, then align precisely once the target section is
    // inflated. The estimate is biased low, so the aligning animation that
    // follows only ever continues in the same direction instead of
    // overshooting and bouncing back.
    final position =
        _scrollController.hasClients ? _scrollController.position : null;
    if (position == null || !position.hasContentDimensions) return;

    final target = ((position.maxScrollExtent + position.viewportDimension) *
            index /
            _displayEntries.length)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();

    _isScrollingProgrammatically = true;
    position
        .animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      if (!mounted) return;
      final element = _findChildElement(
        _scrollViewKey.currentContext!.findRenderObject()!,
        sectionKey,
      );
      if (element != null) {
        _animateToElement(element);
      } else {
        _isScrollingProgrammatically = false;
      }
    });
  }

  /// Animates the right column so [targetElement]'s section box (including
  /// its top padding) rests at the top of the right column's viewport.
  ///
  /// Only the right column's own viewport is animated. [Scrollable.ensureVisible]
  /// is intentionally avoided: it walks up and animates every nested
  /// Scrollable ancestor, so a page-level [SingleChildScrollView] hosting
  /// this panel would scroll along with the tap-driven animation (unwanted
  /// scroll chaining). Instead, the reveal offset is computed against the
  /// nearest enclosing viewport of the section box — which is always the
  /// right column's ListView, since any inner scrollables are descendants,
  /// never ancestors — clamped to the scroll range, and applied via the
  /// column's own [ScrollPosition].
  ///
  /// Does nothing when the section's render object is detached, the scroll
  /// controller has no clients, or the position has no content dimensions
  /// yet (e.g. before the first frame).
  ///
  /// The scroll-linked sidebar highlight is guarded for the duration of the
  /// animation via [_isScrollingProgrammatically]; the flag is reset shortly
  /// after the animation completes, or immediately if it fails.
  void _animateToElement(Element targetElement) {
    final renderObject = targetElement.renderObject;
    final position =
        _scrollController.hasClients ? _scrollController.position : null;
    if (renderObject == null || !renderObject.attached) return;
    if (position == null || !position.hasContentDimensions) return;

    // Reveal the section within the right column's own viewport only: the
    // nearest enclosing viewport of the section box is the right column's
    // ListView (inner horizontal scrollables are descendants, never
    // ancestors, so they cannot be picked here).
    final viewport = RenderAbstractViewport.of(renderObject);
    final target = viewport
        .getOffsetToReveal(renderObject, 0.0)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    _isScrollingProgrammatically = true;

    position
        .animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
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
    final categoryEntry =
        widget.entries.singleWhereOrNull((e) => e.id == item.parentId);
    if (categoryEntry is! SelectCategoryEntry) {
      assert(() {
        debugPrint(
          'SideNavSelect: child entry "${item.id}" has a parentId of '
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
    final categoryHeader = category.header;
    final categoryFooter = category.footer;
    final hasHeader = categoryHeader != null && categoryHeader.children != null;
    final hasFooter = categoryFooter != null && categoryFooter.children != null;

    // A category without children, header or footer has nothing to show on
    // the right; render an empty box instead of a lonely category title.
    final hasChildren = category.children?.isNotEmpty ?? false;
    if (!hasChildren && !hasHeader && !hasFooter) {
      return const SizedBox.shrink();
    }

    final view = SelectCategoryContentView(
      category: category,
      index: index,
      selectedEntries:
          controller?.selectedEntriesForParent(category.id, level: 1) ?? {},
      fallbackLayout: delegate.defaultLayout ?? const SelectWrapLayout(),
      delegate: delegate,
      chipDirection: Axis.vertical,
      onTerminalItemTap: _onTerminalItemTap,
    );

    final categoryTitle = _buildCategoryTitle(category);

    // The outer ListView handles vertical scrolling; the inner view must not
    // add another vertical scrollable in the same axis. Every branch above
    // either is non-scrollable (chip/range/counter) or self-sizes its internal
    // scroll view (list/grid), so nesting is safe.
    //
    // The KeyedSubtree is the single scroll-sync anchor shared by both
    // linkage directions: tap-to-scroll aligns its outer edge (including
    // the top padding) with the top of the right column's viewport, and the
    // scroll-linked highlight observes the same box, so the tap resting
    // point always sits on the highlight's geometric origin.
    return KeyedSubtree(
      key: ValueKey('sidenav_section_$index'),
      child: Padding(
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
                        spacing: 12.0,
                        onChanged: (index, entry) =>
                            _onHeaderOrFooterItemTap.call(category, true, index,
                                entry as SelectChildEntry),
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
                        spacing: 12.0,
                        onChanged: (index, entry) =>
                            _onHeaderOrFooterItemTap.call(category, false,
                                index, entry as SelectChildEntry),
                      ),
                    ),
                ],
              )
            : view,
      ),
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

    // A category badge should only appear when it has a "real" selection,
    // i.e. at least one selected child that is not the "Any" placeholder.
    // Selecting only "Any" must not trigger the badge.
    final selectedCategories = controller?.badgedCategories ?? <SelectEntry>{};

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
                isScrollable: delegate.isScrollable,
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
                      // Attached so programmatic scrolls (tap-to-section,
                      // fallback estimate) target only this scrollable and
                      // never chain to ancestor page-level scroll views.
                      controller: _scrollController,
                      // Eagerly inflate every section of the (bounded)
                      // two-level filter so any category can be scrolled to
                      // with one continuous animation instead of an
                      // estimate-then-correct jump; it also lets the
                      // scroll-linked highlight observe every section.
                      cacheExtent: _kRightColumnCacheExtent,
                      physics: ChainingClampingScrollPhysics(),
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

class SideNavSelectSkeleton extends StatelessWidget {
  /// Loading skeleton for [SideNavSelect].
  const SideNavSelectSkeleton({
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
