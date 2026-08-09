import 'package:flutter/material.dart';

import '../select_entry.dart';
import 'constants.dart';
import 'field_tile.dart';
import 'field_tile_theme.dart';
import 'range_slider.dart';

/// A composite view that renders a [SelectRangeSlider] above a
/// [SelectFieldTile], keeping both in sync with a single source of truth.
///
/// This is the canonical render target for
/// [SelectRangeLayout] — drop the layout on a category that contains
/// a custom [SelectRangeEntry] and you get a "price-range" style control
/// out of the box:
///
/// * The slider is the primary input.
/// * The two text fields mirror the slider state and remain editable for
///   precise input.
/// * When a handle touches an extreme ([min] / [max]) the corresponding
///   field shows the entry's `minHintText` / `maxHintText` as a placeholder.
class SelectRangeView extends StatefulWidget {
  const SelectRangeView({
    super.key,
    this.category,
    required this.entries,
    this.selectedEntries,
    required this.onChanged,
    this.minController,
    this.maxController,
    this.minFocusNode,
    this.maxFocusNode,
    this.padding,
    this.showTitle = true,
    this.toText = '-',
    this.fieldVariant,
  });

  /// Whether to show the category's name as a title above the slider.
  ///
  /// Defaults to true. Has no effect when [category] is null.
  final bool showTitle;

  /// The category that owns the layout; supplies the [SelectRangeEntry]
  /// to render via [SelectCategoryEntryExtension.firstCustomOrNull].
  ///
  /// When null, the view falls back to [entries] to locate a custom
  /// [SelectRangeEntry].
  final SelectCategoryEntry? category;

  /// The full child-entry list, used as a fallback to locate a custom
  /// [SelectRangeEntry] when [category] does not provide one.
  final List<SelectEntry> entries;

  /// The set of currently selected entries. Used to restore the custom
  /// entry's previous min/max on first build.
  final SelectEntries? selectedEntries;

  /// Called when the range changes. The view has already normalized the
  /// current start/end onto the custom [SelectRangeEntry] (writing `null`
  /// for bounds that sit at the slider's extremes) before invoking this
  /// callback, so the listener only needs to update selection state.
  final OnChanged onChanged;

  /// Optional external controller for the min text field.
  final TextEditingController? minController;

  /// Optional external controller for the max text field.
  final TextEditingController? maxController;

  /// Optional external focus node for the min text field.
  final FocusNode? minFocusNode;

  /// Optional external focus node for the max text field.
  final FocusNode? maxFocusNode;

  /// Padding around the whole view.
  final EdgeInsetsGeometry? padding;

  /// Text rendered between the two text fields (default: `'-'`).
  final String toText;

  /// The visual variant applied to the two [SelectFieldTile]s below the
  /// slider. When `null` (the default), each field tile uses the variant
  /// resolved from the select's theme (see
  /// [FieldTileThemeResolver]).
  final SelectFieldTileVariant? fieldVariant;

  @override
  State<SelectRangeView> createState() => _SelectRangeViewState();
}

class _SelectRangeViewState extends State<SelectRangeView> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late FocusNode _minFocusNode;
  late FocusNode _maxFocusNode;

  // Range bounds. The entry may carry N as int or double; we treat all
  // numerics uniformly as `num` and project to `double` for the slider.
  double _min = 0;
  double _max = 1;
  int? _divisions;
  num? _initialMin;
  num? _initialMax;

  // Display labels for the slider's bottom corners. When the range entry
  // carries a `name` of the form "minText-maxText" (e.g. "$1,500-$10M+"),
  // the two segments become [SelectRangeSlider.minLabel] / [maxLabel].
  // Otherwise they fall back to the numeric extremes.
  String? _minLabel;
  String? _maxLabel;

  /// Whether the underlying entry is integral (both bounds are `int`, e.g.
  /// a [SelectIntEntry]). When true, slider/field values are snapped to
  /// whole numbers and never exposed as floating-point text.
  bool _isInt = false;

  // Live state.
  late RangeValues _currentRange;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _minController = widget.minController ?? TextEditingController();
    _maxController = widget.maxController ?? TextEditingController();
    _minFocusNode = widget.minFocusNode ?? FocusNode();
    _maxFocusNode = widget.maxFocusNode ?? FocusNode();
    // Commit a field when it loses focus, so tapping away also finalizes the
    // value (the slider only updates on commit, never mid-typing).
    _minFocusNode.addListener(_onMinFocusChanged);
    _maxFocusNode.addListener(_onMaxFocusChanged);
    _loadEntry();
    // Restore the previously selected range from [selectedEntries] when the
    // custom entry carries a saved min/max; otherwise start at the full
    // slider bounds.
    _currentRange = _restoreFromSelected() ??
        RangeValues(
          _toDouble(_initialMin) ?? _min,
          _toDouble(_initialMax) ?? _max,
        );
    _initialized = true;
    _syncControllersFromRange(force: true);
  }

  @override
  void didUpdateWidget(covariant SelectRangeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The slider bounds (_min / _max / divisions / hints) are fixed for the
    // lifetime of this view and loaded once in [initState]. Re-reading them
    // here from the (original) category entry would revert the user's edits
    // back to the extremes and wipe the text fields on every parent rebuild
    // — every edit emits through [focusListener], which rebuilds the parent
    // and re-invokes this method. The bounds never change in response to
    // user input, so there is nothing to reconcile here.
    //
    // We only react to two explicit transitions:
    //   * selection first becomes available (data loaded after the first
    //     build) — restore the last-selected range onto the slider/fields;
    //   * the custom range is deselected — clear the fields back to their
    //     empty (extreme) placeholders.
    // During ordinary edits both old and new carry a custom entry, so neither
    // branch runs and the user's in-progress input is never clobbered.
    final oldHadCustom = (oldWidget.selectedEntries ?? const <SelectEntry>{})
        .any((e) => e is SelectRangeEntry && e.isCustom);
    final newHasCustom = (widget.selectedEntries ?? const <SelectEntry>{})
        .any((e) => e is SelectRangeEntry && e.isCustom);
    if (!oldHadCustom && newHasCustom) {
      final restored = _restoreFromSelected();
      if (restored != null) {
        _currentRange = restored;
        _syncControllersFromRange(force: true);
      }
    } else if (oldHadCustom && !newHasCustom) {
      _currentRange = RangeValues(_min, _max);
      _minController.clear();
      _maxController.clear();
    }
  }

  @override
  void dispose() {
    _minFocusNode.removeListener(_onMinFocusChanged);
    _maxFocusNode.removeListener(_onMaxFocusChanged);
    if (widget.minController == null) _minController.dispose();
    if (widget.maxController == null) _maxController.dispose();
    if (widget.minFocusNode == null) _minFocusNode.dispose();
    if (widget.maxFocusNode == null) _maxFocusNode.dispose();
    super.dispose();
  }

  void _loadEntry() {
    // The slider bounds come from the range entry (the non-custom
    // [SelectRangeEntry] in the category's children), while the field tile
    // and the emitted value come from the custom entry. If no range entry is
    // found, fall back to a degenerate 0..1 range so the slider still renders
    // safely.
    final rangeEntry = _findRangeEntry();
    if (rangeEntry == null) {
      _min = 0;
      _max = 1;
      _divisions = null;
      _initialMin = null;
      _initialMax = null;
      _minLabel = null;
      _maxLabel = null;
      return;
    }
    // Read N values as num.
    _min = _toDouble(rangeEntry.min) ?? 0;
    _max = _toDouble(rangeEntry.max) ?? (_min + 1);
    if (_max <= _min) _max = _min + 1;
    _divisions = rangeEntry.divisions;
    _initialMin = rangeEntry.min;
    _initialMax = rangeEntry.max;
    // Treat the range as integral when both bounds are integers (e.g. a
    // SelectIntEntry); the slider then snaps the displayed/returned value
    // to whole numbers instead of exposing floating-point text.
    _isInt = rangeEntry.min is int && rangeEntry.max is int;
    // Parse the entry's display label (e.g. "$1,500-$10M+") into the two
    // segments used by the slider's bottom corners. If the name does not
    // contain a '-' separator, the labels stay null and the numeric bounds
    // are shown instead.
    final name = rangeEntry.name;
    if (name != null) {
      final dash = name.indexOf('-');
      if (dash > 0 && dash < name.length - 1) {
        _minLabel = name.substring(0, dash).trim();
        _maxLabel = name.substring(dash + 1).trim();
      } else {
        _minLabel = null;
        _maxLabel = null;
      }
    } else {
      _minLabel = null;
      _maxLabel = null;
    }
  }

  /// Restores the last-selected range from the custom entry carried in
  /// [selectedEntries].
  ///
  /// When the user previously set a range and that selection is still present,
  /// the slider and text fields should reopen at those values instead of
  /// starting from the full bounds. Returns `null` when no custom entry with a
  /// saved value is found, letting the caller fall back to the extremes.
  ///
  /// A `null` bound on the custom entry means that end was left at its extreme,
  /// so it is projected back to the corresponding slider bound here.
  RangeValues? _restoreFromSelected() {
    for (final e in widget.selectedEntries ?? const <SelectEntry>{}) {
      if (e is SelectRangeEntry && e.isCustom) {
        final start = (_toDouble(e.min) ?? _min).clamp(_min, _max).toDouble();
        final end = (_toDouble(e.max) ?? _max).clamp(_min, _max).toDouble();
        return RangeValues(start, end);
      }
    }
    return null;
  }

  /// Locates the range entry that defines the slider bounds: a
  /// [SelectRangeEntry] in the category's children that is **not** custom.
  ///
  /// In the canonical `SelectRangeLayout` arrangement each category owns two
  /// entries — a range entry (bounds for the slider) and a custom entry
  /// (user input, rendered as the field tile). We prefer the category's
  /// non-custom range entry and fall back to scanning [entries].
  SelectRangeEntry? _findRangeEntry() {
    final children = widget.category?.children ?? widget.entries;
    for (final e in children) {
      if (e is SelectRangeEntry && !e.isCustom) return e;
    }
    return null;
  }

  /// Locates the custom entry that owns the field-tile display and is the
  /// sole target of [onChanged].
  SelectRangeEntry? _findEntry() {
    final fromCategory = widget.category?.firstCustomOrNull;
    if (fromCategory != null) return fromCategory;
    for (final e in widget.entries) {
      if (e is SelectRangeEntry && e.isCustom) return e;
    }
    return null;
  }

  void _onSliderChanged(RangeValues newRange) {
    setState(() {
      _currentRange = _roundRange(newRange);
    });
    _syncControllersFromRange();
  }

  void _onSliderChangeEnd(RangeValues newRange) {
    setState(() {
      _currentRange = _roundRange(newRange);
    });
    _syncControllersFromRange(force: true);
    _emit(newRange);
  }

  void _onFieldDraftChanged(String text) {
    // The typed text is buffered in the field's controller while the user
    // types. We deliberately do NOT push it to the slider here — the slider
    // only updates once the edit is committed (see [_commitField]), so it does
    // not jump around mid-typing.
  }

  void _onMinFocusChanged() {
    if (!mounted) return;
    if (!_minFocusNode.hasFocus) _commitField(true, _minController.text);
  }

  void _onMaxFocusChanged() {
    if (!mounted) return;
    if (!_maxFocusNode.hasFocus) _commitField(false, _maxController.text);
  }

  /// Finalizes the value of one field. Called when the field is submitted
  /// (e.g. "done") or loses focus. This is the *only* path that updates the
  /// [SelectRangeSlider] from the text fields.
  void _commitField(bool isMin, String text) {
    final parsed = _parseNum(text);
    if (parsed == null) {
      // Empty / invalid input: revert the field to the canonical range value
      // so a half-typed or cleared field never sticks on screen.
      _syncControllersFromRange(force: true);
      return;
    }
    final clamped = parsed.clamp(_min, _max).toDouble();
    final value = _isInt ? clamped.roundToDouble() : clamped;

    final rawStart = isMin ? value : _currentRange.start;
    final rawEnd = isMin ? _currentRange.end : value;
    // Keep the two bounds ordered: if the edited bound lands on the wrong side
    // of the other, swap them so the user can never produce an inverted range
    // (e.g. typing a smaller value into the max field auto-swaps the two).
    final newRange = rawStart <= rawEnd
        ? RangeValues(rawStart, rawEnd)
        : RangeValues(rawEnd, rawStart);

    if (newRange != _currentRange) {
      setState(() {
        _currentRange = newRange;
      });
      _emit(newRange);
    }
    // Always re-sync so both fields reflect the canonical (snapped / swapped)
    // value now that editing is done.
    _syncControllersFromRange(force: true);
  }

  void _syncControllersFromRange({bool force = false}) {
    final minText = _format(_currentRange.start, atExtreme: _atMinExtreme);
    final maxText = _format(_currentRange.end, atExtreme: _atMaxExtreme);
    if (force || _minController.text != minText) {
      _minController.value = TextEditingValue(
        text: minText,
        selection: TextSelection.collapsed(offset: minText.length),
      );
    }
    if (force || _maxController.text != maxText) {
      _maxController.value = TextEditingValue(
        text: maxText,
        selection: TextSelection.collapsed(offset: maxText.length),
      );
    }
  }

  void _emit(RangeValues range) {
    final entry = _findEntry();
    if (entry == null) return;
    final atMin = range.start <= _min + _epsilon;
    final atMax = range.end >= _max - _epsilon;
    entry.min = atMin ? null : _toEntryValue(range.start);
    entry.max = atMax ? null : _toEntryValue(range.end);
    entry.name = '${entry.min}-${entry.max}';
    final index = widget.entries.indexOf(entry);
    widget.onChanged.call(index < 0 ? 0 : index, entry);
  }

  /// Projects a slider value to the entry's native numeric type (int when the
  /// range is integral, otherwise double).
  Object _toEntryValue(double v) => _isInt ? v.round() : v;

  RangeValues _roundRange(RangeValues r) {
    if (!_isInt) return r;
    return RangeValues(
      r.start.roundToDouble().clamp(_min, _max),
      r.end.roundToDouble().clamp(_min, _max),
    );
  }

  bool get _atMinExtreme => _currentRange.start <= _min + _epsilon;
  bool get _atMaxExtreme => _currentRange.end >= _max - _epsilon;
  static const double _epsilon = 1e-9;

  String _format(double v, {required bool atExtreme}) {
    if (atExtreme) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  /// Formats an extreme bound (min/max) for the slider's bottom labels.
  ///
  /// Unlike [_format], this always renders the numeric value — even at the
  /// extremes — because the labels are meant to display the range bounds
  /// (e.g. "0" / "2000000"), while the text fields show their placeholders
  /// at the extremes.
  String _formatBound(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  num? _parseNum(String text) {
    if (text.isEmpty) return null;
    final cleaned = text.replaceAll(',', '').replaceAll(RegExp(r'\s+'), '');
    return num.tryParse(cleaned);
  }

  double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return num.tryParse(value.toString())?.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.shrink();
    }
    final entry = _findEntry();
    final showTitle = widget.showTitle && widget.category?.name != null;
    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                child: Text(widget.category?.name ?? ''),
              ),
            ),
          SelectRangeSlider(
            min: _min,
            max: _max,
            values: _currentRange,
            divisions: _divisions,
            // Show the parsed display labels at the bottom corners of the
            // slider (e.g. "$1,500" / "$10M+"). When the entry name does not
            // provide them, fall back to the numeric extremes.
            minLabel: _minLabel ?? _formatBound(_min),
            maxLabel: _maxLabel ?? _formatBound(_max),
            onChanged: _onSliderChanged,
            onChangeEnd: _onSliderChangeEnd,
          ),
          const SizedBox(height: 12),
          // Reuse [SelectFieldTile] for the two text fields. It owns the
          // visual treatment; the change/submit callbacks wire the deferred
          // slider sync (see [_commitField]).
          if (entry != null)
            SelectFieldTile(
              entry,
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              separator: widget.toText,
              variant: widget.fieldVariant,
              // The range view accepts fractional input while typing and
              // rounds/snaps on commit (see [_commitField]).
              allowDecimal: true,
              onMinChanged: _onFieldDraftChanged,
              onMaxChanged: _onFieldDraftChanged,
              onMinSubmitted: (text) => _commitField(true, text),
              onMaxSubmitted: (text) => _commitField(false, text),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
