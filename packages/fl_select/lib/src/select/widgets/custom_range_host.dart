import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_entry.dart';
import 'field_tile.dart';
import 'field_tile_theme.dart';

/// Shared state machine for select views that render a custom range entry
/// (a [SelectRangeEntry] with the special id `custom`, see
/// [SelectRangeEntryExt.isCustom]) as a min/max input field ([SelectFieldTile])
/// at the header and/or footer of the view.
///
/// This mixin consolidates the logic previously duplicated across
/// `SelectChipBar`, `SelectGridView` and `SelectListView`:
///
/// * extracting the custom entry from the head/tail of [customRangeEntries]
///   (see [IterableExtension.firstCustomOrNull] / [lastCustomOrNull]),
/// * owning and disposing the min/max [TextEditingController]s and
///   [FocusNode]s,
/// * restoring a committed custom selection back into the fields,
/// * committing the input on focus loss (or submit), normalizing an inverted
///   range and syncing [SelectEntry.name],
/// * clearing the fields when the custom selection is removed elsewhere
///   (e.g. tapping a preset or reset), and
/// * scoping all of the above to the host category ([customRangeCategory]) so
///   a value committed in one category never leaks into another category's
///   fields.
///
/// Hosts hook the three lifecycle entry points from their [State.initState],
/// [State.didUpdateWidget] and [State.dispose] overrides:
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   initCustomRange();
/// }
///
/// @override
/// void didUpdateWidget(covariant MyWidget oldWidget) {
///   super.didUpdateWidget(oldWidget);
///   updateCustomRange(oldSelectedEntries: oldWidget.selectedEntries ?? {});
/// }
///
/// @override
/// void dispose() {
///   disposeCustomRange();
///   super.dispose();
/// }
/// ```
mixin CustomRangeHost<T extends StatefulWidget> on State<T> {
  SelectRangeEntry? _firstCustomEntry;
  SelectRangeEntry? _lastCustomEntry;

  TextEditingController? _minController;
  TextEditingController? _maxController;

  FocusNode? _minFocusNode;
  FocusNode? _maxFocusNode;

  /// The entries currently rendered by this host; the custom entry is looked
  /// up at the head/tail of this list.
  List<SelectEntry> get customRangeEntries;

  /// The category scoping this host's custom entry, or null.
  ///
  /// Only its `id` is read: in a multi-category tree, every category shares
  /// the same level-1 selection set and custom entries all use the same id
  /// (`custom`), so the category id is what keeps one category's committed
  /// range from leaking into another category's input fields.
  SelectEntry? get customRangeCategory;

  /// The currently selected entries; never null.
  SelectEntries get customRangeSelectedEntries;

  /// Text rendered between the two input fields.
  String get customRangeToText;

  /// Reports that [entry] at [index] was committed from the input fields.
  ///
  /// The min/max values have already been parsed and normalized onto [entry]
  /// before this is invoked, so the host only needs to update selection
  /// state (typically by forwarding to its `onChanged`).
  void notifyCustomRangeChanged(int index, SelectEntry entry);

  /// Whether [customRangeEntries] starts or ends with a custom range entry.
  bool get hasCustomRange =>
      _firstCustomEntry != null || _lastCustomEntry != null;

  /// The custom range entry at the head of [customRangeEntries], if any.
  SelectRangeEntry? get firstCustomRange => _firstCustomEntry;

  /// The custom range entry at the tail of [customRangeEntries], if any.
  SelectRangeEntry? get lastCustomRange => _lastCustomEntry;

  /// Re-reads the custom entries from [customRangeEntries], lazily creates the
  /// input controllers/focus nodes and restores the committed selection into
  /// the fields. Call once from [State.initState].
  void initCustomRange() {
    _syncCustomEntries();
    _restoreCustomSelectionToInputs();
  }

  /// Same as [initCustomRange], plus clears the fields when the custom
  /// selection was present in [oldSelectedEntries] but is gone now (e.g.
  /// tapping a preset or clicking reset). Call from [State.didUpdateWidget].
  ///
  /// Only that transition clears the fields — not every rebuild — to avoid
  /// clobbering text the user is actively typing.
  void updateCustomRange({required SelectEntries oldSelectedEntries}) {
    _syncCustomEntries();
    _restoreCustomSelectionToInputs();

    final oldHadCustom =
        oldSelectedEntries.whereType<SelectRangeEntry>().any(_isOwnCustom);
    final newHasCustom = customRangeSelectedEntries
        .whereType<SelectRangeEntry>()
        .any(_isOwnCustom);
    if (oldHadCustom && !newHasCustom) {
      clearCustomRangeInput();
    }
  }

  /// Releases the input controllers and focus nodes. Call from
  /// [State.dispose].
  void disposeCustomRange() {
    _minFocusNode?.removeListener(_focusListener);
    _maxFocusNode?.removeListener(_focusListener);

    _minController?.dispose();
    _maxController?.dispose();
    _minFocusNode?.dispose();
    _maxFocusNode?.dispose();
  }

  /// Clears both input fields and unfocuses them.
  ///
  /// Called when a regular entry is tapped (its selection replaces the custom
  /// range) or when the custom selection is removed elsewhere.
  void clearCustomRangeInput() {
    if (inputNotEmpty) {
      _minController?.clear();
      _maxController?.clear();
    }
    if (inputHasFocus) {
      _minFocusNode?.unfocus();
      _maxFocusNode?.unfocus();
    }
  }

  /// Builds the min/max [SelectFieldTile] for the custom entry at the head
  /// ([isHeader] true) or tail of [customRangeEntries].
  ///
  /// Pressing enter commits immediately instead of waiting for a focus loss
  /// (e.g. closing the panel without tapping outside).
  Widget buildCustomRangeFieldTile({
    required bool isHeader,
    EdgeInsetsGeometry? padding,
    SelectFieldTileVariant? variant,
  }) {
    final custom = isHeader ? _firstCustomEntry! : _lastCustomEntry!;
    return SelectFieldTile(
      custom,
      padding: padding,
      minController: _minController,
      maxController: _maxController,
      minFocusNode: _minFocusNode,
      maxFocusNode: _maxFocusNode,
      variant: variant,
      separator: customRangeToText,
      onMinSubmitted: (_) => _commitCustomRange(custom),
      onMaxSubmitted: (_) => _commitCustomRange(custom),
    );
  }

  bool get inputNotEmpty =>
      (_minController?.text.isNotEmpty ?? false) ||
      (_maxController?.text.isNotEmpty ?? false);

  bool get inputHasFocus =>
      (_minFocusNode?.hasFocus ?? false) || (_maxFocusNode?.hasFocus ?? false);

  void _syncCustomEntries() {
    _firstCustomEntry = customRangeEntries.firstCustomOrNull;
    _lastCustomEntry = customRangeEntries.lastCustomOrNull;
    if (hasCustomRange) {
      _ensureInput();
    }
  }

  /// Creates the controllers/focus nodes and attaches the focus listener once.
  void _ensureInput() {
    if (_minController != null) return;
    _minController = TextEditingController();
    _maxController = TextEditingController();
    _minFocusNode = FocusNode();
    _maxFocusNode = FocusNode();
    _minFocusNode!.addListener(_focusListener);
    _maxFocusNode!.addListener(_focusListener);
  }

  /// Whether [e] is this host's own custom range entry.
  bool _isOwnCustom(SelectRangeEntry e) {
    final categoryId = customRangeCategory?.id;
    if (categoryId == null) return e.isCustom;
    return e.isCustom && e.parentId == categoryId;
  }

  /// Writes the committed custom selection (if any) back into the fields.
  void _restoreCustomSelectionToInputs() {
    for (final selected in customRangeSelectedEntries) {
      if (selected is SelectRangeEntry && _isOwnCustom(selected)) {
        _minController?.text = selected.min?.toString() ?? '';
        _maxController?.text = selected.max?.toString() ?? '';
      }
    }
  }

  /// When both fields lose focus, commit the final normalized values.
  void _focusListener() {
    if (!(_minFocusNode?.hasFocus ?? false) &&
        !(_maxFocusNode?.hasFocus ?? false)) {
      _commitCustomRange(_firstCustomEntry);
      _commitCustomRange(_lastCustomEntry);
    }
  }

  /// Parses the current min/max input, normalizes it onto [custom], and
  /// notifies the host via [notifyCustomRangeChanged].
  void _commitCustomRange(SelectRangeEntry? custom) {
    if (custom == null) return;
    final minText = _minController!.text;
    final maxText = _maxController!.text;
    var minInt = int.tryParse(minText) ?? 0;
    var maxInt = int.tryParse(maxText) ?? 0;
    // Only normalize an inverted range when both bounds have actually been
    // entered. Otherwise an empty field (parsed as 0) would spuriously
    // trigger a swap and push a freshly-typed min value into the max field
    // (or clear the min field), losing the user's input.
    final bothEntered = minText.isNotEmpty && maxText.isNotEmpty;
    final swapped = bothEntered && minInt > maxInt;
    if (swapped) {
      final temp = minInt;
      minInt = maxInt;
      maxInt = temp;
    }
    custom.min = (minInt == 0) ? null : minInt;
    custom.max = (maxInt == 0) ? null : maxInt;
    // Keep the entry's name in sync with the committed range so downstream
    // consumers (e.g. the applied-result label on a popup trigger) show
    // "111-222" instead of a null name. Mirrors [SelectRangeView]'s slider
    // commit; safe because name is not part of == / hashCode.
    if (custom.hasCustomValue) {
      custom.name = '${custom.min ?? ''}$customRangeToText${custom.max ?? ''}';
    }
    // Reflect the canonical (swapped) order back into the fields so the
    // display immediately shows "left small, right big" instead of the raw
    // typed order.
    if (swapped) {
      _minController?.text = custom.min?.toString() ?? '';
      _maxController?.text = custom.max?.toString() ?? '';
    }
    final index = customRangeEntries.indexOf(custom);
    notifyCustomRangeChanged(index, custom);
  }
}
