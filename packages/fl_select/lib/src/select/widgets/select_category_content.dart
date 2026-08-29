import 'package:flutter/material.dart';

import '../select_delegate.dart';
import '../select_entry.dart';
import '../select_layout.dart';
import 'widgets.dart';

/// Renders one category's children by mapping the resolved [SelectLayout]
/// (`category.layout ?? fallbackLayout`) to the matching select widget.
///
/// This is an internal building block shared by the two-level select bodies
/// (tab-nav, side-nav, expandable and the deprecated compatibility paths) so
/// the five layout flavors are mapped to widgets in exactly one place.
class SelectCategoryContentView extends StatelessWidget {
  /// Creates the content view for [category].
  const SelectCategoryContentView({
    super.key,
    required this.category,
    required this.index,
    required this.selectedEntries,
    required this.fallbackLayout,
    required this.delegate,
    required this.onTerminalItemTap,
    this.radioBuilder,
    this.checkboxBuilder,
    this.chipDirection,
  });

  /// The category whose children are rendered.
  final SelectCategoryEntry category;

  /// Index used for the [ValueKey] of the rendered content.
  final int index;

  /// The currently selected child entries, resolved by the host body
  /// (per-parent or per-level depending on the navigation metaphor).
  final Set<SelectEntry> selectedEntries;

  /// The layout used when [SelectCategoryEntry.layout] is null.
  final SelectLayout fallbackLayout;

  /// Carries the per-widget themes applied to the rendered content.
  final SelectDelegate delegate;

  /// Invoked when a child entry is tapped.
  final ValueChanged<SelectChildEntry> onTerminalItemTap;

  /// Optional custom radio/checkbox builders forwarded to the list branch.
  final ToggleWidgetBuilder? radioBuilder;
  final ToggleWidgetBuilder? checkboxBuilder;

  /// Overrides the chip bar direction; hosts that stack the category title
  /// above the chips (e.g. the side-nav right column) pass [Axis.vertical].
  final Axis? chipDirection;

  @override
  Widget build(BuildContext context) {
    final entries = category.children?.toList() ?? [];
    final layout = category.layout ?? fallbackLayout;

    return switch (layout) {
      SelectListLayout(:final toText) => SelectListView(
          key: ValueKey('category_$index'),
          category: category,
          showTitle: false,
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: (_, entry) => onTerminalItemTap(entry as SelectChildEntry),
          toText: toText,
          radioBuilder: radioBuilder,
          checkboxBuilder: checkboxBuilder,
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
          onChanged: (_, entry) => onTerminalItemTap(entry as SelectChildEntry),
          toText: toText,
        ),
      SelectWrapLayout(
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
          direction: chipDirection ?? Axis.horizontal,
          spacing: spacing,
          runSpacing: runSpacing,
          backgroundColor: delegate.chipBarTheme?.backgroundColor,
          padding: delegate.chipBarTheme?.padding,
          variant: delegate.chipBarTheme?.variant,
          chipColor: delegate.chipBarTheme?.chipColor,
          selectedChipColor: delegate.chipBarTheme?.selectedChipColor,
          labelStyle: delegate.chipBarTheme?.labelStyle,
          selectedLabelStyle: delegate.chipBarTheme?.selectedLabelStyle,
          onChanged: (_, item) => onTerminalItemTap(item as SelectChildEntry),
        ),
      SelectRangeLayout(:final toText) => SelectRangeView(
          key: ValueKey('category_$index'),
          category: category,
          showTitle: false,
          toText: toText,
          entries: entries,
          selectedEntries: selectedEntries,
          fieldVariant: delegate.fieldTileTheme?.variant,
          onChanged: (_, entry) => onTerminalItemTap(entry as SelectChildEntry),
        ),
      SelectCounterLayout() => SelectCounter(
          key: ValueKey('category_$index'),
          category: category,
          showTitle: false,
          entries: entries,
          selectedEntries: selectedEntries,
          onChanged: (_, entry) => onTerminalItemTap(entry as SelectChildEntry),
        ),
    };
  }
}
