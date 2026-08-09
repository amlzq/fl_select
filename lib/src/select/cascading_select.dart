import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'action_bar_visibility.dart';
import 'constants.dart';
import 'select_controller.dart';
import 'select_delegate.dart';
import 'select_entry.dart';
import 'select_theme.dart';
import 'widgets/widgets.dart';

/// Horizontal layout: category list on the left and cascading item lists on the right.
/// Tree-structured data with unlimited cascading levels.
///
/// Behavior notes:
/// - Supports arbitrary depth (category -> child -> grandchild -> ...).
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
    required this.previousSelected,
  });

  final CascadingSelectDelegate delegate;

  final List<SelectEntry> entries;

  final Set<SelectEntry>? previousSelected;

  @override
  State<CascadingSelect> createState() => CascadingSelectState();
}

class CascadingSelectState extends State<CascadingSelect> {
  /// Temporarily selected (focused) item per level (usually a parent node)
  /// Terminal nodes do not need to be included in the temporary selection list
  final List<SelectEntry> _tempSelectedEntryPerLevel = [];

  /// Cascading lists: index0 is first-level children, index1 is second-level children, and so on
  final List<List<SelectEntry>> _cascadingList = [];

  /// Current focused level
  /// 0 means only category nodes are shown; 1 means category + first-level children are shown; and so on
  int _currentLevel = 0;

  final List<ScrollController> _scrollControllers = [];

  final ScrollController _cascadeHorizontalController = ScrollController();

  SelectController? controller;
  int _alignmentSession = 0;

  /// Gradient colors for each level
  late List<Color> _backgroundColors;
  // late List<Color> _textColors;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _disposeScrollControllers();
    _cascadeHorizontalController.dispose();
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
    // every tap — even though entries and previousSelected are unchanged.
    // Unconditionally calling _updateSelectController (which calls
    // _rebuildSelectionState) discards the in-memory focused-path state
    // (_tempSelectedEntryPerLevel) and rebuilds it from the state tree.
    // While that rebuild is usually correct, it is unnecessary work and can
    // cause the UI to jump to a different category under certain timing
    // conditions. Guarding the call avoids the extra rebuild.
    final sameEntries = const ListEquality<SelectEntry>()
        .equals(widget.entries, oldWidget.entries);
    final samePrevious = const SetEquality<SelectEntry>().equals(
        widget.previousSelected ?? const {},
        oldWidget.previousSelected ?? const {});
    if (!sameEntries || !samePrevious) {
      _updateSelectController(context);
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
    final categoryBackgroundColor =
        delegate.categoryBackgroundColor ?? theme.backgroundColor;
    final terminalBackgroundColor =
        delegate.terminalBackgroundColor ?? theme.backgroundColorHighest;
    final maxDepth = _calculateMaxDepth(widget.entries.toSet(), 1);
    _backgroundColors = _calculateGradientColors(
        maxDepth, categoryBackgroundColor, terminalBackgroundColor);

    controller?.bindState(
      widget.entries,
      initializeAnyIfEmpty: false,
      previousSelectedOverride: widget.previousSelected,
    );
    _rebuildSelectionState();
  }

  void _handleSelectControllerTick() {
    if (!mounted) return;
    setState(() {});
  }

  CascadingSelectDelegate get delegate => widget.delegate;

  void _rebuildSelectionState() {
    _tempSelectedEntryPerLevel.clear();
    _currentLevel = 0;
    _cascadingList.clear();
    _disposeScrollControllers();

    _initializeTempSelectedEntryPerLevel(null, 0);

    if (_tempSelectedEntryPerLevel.isEmpty && widget.entries.isNotEmpty) {
      final firstCategory = widget.entries.first as SelectCategoryEntry;
      _tempSelectedEntryPerLevel.add(firstCategory);
      _cascadingList.add(firstCategory.children?.toList() ?? []);
      _currentLevel = 1;
      _scrollControllers.add(ScrollController());
    }

    // Reveal to selected list item after build
    _scheduleCascadeReveal();
  }

  void _scheduleCascadeReveal() {
    final session = ++_alignmentSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || session != _alignmentSession) return;
      _revealFocusedItemsIfNeeded();
      _scrollCascadeToEnd();
    });
  }

  void _revealFocusedItemsIfNeeded() {
    bool sameEntry(SelectEntry a, SelectEntry b) {
      if (a.id != b.id) return false;
      if (a is SelectChildEntry && b is SelectChildEntry) {
        return a.parentId == b.parentId;
      }
      return true;
    }

    for (int columnIndex = 0;
        columnIndex < _scrollControllers.length;
        columnIndex++) {
      if (columnIndex >= _cascadingList.length) continue;
      final scrollController = _scrollControllers[columnIndex];
      if (!scrollController.hasClients) continue;

      final entries = _cascadingList[columnIndex];
      if (entries.isEmpty) continue;

      final parent = _tempSelectedEntryPerLevel.elementAtOrNull(columnIndex);
      final selectionLevel = columnIndex + 1;
      final selectedAtLevel =
          controller?.selectedEntriesAtLevel(selectionLevel) ?? {};

      SelectEntry? target =
          _tempSelectedEntryPerLevel.elementAtOrNull(columnIndex + 1);

      if (target == null && parent != null) {
        target = selectedAtLevel
            .whereType<SelectChildEntry>()
            .firstWhereOrNull((e) => e.parentId == parent.id);
      }

      target ??= selectedAtLevel.firstOrNull;
      if (target == null) continue;

      final selectedIndex = entries.indexWhere((e) => sameEntry(e, target!));
      if (selectedIndex == -1) continue;

      const itemExtent = kSelectListTileHeight;
      final itemTop = selectedIndex * itemExtent;
      final itemBottom = itemTop + itemExtent;
      final viewportTop = scrollController.offset;
      final viewportBottom =
          viewportTop + scrollController.position.viewportDimension;

      double? targetOffset;
      if (itemTop < viewportTop) {
        targetOffset = itemTop;
      } else if (itemBottom > viewportBottom) {
        targetOffset = itemBottom - scrollController.position.viewportDimension;
      }

      if (targetOffset == null) continue;
      final maxScroll = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(targetOffset.clamp(0.0, maxScroll));
    }
  }

  void _scrollCascadeToEnd() {
    if (delegate.isScrollable != true) return;
    if (!_cascadeHorizontalController.hasClients) return;
    final maxScroll = _cascadeHorizontalController.position.maxScrollExtent;
    _cascadeHorizontalController.animateTo(
      maxScroll,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  double _measureMaxLabelWidth(
    BuildContext context,
    Iterable<SelectEntry> entries,
    TextStyle style,
  ) {
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    double maxWidth = 0;
    for (final entry in entries) {
      final label = entry.name ?? '';
      if (label.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: textDirection,
        maxLines: 1,
        textScaler: textScaler,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
    }
    return maxWidth;
  }

  double _estimateCascadeColumnWidth(BuildContext context, int cascadeIndex) {
    const horizontalPadding = 20.0;
    const trailingWidth = 48.0;
    const badgeWidth = 24.0;

    final entries = _cascadingList[cascadeIndex];
    const textStyle = TextStyle(fontSize: 14);

    final maxLabelWidth = _measureMaxLabelWidth(context, entries, textStyle);
    final hasTrailing = entries.any((e) => !e.hasChildren && e.enabled);
    final width = maxLabelWidth +
        horizontalPadding +
        badgeWidth +
        (hasTrailing ? trailingWidth : 0);
    return width.clamp(160.0, double.infinity).toDouble();
  }

  SelectEntries _headerSelectedFor(String categoryId) =>
      controller?.selectedHeaderEntriesFor(categoryId) ?? <SelectEntry>{};

  SelectEntries _footerSelectedFor(String categoryId) =>
      controller?.selectedFooterEntriesFor(categoryId) ?? <SelectEntry>{};

  void _disposeScrollControllers() {
    for (var scrollController in _scrollControllers) {
      scrollController.dispose();
    }
    _scrollControllers.clear();
  }

  SelectEntry? _pickFocusedEntryForLevel(SelectEntry? parent, int level) {
    final selectedEntries = controller?.selectedEntriesAtLevel(level) ?? {};
    if (selectedEntries.isEmpty) return null;

    final Iterable<SelectEntry> candidates;
    if (level == 0) {
      candidates = selectedEntries.whereType<SelectCategoryEntry>();
    } else {
      if (parent == null) return null;
      candidates = selectedEntries
          .whereType<SelectChildEntry>()
          .where((entry) => entry.parentId == parent.id);
    }

    if (candidates.isEmpty) return null;

    int score(SelectEntry entry, int currentLevel) {
      final nextSelected =
          controller?.selectedEntriesAtLevel(currentLevel + 1) ?? {};
      final nextChildren = nextSelected
          .whereType<SelectChildEntry>()
          .where((child) => child.parentId == entry.id);
      final descendantScore =
          nextChildren.map((child) => score(child, currentLevel + 1)).maxOrNull;
      final selfScore = entry is SelectChildEntry && entry.isAny ? 0 : 1;
      if (descendantScore == null) return selfScore;
      return 10 + descendantScore + selfScore;
    }

    SelectEntry? bestEntry;
    var bestScore = -1;
    for (final entry in candidates) {
      final entryScore = score(entry, level);
      if (entryScore > bestScore) {
        bestEntry = entry;
        bestScore = entryScore;
      }
    }
    return bestEntry;
  }

  /// Builds a connected focused path from state tree selections.
  void _initializeTempSelectedEntryPerLevel(SelectEntry? parent, int level) {
    final selectedEntry = _pickFocusedEntryForLevel(parent, level);
    if (selectedEntry == null) return;

    _tempSelectedEntryPerLevel.add(selectedEntry);
    if (selectedEntry.hasChildren) {
      _cascadingList.add(selectedEntry.children?.toList() ?? []);
      _currentLevel = level + 1;
      _scrollControllers.add(ScrollController());
      _initializeTempSelectedEntryPerLevel(selectedEntry, level + 1);
    }
  }

  /// Calculate gradient colors for cascade levels
  List<Color> _calculateGradientColors(
      int depth, Color beginColor, Color endColor) {
    if (depth <= 1) {
      return [beginColor];
    }
    final colors = <Color>[];
    for (int i = 0; i < depth; i++) {
      final t = depth == 1 ? 0.0 : i / (depth - 1);
      colors.add(Color.lerp(beginColor, endColor, t)!);
    }
    return colors;
  }

  /// Calculate maximum depth of the tree structure
  int _calculateMaxDepth(Set<SelectEntry>? entries, int currentDepth) {
    int maxDepth = currentDepth;
    for (SelectEntry entry in entries ?? []) {
      if (entry.hasChildren) {
        final childDepth =
            _calculateMaxDepth(entry.children!, currentDepth + 1);
        if (childDepth > maxDepth) {
          maxDepth = childDepth;
        }
      }
    }
    return maxDepth;
  }

  /// Focused Category Item
  SelectCategoryEntry get tempSelectedCategory =>
      _tempSelectedEntryPerLevel.first as SelectCategoryEntry;

  /// Selection Mode for category entries
  SelectionMode? get categorySelectionMode => delegate.selectionMode;

  /// Selection Mode for the selected category sub-items
  SelectionMode get childrenSelectionMode => tempSelectedCategory.selectionMode;

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

  /// Tap handler for a category item
  void _onCategoryItemTap(SelectCategoryEntry newCategoryEntry) {
    final selectionMode = controller?.selectionMode;
    if (SelectionMode.single == selectionMode) {
      _tempSelectedEntryPerLevel.clear();
      _cascadingList.clear();
      _disposeScrollControllers();

      // Select the new category
      _tempSelectedEntryPerLevel.add(newCategoryEntry);
      _cascadingList.add(tempSelectedCategory.children?.toList() ?? []);
      _currentLevel = 1;
      _scrollControllers.add(ScrollController());
    } else {
      // Multi-select mode: keep previous selection and only switch the focused category
      if (_tempSelectedEntryPerLevel.isEmpty ||
          _tempSelectedEntryPerLevel.firstOrNull is! SelectCategoryEntry) {
        _tempSelectedEntryPerLevel
          ..clear()
          ..add(newCategoryEntry);
      } else {
        _tempSelectedEntryPerLevel[0] = newCategoryEntry;
      }

      _cascadingList
        ..clear()
        ..add(newCategoryEntry.children?.toList() ?? []);
      _currentLevel = 1;
      _disposeScrollControllers();
      _scrollControllers.add(ScrollController());
    }
    controller?.focusCategoryEntry(
      newCategoryEntry,
      selectionMode: selectionMode ?? SelectionMode.single,
    );
    setState(() {});
    _scheduleCascadeReveal();
  }

  /// Tap handler for a middle node
  /// Only selecting a terminal node is an actual selection; otherwise it just expands children
  void _onMiddleItemTap(int cascadeIndex, SelectEntry entry) {
    if (entry == _tempSelectedEntryPerLevel.lastOrNull) {
      // Re-tapping the same node: no-op
      return;
    }

    final level = cascadeIndex + 1;

    // items.firstWhere((e) => e.isAny).selected = false;

    while (_tempSelectedEntryPerLevel.length > level) {
      _tempSelectedEntryPerLevel.removeLast();
    }
    _tempSelectedEntryPerLevel.add(entry);

    // Remove all levels after the current level
    while (_cascadingList.length > level) {
      _cascadingList.removeLast();
      if (_scrollControllers.length > level) {
        _scrollControllers.removeLast().dispose();
      }
    }

    // Expand child nodes
    _cascadingList.add(entry.children?.toList() ?? []);
    _currentLevel = level + 1;
    _scrollControllers.add(ScrollController());

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_scrollControllers.last.hasClients) {
    //     _scrollControllers.last.jumpTo(x);
    //   }
    // });

    setState(() {});
    _scheduleCascadeReveal();
  }

  /// Tap handler for a terminal node
  /// Only selecting a terminal node is an actual selection; otherwise it just expands children
  void _onTerminalItemTap(int cascadeIndex, SelectChildEntry entry) {
    // Jump-level selection for an "Any" entry (e.g., selecting the category's "Any" entry)
    final level = cascadeIndex + 1;
    if (level < _currentLevel && entry.isAny) {
      // Remove all levels after the current level
      controller?.trimSelectionLevels(level);
      while (_cascadingList.length > level) {
        _cascadingList.removeLast();
      }
      while (_tempSelectedEntryPerLevel.length > level) {
        _tempSelectedEntryPerLevel.removeLast();
      }
      _tempSelectedEntryPerLevel.add(entry);
      _currentLevel = level;
      controller?.toggleCascadingEntry(
        entry,
        selectionMode: selectSelectionMode ?? SelectionMode.single,
        childrenSelectionMode: childrenSelectionMode,
        focusedPath: _tempSelectedEntryPerLevel.take(cascadeIndex + 1).toList(),
        category: tempSelectedCategory,
      );
      _setStateOrImmediateApply(entry);
      return;
    }

    controller?.toggleCascadingEntry(
      entry,
      selectionMode: selectSelectionMode ?? SelectionMode.single,
      childrenSelectionMode: childrenSelectionMode,
      focusedPath: _tempSelectedEntryPerLevel.take(cascadeIndex + 1).toList(),
      category: tempSelectedCategory,
    );

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

  void _onHeaderOrFooterItemTap(
    bool isHeader,
    int chipIndex,
    SelectChildEntry entry,
  ) {
    final selectionMode = isHeader
        ? tempSelectedCategory.headerSelectionMode
        : tempSelectedCategory.footerSelectionMode;
    controller?.toggleHeaderOrFooterEntry(
      categoryId: tempSelectedCategory.id,
      entry: entry,
      selectionMode: selectionMode,
      isHeader: isHeader,
    );

    _setStateOrImmediateApply(entry);
  }

  void _onApplyTap() {
    controller?.applyFromState();
  }

  void _onResetTap() {
    final previousSelectedCategoryId = tempSelectedCategory.id;
    controller?.resetState(initializeAnyIfEmpty: false);
    _rebuildSelectionState();
    final newCategory =
        widget.entries.firstWhere((e) => e.id == previousSelectedCategoryId)
            as SelectCategoryEntry;
    _onCategoryItemTap(newCategory);
    setState(() {});
    controller?.reset();
  }

  Widget buildCascadeList(int cascadeIndex, double? width) {
    final entries = _cascadingList[cascadeIndex];
    final level = cascadeIndex + 1;
    final selectedEntries = controller?.selectedEntriesAtLevel(level) ?? {};
    final bgColor = level < _backgroundColors.length
        ? _backgroundColors[level]
        : Colors.white;
    final selectedColor = level + 1 < _backgroundColors.length
        ? _backgroundColors[level + 1]
        : Colors.white;

    final child = ColoredBox(
      color: bgColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        controller: _scrollControllers[cascadeIndex],
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index] as SelectTextEntry;
          if (!entry.hasChildren && entry.enabled) {
            final selected = selectedEntries.contains(entry);
            if (SelectionMode.single == childrenSelectionMode) {
              return SelectRadioListTile(
                label: entry.name ?? '',
                selected: selected,
                radioBuilder: delegate.radioBuilder,
                enabled: entry.enabled,
                onTap: () {
                  _onTerminalItemTap.call(cascadeIndex, entry);
                },
              );
            } else {
              return SelectCheckboxListTile(
                label: entry.name ?? '',
                checked: selected,
                checkboxBuilder: delegate.checkboxBuilder,
                enabled: entry.enabled,
                onTap: () => _onTerminalItemTap.call(cascadeIndex, entry),
              );
            }
          } else {
            final selected = _tempSelectedEntryPerLevel.contains(entry);
            final selectedCount = controller
                    ?.selectedEntriesAtLevel(level + 1)
                    .where(
                        (e) => e is SelectChildEntry && e.parentId == entry.id)
                    .length ??
                0;
            return SelectListTile(
              label: entry.name ?? '',
              selected: selected,
              selectedTileColor: selectedColor,
              badge: selectedCount > 0 ? selectedCount.toString() : null,
              enabled: entry.enabled,
              onTap: () => _onMiddleItemTap.call(cascadeIndex, entry),
            );
          }
        },
      ),
    );

    if (width == null) {
      return Flexible(child: child);
    }
    return SizedBox(width: width, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SelectTheme.of(context);
    final isScrollable = delegate.isScrollable == true;

    /// Maximum level for the current category
    // final maxLevel = tempSelectedCategory.maxLevel;
    // final isMultipleSelectionMode =
    //     SelectionMode.multiple == tempSelectedCategory.selectionMode;

    final categoryHeader = tempSelectedCategory.header;
    final categoryFooter = tempSelectedCategory.footer;
    final headerSelected = _headerSelectedFor(tempSelectedCategory.id);
    final footerSelected = _footerSelectedFor(tempSelectedCategory.id);

    final categoryBackgroundColor =
        _backgroundColors.firstOrNull ?? Colors.white;
    // Get selected item color (background color of next level)
    final selectedTileColor = 0 + 1 < _backgroundColors.length
        ? _backgroundColors[0 + 1]
        : Colors.white;

    final effectiveSelectedColor =
        delegate.selectedColor ?? theme.selectedColor;

    final tempSelectedCategoryIndex =
        widget.entries.indexOf(tempSelectedCategory);

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
                width: delegate.sideBarTheme?.width,
                backgroundColor: categoryBackgroundColor,
                selectedColor: effectiveSelectedColor,
                selectedTileColor: selectedTileColor,
                entries: widget.entries,
                selectedCategories: selectedCategories,
                focusedIndex: tempSelectedCategoryIndex,
                onChanged: (_, entry) =>
                    _onCategoryItemTap(entry as SelectCategoryEntry),
              ),
              // Children lists (right)
              // delegate.isScrollable
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryHeader != null &&
                        categoryHeader.children != null)
                      SelectChipBar(
                        category: categoryHeader,
                        entries: categoryHeader.children!.toList(),
                        selectedEntries: headerSelected,
                        variant: SelectChipVariant.filled,
                        onChanged: (index, entry) => _onHeaderOrFooterItemTap
                            .call(true, index, entry as SelectChildEntry),
                      ),
                    Expanded(
                      child: isScrollable
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                final row = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(
                                    _cascadingList.length,
                                    (cascadeIndex) => buildCascadeList(
                                      cascadeIndex,
                                      _estimateCascadeColumnWidth(
                                        context,
                                        cascadeIndex,
                                      ),
                                    ),
                                  ),
                                );
                                return ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(context)
                                      .copyWith(overscroll: false),
                                  child: SingleChildScrollView(
                                    controller: _cascadeHorizontalController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: row,
                                  ),
                                );
                              },
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                _cascadingList.length,
                                (cascadeIndex) =>
                                    buildCascadeList(cascadeIndex, null),
                              ),
                            ),
                    ),
                    if (categoryFooter != null &&
                        categoryFooter.children != null)
                      SelectChipBar(
                        category: categoryFooter,
                        entries: categoryFooter.children!.toList(),
                        selectedEntries: footerSelected,
                        variant: SelectChipVariant.filled,
                        onChanged: (index, entry) => _onHeaderOrFooterItemTap
                            .call(false, index, entry as SelectChildEntry),
                      ),
                  ],
                ),
              ),
            ],
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

// class _CascadingSelectDefaults extends SelectThemeData {
//   _CascadingSelectDefaults(this.context) : super();

//   final BuildContext context;
//   late final ColorScheme _colors = Theme.of(context).colorScheme;
//   late final TextTheme _textTheme = Theme.of(context).textTheme;

//   @override
//   Color? get selectedColor => _colors.primary;

//   @override
//   Color? get categoryBackgroundColor => _colors.surfaceContainer;

//   @override
//   Color? get terminalBackgroundColor => _colors.surfaceContainerHighest;
// }

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
