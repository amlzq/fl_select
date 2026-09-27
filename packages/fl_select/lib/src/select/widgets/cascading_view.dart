import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_controller.dart';
import '../select_entry.dart';
import '../select_theme.dart';
import '../select_utils.dart';
import 'cascading_view_theme.dart';
import 'constants.dart';
import 'list_tile.dart';

/// Renders the cascading (multi-column) item area of a category tree.
///
/// The first column is driven by [entries] — normally the children of
/// [category] — and tapping an entry that has children appends that entry's
/// children as a new column to the right, with no depth limit
/// (child -> grandchild -> ...). Tapping a leaf entry performs the actual
/// selection through the ambient [SelectController].
///
/// The view owns the cascade navigation state: the column contents, the
/// focused path, one vertical [ScrollController] per column and the horizontal
/// controller used to sweep to the newly revealed column. Selection state is
/// read from and written to the ambient [SelectController]
/// ([SelectController.selectedEntriesAtLevel] /
/// [SelectController.toggleCascadingEntry]) so that the two hosts —
/// `CascadingSelect` and the `SelectCascadingLayout` branch of
/// `SelectCategoryContentView` — share exactly one implementation.
class CascadingView extends StatefulWidget {
  /// Creates a cascading item area for [category].
  const CascadingView({
    super.key,
    required this.entries,
    required this.category,
    this.selectionMode = SelectionMode.single,
    this.isScrollable = false,
    this.shrinkWrap = false,
    this.showTitle = true,
    this.backgroundColors,
    this.autoExpandFirstBranch = false,
    this.restoreSelectionPath = true,
    this.radioBuilder,
    this.checkboxBuilder,
  });

  /// The entries of the first column, usually [category]'s children.
  final List<SelectEntry> entries;

  /// The category that owns the cascade.
  ///
  /// It is the root of the focused path handed to
  /// [SelectController.toggleCascadingEntry] and the owner of the columns'
  /// selection level (column `n` reads and writes level `n + 1`).
  final SelectCategoryEntry category;

  /// The effective selection mode for [category]'s children.
  ///
  /// [SelectionMode.single] renders radio tiles for leaf entries,
  /// [SelectionMode.multiple] renders checkbox tiles.
  final SelectionMode selectionMode;

  /// Whether the cascade scrolls horizontally when the columns overflow.
  final bool isScrollable;

  /// Whether the columns size themselves to their content instead of filling
  /// and scrolling within the available height.
  ///
  /// Set this to `true` when the host gives an unbounded height — for example
  /// the content view of a category sitting inside an outer vertical
  /// scrollable. In that mode the per-column scrolling and the post-frame
  /// alignment jump are skipped, because the viewport equals the content.
  final bool shrinkWrap;

  /// Whether to show [category]'s name as a header above the columns.
  ///
  /// Defaults to true, mirroring [SelectListView.showTitle]. Hosts that
  /// already render the category name — the cascading select (its sidebar
  /// highlights the focused category) and the category containers (their tab,
  /// sidebar or expansion tile shows it) — pass false.
  final bool showTitle;

  /// The background color of every depth level, index 0 being the category
  /// level.
  ///
  /// When null, [SelectCascadingViewTheme.backgroundColors] is used if set,
  /// otherwise the gradient is derived from [SelectTheme] using the depth of
  /// [category]; a host that already computed its own gradient (such as
  /// `CascadingSelect`, whose sidebar shares index 0) passes it in so both
  /// stay in sync.
  final List<Color>? backgroundColors;

  /// Whether to expand the first branch that still has children when nothing
  /// is selected yet.
  ///
  /// Used while searching, so that deeper matches are revealed.
  final bool autoExpandFirstBranch;

  /// Whether a rebuild of the columns should re-expand the deepest selected
  /// path below [category].
  ///
  /// Only read when the columns are (re)built, i.e. on mount and whenever
  /// [entries] or [category] change. Pass `false` to collapse the cascade to
  /// the first column — for example when the user switches to another
  /// category.
  final bool restoreSelectionPath;

  /// Optional builder for the radio widget of a leaf entry.
  final ToggleWidgetBuilder? radioBuilder;

  /// Optional builder for the checkbox widget of a leaf entry.
  final ToggleWidgetBuilder? checkboxBuilder;

  @override
  State<CascadingView> createState() => _CascadingViewState();
}

class _CascadingViewState extends State<CascadingView> {
  /// Focused (expanded) entry per level; index 0 is always
  /// [CascadingView.category].
  ///
  /// This is the widget-side counterpart of the `focusedPath` passed to
  /// [SelectController.toggleCascadingEntry]: the same list drives the
  /// cascade columns and is handed to the controller as the ancestor path.
  ///
  /// It holds navigation state only — the "tentative" selection that is not
  /// committed until "Apply" lives in the controller's state tree.
  /// Terminal nodes are not included: they end the cascade.
  final List<SelectEntry> _focusedEntryPerLevel = [];

  /// Cascading columns: index 0 is [CascadingView.entries], index 1 is the
  /// children of the first expanded entry, and so on.
  final List<List<SelectEntry>> _cascadingList = [];

  /// One vertical controller per column, kept index-aligned with
  /// [_cascadingList].
  final List<ScrollController> _scrollControllers = [];

  final ScrollController _cascadeHorizontalController = ScrollController();

  /// Current focused level: 1 means only [CascadingView.entries] is shown, 2
  /// means one more column, and so on.
  int _currentLevel = 0;

  SelectController? controller;

  int _alignmentSession = 0;

  /// Gradient colors for each level.
  late List<Color> _backgroundColors;

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
  void didUpdateWidget(covariant CascadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _backgroundColors =
        widget.backgroundColors ?? _resolveBackgroundColors(context);
    final sameEntries = const ListEquality<SelectEntry>().equals(
      widget.entries,
      oldWidget.entries,
    );
    // A different category instance (or a different entry set) means the
    // cascade must be rebuilt from the selection state; unrelated rebuilds of
    // the host must not discard the in-memory focused path.
    if (!sameEntries || !identical(widget.category, oldWidget.category)) {
      _rebuildColumns();
    }
  }

  void _updateSelectController(BuildContext context) {
    if (controller == null) {
      controller = SelectController.of(context);
      controller?.addListener(_handleSelectControllerTick);
    }
    _backgroundColors =
        widget.backgroundColors ?? _resolveBackgroundColors(context);
    _rebuildColumns();
  }

  void _handleSelectControllerTick() {
    if (!mounted) return;
    setState(() {});
  }

  /// Resolves the per-level background colors: the theme override when set,
  /// otherwise the depth-based gradient derived from the ambient theme.
  List<Color> _resolveBackgroundColors(BuildContext context) {
    final theme = SelectTheme.of(context);
    // A theme-level gradient replaces the derived one entirely: the host owns
    // the whole level palette (index 0 is the category level).
    final themeColors = SelectCascadingViewTheme.of(context).backgroundColors;
    if (themeColors != null && themeColors.isNotEmpty) {
      return themeColors;
    }
    // The cascade always renders at least the category level plus one children
    // column, so the gradient must span two steps even for a childless
    // category.
    final depth = max(2, SelectUtils.maxDepth({widget.category}, 1));
    return SelectUtils.gradientColors(
      depth,
      theme.backgroundColor,
      theme.backgroundColorHighest,
    );
  }

  /// Rebuilds the columns from [CascadingView.entries] and the current
  /// selection, restoring the deepest selected path below the category.
  void _rebuildColumns() {
    _focusedEntryPerLevel
      ..clear()
      ..add(widget.category);
    _cascadingList
      ..clear()
      ..add(widget.entries);
    _currentLevel = 1;
    _disposeScrollControllers();
    _scrollControllers.add(ScrollController());

    if (widget.autoExpandFirstBranch) {
      // Keep expanding along the first branch that still has children so
      // deeper matches (e.g. entries at the third level) are revealed.
      while (true) {
        final currentEntries = _cascadingList.lastOrNull;
        if (currentEntries == null) break;
        final next = currentEntries.firstWhereOrNull((e) => e.hasChildren);
        if (next == null) break;
        _focusedEntryPerLevel.add(next);
        _cascadingList.add(next.children?.toList() ?? []);
        _scrollControllers.add(ScrollController());
      }
      _currentLevel = _cascadingList.length;
    } else if (widget.restoreSelectionPath) {
      _initializeFocusedEntryPerLevel(widget.category, 1);
    }

    _scheduleCascadeReveal();
  }

  void _scheduleCascadeReveal() {
    // Under an unbounded host the columns are neither scrollable nor taller
    // than their content, so there is nothing to scroll — unless the cascade
    // itself scrolls horizontally, which stays meaningful there.
    if (widget.shrinkWrap && !widget.isScrollable) return;
    final session = ++_alignmentSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || session != _alignmentSession) return;
      if (!widget.shrinkWrap) {
        _revealFocusedItemsIfNeeded();
      }
      _scrollCascadeToEnd();
    });
  }

  /// Scrolls every column so the selected/focused entry is visible.
  void _revealFocusedItemsIfNeeded() {
    bool sameEntry(SelectEntry a, SelectEntry b) {
      if (a.id != b.id) return false;
      if (a is SelectChildEntry && b is SelectChildEntry) {
        return a.parentId == b.parentId;
      }
      return true;
    }

    for (
      int columnIndex = 0;
      columnIndex < _scrollControllers.length;
      columnIndex++
    ) {
      if (columnIndex >= _cascadingList.length) continue;
      final scrollController = _scrollControllers[columnIndex];
      if (!scrollController.hasClients) continue;

      final entries = _cascadingList[columnIndex];
      if (entries.isEmpty) continue;

      final parent = _focusedEntryPerLevel.elementAtOrNull(columnIndex);
      final selectionLevel = columnIndex + 1;
      final selectedAtLevel =
          controller?.selectedEntriesAtLevel(selectionLevel) ?? {};

      SelectEntry? target = _focusedEntryPerLevel.elementAtOrNull(
        columnIndex + 1,
      );

      if (target == null && parent != null) {
        target = selectedAtLevel.whereType<SelectChildEntry>().firstWhereOrNull(
          (e) => e.parentId == parent.id,
        );
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
    if (!widget.isScrollable) return;
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
    final width =
        maxLabelWidth +
        horizontalPadding +
        badgeWidth +
        (hasTrailing ? trailingWidth : 0);
    return width.clamp(160.0, double.infinity).toDouble();
  }

  void _disposeScrollControllers() {
    for (var scrollController in _scrollControllers) {
      scrollController.dispose();
    }
    _scrollControllers.clear();
  }

  SelectEntry? _pickFocusedEntryForLevel(SelectEntry? parent, int level) =>
      SelectUtils.pickFocusedEntry(
        (level) => controller?.selectedEntriesAtLevel(level) ?? {},
        parent,
        level,
      );

  /// Resolves [entry] to the corresponding entry in the source tree rooted at
  /// [CascadingView.category].
  ///
  /// Selections made while searching store filtered copies (created via
  /// `copyWith` with only matching children). Resolving back to the source
  /// tree ensures cascading columns render the full children after the search
  /// is canceled.
  SelectEntry? _resolveFromSource(SelectEntry? parent, SelectEntry entry) {
    final source = parent == null ? widget.entries : parent.children;
    if (source == null) return null;
    for (final candidate in source) {
      if (candidate.id != entry.id) continue;
      if (entry is SelectChildEntry) {
        if (candidate is SelectChildEntry &&
            candidate.parentId == entry.parentId) {
          return candidate;
        }
        continue;
      }
      return candidate;
    }
    return null;
  }

  /// Builds a connected focused path from state tree selections.
  void _initializeFocusedEntryPerLevel(SelectEntry? parent, int level) {
    final picked = _pickFocusedEntryForLevel(parent, level);
    if (picked == null) return;

    // Prefer the original tree instance so the expanded columns show the
    // complete children, not the search-filtered subset.
    final selectedEntry = _resolveFromSource(parent, picked) ?? picked;

    _focusedEntryPerLevel.add(selectedEntry);
    if (selectedEntry.hasChildren) {
      _cascadingList.add(selectedEntry.children?.toList() ?? []);
      _currentLevel = level + 1;
      _scrollControllers.add(ScrollController());
      _initializeFocusedEntryPerLevel(selectedEntry, level + 1);
    }
  }

  /// Tap handler for a middle node: it only expands the children, unless the
  /// tapped node is already the deepest focused one.
  void _onMiddleItemTap(int cascadeIndex, SelectEntry entry) {
    if (entry == _focusedEntryPerLevel.lastOrNull) {
      // Re-tapping the same node: no-op
      return;
    }

    final level = cascadeIndex + 1;

    while (_focusedEntryPerLevel.length > level) {
      _focusedEntryPerLevel.removeLast();
    }
    _focusedEntryPerLevel.add(entry);

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

    setState(() {});
    _scheduleCascadeReveal();
  }

  /// Tap handler for a terminal node: selecting a terminal node is the actual
  /// selection.
  void _onTerminalItemTap(int cascadeIndex, SelectChildEntry entry) {
    // Jump-level selection for an "Any" entry (e.g., selecting the category's
    // "Any" entry)
    final level = cascadeIndex + 1;
    if (level < _currentLevel && entry.isAny) {
      // Remove all levels after the current level
      controller?.trimSelectionLevels(level);
      while (_cascadingList.length > level) {
        _cascadingList.removeLast();
        if (_scrollControllers.length > level) {
          _scrollControllers.removeLast().dispose();
        }
      }
      while (_focusedEntryPerLevel.length > level) {
        _focusedEntryPerLevel.removeLast();
      }
      _focusedEntryPerLevel.add(entry);
      _currentLevel = level;
      controller?.toggleCascadingEntry(
        entry,
        // Cross-category clearing must follow the delegate-level mode.
        // [SelectController.hasMultipleMode] turns true as soon as any
        // category opts into multiple, disabling the clearing.
        selectionMode: controller?.selectionMode ?? SelectionMode.single,
        childrenSelectionMode: widget.selectionMode,
        focusedPath: _focusedEntryPerLevel.take(cascadeIndex + 1).toList(),
        category: widget.category,
      );
      _setStateOrImmediateApply(entry);
      return;
    }

    controller?.toggleCascadingEntry(
      entry,
      // Delegate-level mode; see the Any-skip branch above for rationale.
      selectionMode: controller?.selectionMode ?? SelectionMode.single,
      childrenSelectionMode: widget.selectionMode,
      focusedPath: _focusedEntryPerLevel.take(cascadeIndex + 1).toList(),
      category: widget.category,
    );

    _setStateOrImmediateApply(entry);
  }

  void _setStateOrImmediateApply(SelectChildEntry entry) {
    if (controller?.hasMultipleMode != true || entry.immediate) {
      // No need to tap "Apply"; return result immediately
      controller?.applyFromState();
    } else {
      setState(() {});
      controller?.emitChangeFromState();
    }
  }

  Widget _buildColumn(int cascadeIndex, double? width) {
    final entries = _cascadingList[cascadeIndex];
    final level = cascadeIndex + 1;
    final selectedEntries = controller?.selectedEntriesAtLevel(level) ?? {};
    // Clamp to the gradient's last color instead of a hard-coded white so
    // out-of-range levels still match the theme.
    final bgColor = level < _backgroundColors.length
        ? _backgroundColors[level]
        : _backgroundColors.last;
    final selectedColor = level + 1 < _backgroundColors.length
        ? _backgroundColors[level + 1]
        : _backgroundColors.last;

    final child = ColoredBox(
      color: bgColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        controller: _scrollControllers[cascadeIndex],
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index] as SelectChildEntry;
          if (!entry.hasChildren && entry.enabled) {
            final selected = selectedEntries.contains(entry);
            if (SelectionMode.single == widget.selectionMode) {
              return SelectRadioListTile(
                label: entry.name ?? '',
                selected: selected,
                radioBuilder: widget.radioBuilder,
                enabled: entry.enabled,
                onTap: () {
                  _onTerminalItemTap.call(cascadeIndex, entry);
                },
              );
            } else {
              return SelectCheckboxListTile(
                label: entry.name ?? '',
                checked: selected,
                checkboxBuilder: widget.checkboxBuilder,
                enabled: entry.enabled,
                onTap: () => _onTerminalItemTap.call(cascadeIndex, entry),
              );
            }
          } else {
            final selected = _focusedEntryPerLevel.contains(entry);
            final selectedCount =
                controller
                    ?.selectedEntriesAtLevel(level + 1)
                    .where(
                      (e) => e is SelectChildEntry && e.parentId == entry.id,
                    )
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

  /// Wraps [content] (the cascade columns) with [CascadingView.category]'s name,
  /// mirroring [SelectListView]'s title header.
  Widget _buildWithTitle(BuildContext context, Widget content) {
    final title = widget.category.name;
    if (!widget.showTitle || title == null) return content;

    final header = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DefaultTextStyle.merge(
        style:
            Theme.of(context).textTheme.titleSmall ??
            const TextStyle(fontSize: 16),
        child: Text(title),
      ),
    );

    // Under an unbounded host the columns size themselves, so the title simply
    // stacks above them. A bounded host hands the columns the remaining height
    // through [Expanded], which keeps their independent scrolling intact.
    return Column(
      mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (widget.shrinkWrap) content else Expanded(child: content),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cascadingList.isEmpty) return const SizedBox.shrink();
    return _buildWithTitle(context, _buildColumns(context));
  }

  Widget _buildColumns(BuildContext context) {
    if (widget.isScrollable) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final row = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              _cascadingList.length,
              (cascadeIndex) => _buildColumn(
                cascadeIndex,
                _estimateCascadeColumnWidth(context, cascadeIndex),
              ),
            ),
          );
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(overscroll: false),
            child: SingleChildScrollView(
              controller: _cascadeHorizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: row,
            ),
          );
        },
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        _cascadingList.length,
        (cascadeIndex) => _buildColumn(cascadeIndex, null),
      ),
    );
  }
}
