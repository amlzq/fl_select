import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../select_entry.dart';
import '../select_theme.dart';
import 'constants.dart';

/// A spin-box counter for a single-valued [SelectCategoryEntry].
///
/// The [SelectCounter] renders a title (the category name) on the first row
/// and a [_SpinBox] on the second row. The spin box shows a `-` button on the
/// left, the current value in the middle, and a `+` button on the right. The
/// user increments / decrements through the category's child entries (e.g.
/// "Any", "1", "1+", "2", "2+", ...). At the two extremes, the corresponding
/// button is disabled.
///
/// This is the canonical render target for [SelectCounterLayout]: drop the
/// layout on a category that contains the value entries you want to step
/// through and you get a stepper out of the box. The "Any" entry (if present)
/// is always the left-most, zero value.
class SelectCounter extends StatefulWidget {
  const SelectCounter({
    super.key,
    this.category,
    required this.entries,
    this.selectedEntries,
    required this.onChanged,
    this.padding,
    this.showTitle = true,
    this.decrementIcon = Icons.remove,
    this.incrementIcon = Icons.add,
  });

  /// Whether to show the category's name as a title above the spin box.
  ///
  /// Defaults to true. Has no effect when [category] is null.
  final bool showTitle;

  /// The category that owns the layout; supplies the title text.
  ///
  /// When null, no title is rendered.
  final SelectCategoryEntry? category;

  /// The child entries to step through, in display order.
  ///
  /// A special "Any" entry ([SelectChildEntry.isAny]), when present, is pinned
  /// to the left-most (zero) position.
  final List<SelectEntry> entries;

  /// The set of currently selected entries. Used to restore the current
  /// position on first build and when the widget updates.
  final SelectEntries? selectedEntries;

  /// Called when the user taps `-` or `+`.
  ///
  /// Receives the position of the tapped value and the corresponding
  /// [SelectTextEntry]. The listener only needs to update selection state.
  final OnChanged<SelectTextEntry> onChanged;

  /// Padding around the whole view.
  final EdgeInsetsGeometry? padding;

  /// Icon shown on the left (decrement) button. Defaults to [Icons.remove].
  final IconData decrementIcon;

  /// Icon shown on the right (increment) button. Defaults to [Icons.add].
  final IconData incrementIcon;

  @override
  State<SelectCounter> createState() => _SelectCounterState();
}

class _SelectCounterState extends State<SelectCounter> {
  /// The ordered display items: the "Any" entry (if present) first, followed by
  /// the remaining child entries in their original order.
  late List<SelectTextEntry> _items;

  late SelectEntries _selectedEntries;

  /// Current position within [_items].
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _selectedEntries = widget.selectedEntries ?? {};
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant SelectCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedEntries = widget.selectedEntries ?? {};
    _rebuild();
  }

  void _rebuild() {
    final children = widget.entries.whereType<SelectTextEntry>().toList();
    final any = children.where((e) => e.isAny).firstOrNull;
    final others = children.where((e) => !e.isAny).toList();
    _items = [
      if (any != null) any,
      ...others,
    ];
    _index = _resolveIndex();
  }

  /// Maps the current selection to a position in [_items].
  ///
  /// Prefers the first selected item; falls back to the left-most ("Any")
  /// position when nothing is selected or the list is empty.
  int _resolveIndex() {
    for (var i = 0; i < _items.length; i++) {
      if (_selectedEntries.contains(_items[i])) return i;
    }
    return 0;
  }

  void _onSpinChanged(int index) {
    setState(() => _index = index);
    final entry = _items[index];
    widget.onChanged(index, entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SelectTheme.of(context);
    final showTitle = widget.showTitle && widget.category?.name != null;
    final labels = _items.map((e) => e.name ?? '').toList();

    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.category?.name ?? '',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          if (labels.isEmpty)
            const SizedBox.shrink()
          else
            _SpinBox(
              values: labels,
              index: _index,
              decrementIcon: widget.decrementIcon,
              incrementIcon: widget.incrementIcon,
              valueColor: _index == 0
                  ? theme.onBackgroundColorHighest
                  : theme.selectedColor,
              onChanged: _onSpinChanged,
            ),
        ],
      ),
    );
  }
}

/// A [- / +] stepper with the current value shown in the middle.
///
/// The left button decrements, the right button increments. When the current
/// position is at the left-most index the `-` button is disabled; when at the
/// right-most index the `+` button is disabled.
class _SpinBox extends StatelessWidget {
  const _SpinBox({
    required this.values,
    required this.index,
    required this.onChanged,
    required this.valueColor,
    this.decrementIcon = Icons.remove,
    this.incrementIcon = Icons.add,
  });

  /// The ordered display labels, one per position.
  final List<String> values;

  /// The current position (must be within [0, values.length - 1]).
  final int index;

  /// Called with the new position when the user taps `-` or `+`.
  final ValueChanged<int> onChanged;

  /// The text color used for the middle value.
  final Color valueColor;

  final IconData decrementIcon;
  final IconData incrementIcon;

  @override
  Widget build(BuildContext context) {
    final canDecrement = index > 0;
    final canIncrement = index < values.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: canDecrement ? () => onChanged(index - 1) : null,
          icon: Icon(decrementIcon),
          tooltip: 'Decrease',
        ),
        Expanded(
          child: Text(
            values[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
        IconButton.filled(
          onPressed: canIncrement ? () => onChanged(index + 1) : null,
          icon: Icon(incrementIcon),
          tooltip: 'Increase',
        ),
      ],
    );
  }
}
