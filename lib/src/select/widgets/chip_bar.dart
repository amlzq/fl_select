import 'package:flutter/material.dart';

import '../constants.dart';
import '../select_entry.dart';
import '../select_theme.dart';
import '../select_theme_data.dart';
import 'chip_bar_theme.dart';
import 'constants.dart';
import 'extensions.dart';
import 'field_tile.dart';
import 'field_tile_theme.dart';

/// Default height for [SelectChipBar].
const kSelectChipBarHeight = 44.0;

/// A horizontal chip bar for selecting among sibling [SelectEntry] entries.
///
/// Renders all [SelectEntry] subtypes as chips using their [SelectEntry.name]
/// as the label. This widget is commonly used as a "quick filter" row (e.g.
/// showing children of a selected entry). Selection state is provided by
/// [selectedEntries] and user interactions are reported via [onChanged].
///
/// A custom range entry (a [SelectRangeEntry] with the special id `custom`,
/// see [SelectRangeEntryExt.isCustom]) placed first or last in [entries] is
/// not rendered as a chip. Instead it is rendered as a min/max input field
/// above or below the chip group, mirroring [SelectGridView]. The committed
/// value is reported through [onChanged] once both fields lose focus.
///
/// This is the canonical render target for [SelectChipLayout].
class SelectChipBar extends StatefulWidget {
  const SelectChipBar({
    super.key,
    this.category,
    required this.entries,
    this.selectedEntries,
    this.selectionMode = SelectionMode.single,
    this.isWrapable = false,
    this.showTitle = true,
    this.direction = Axis.horizontal,
    this.spacing = 12,
    this.runSpacing = 12,
    this.backgroundColor,
    this.padding,
    this.variant,
    this.fieldVariant,
    this.chipColor,
    this.selectedChipColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.toText = '-',
    required this.onChanged,
  });

  /// The parent [SelectEntry] whose [SelectEntry.name] is displayed as the
  /// bar's title when [showTitle] is true.
  final SelectEntry? category;

  /// The sibling entries to display as chips in the bar.
  final List<SelectEntry> entries;

  /// The set of currently selected entries.
  ///
  /// Chips whose entry is contained in this set are rendered in the selected
  /// state. When null, no chip is considered selected.
  final SelectEntries? selectedEntries;

  /// How many chips can be selected at the same time.
  ///
  /// Defaults to [SelectionMode.single].
  final SelectionMode selectionMode;

  /// Whether the chip bar is wrapable.
  final bool isWrapable;

  /// Whether to show the category title.
  final bool showTitle;

  /// The direction of the [category] title relative to the chip group.
  ///
  /// Defaults to [Axis.horizontal], which lays the title to the left of the
  /// chips in a single row. Set to [Axis.vertical] to stack the title above
  /// the chip group.
  final Axis direction;

  /// Horizontal spacing between chips.
  ///
  /// When [isWrapable] is true this is the [Wrap.spacing] between chips in a
  /// row; otherwise it is the width of the separators between chips in the
  /// single-row [Row]. Defaults to 12.
  final double spacing;

  /// Vertical spacing between wrapped chip rows.
  ///
  /// Only used when [isWrapable] is true. Defaults to 12.
  final double runSpacing;

  /// The color of the chip bar's background.
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final Color? backgroundColor;

  /// The padding around the chip bar's contents.
  ///
  /// Defaults to [EdgeInsets.only] with a left inset of 12.0, or
  /// [EdgeInsets.zero] when [isWrapable] is true.
  final EdgeInsetsGeometry? padding;

  /// The visual style of the chips.
  ///
  /// See [SelectChipVariant] for the available styles. Defaults to
  /// [SelectChipVariant.filled].
  final SelectChipVariant? variant;

  /// The visual variant of the custom range input field, if [entries] contains
  /// a custom range entry.
  final SelectFieldTileVariant? fieldVariant;

  /// The color of an unselected chip.
  ///
  /// When [variant] is [SelectChipVariant.filled] this is used as the chip's
  /// background color; otherwise it is used as the chip's border color.
  final Color? chipColor;

  /// The color of a selected chip.
  ///
  /// When [variant] is [SelectChipVariant.filled] this is used as the chip's
  /// background color; otherwise it is used as the chip's border and label
  /// color.
  final Color? selectedChipColor;

  /// The text style for an unselected chip's [label].
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final TextStyle? labelStyle;

  /// The text style for a selected chip's [label].
  ///
  /// If null, the value from the surrounding [SelectChipBarTheme] or the
  /// default is used.
  final TextStyle? selectedLabelStyle;

  /// Text rendered between the two custom range input fields.
  ///
  /// Only used when [entries] contains a custom range entry. Defaults to `'-'`.
  final String toText;

  /// Called when the user taps a chip or commits the custom range input.
  ///
  /// The [index] of the tapped entry within [entries] and the tapped entry
  /// itself are passed to the callback.
  final OnChanged onChanged;

  @override
  State<SelectChipBar> createState() => _SelectChipBarState();
}

class _SelectChipBarState extends State<SelectChipBar> {
  SelectRangeEntry? _firstCustomEntry;
  SelectRangeEntry? _lastCustomEntry;

  TextEditingController? _minController;
  TextEditingController? _maxController;

  FocusNode? _minFocusNode;
  FocusNode? _maxFocusNode;

  late SelectEntries _selectedEntries;

  @override
  void initState() {
    super.initState();

    _selectedEntries = widget.selectedEntries ?? {};

    _firstCustomEntry = widget.entries.firstCustomOrNull;
    _lastCustomEntry = widget.entries.lastCustomOrNull;
    if (_firstCustomEntry != null || _lastCustomEntry != null) {
      _minController ??= TextEditingController();
      _maxController ??= TextEditingController();
      _minFocusNode ??= FocusNode();
      _maxFocusNode ??= FocusNode();
    }

    // Restore selection state for custom items.
    _restoreCustomSelectionToInputs();

    _minFocusNode?.addListener(_focusListener);
    _maxFocusNode?.addListener(_focusListener);
  }

  /// Whether [e] is this bar's own custom range entry.
  ///
  /// In a multi-category tree, every category shares the same level-1
  /// selection set and custom entries all use the same id (`custom`). We must
  /// therefore scope restoration to the entry owned by this bar's category
  /// ([widget.category].id) so a value committed in one category never leaks
  /// into another category's input fields.
  bool _isOwnCustom(SelectRangeEntry e) {
    final categoryId = widget.category?.id;
    if (categoryId == null) return e.isCustom;
    return e.isCustom && e.parentId == categoryId;
  }

  void _restoreCustomSelectionToInputs() {
    for (var selectedEntry in _selectedEntries) {
      if (selectedEntry is SelectRangeEntry && _isOwnCustom(selectedEntry)) {
        _minController?.text = selectedEntry.min?.toString() ?? '';
        _maxController?.text = selectedEntry.max?.toString() ?? '';
      }
    }
  }

  @override
  void didUpdateWidget(covariant SelectChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    _selectedEntries = widget.selectedEntries ?? {};

    _firstCustomEntry = widget.entries.firstCustomOrNull;
    _lastCustomEntry = widget.entries.lastCustomOrNull;
    if (_firstCustomEntry != null || _lastCustomEntry != null) {
      _minController ??= TextEditingController();
      _maxController ??= TextEditingController();
      _minFocusNode ??= FocusNode();
      _maxFocusNode ??= FocusNode();
    }

    // Restore selection state for custom items.
    _restoreCustomSelectionToInputs();

    // When the custom range was selected and is now removed (e.g. tapping a
    // preset or clicking reset), clear the input fields so stale values are not
    // left behind. We only react to this transition (not every rebuild) to
    // avoid clobbering text the user is actively typing.
    final oldHadCustom = (oldWidget.selectedEntries ?? {})
        .whereType<SelectRangeEntry>()
        .any(_isOwnCustom);
    final newHasCustom =
        _selectedEntries.whereType<SelectRangeEntry>().any(_isOwnCustom);
    if (oldHadCustom && !newHasCustom) {
      _clearAllInput();
      _unfocusAllInput();
    }
  }

  @override
  void dispose() {
    _minFocusNode?.removeListener(_focusListener);
    _maxFocusNode?.removeListener(_focusListener);

    _minController?.dispose();
    _maxController?.dispose();
    _minFocusNode?.dispose();
    _maxFocusNode?.dispose();

    super.dispose();
  }

  void _focusListener() {
    if (!(_minFocusNode?.hasFocus == true) &&
        !(_maxFocusNode?.hasFocus == true)) {
      _commitCustomRange(_firstCustomEntry);
      _commitCustomRange(_lastCustomEntry);
    }
  }

  /// Parses the current min/max input, normalizes it onto [custom], and
  /// notifies the listener via [SelectChipBar.onChanged].
  void _commitCustomRange(SelectRangeEntry? custom) {
    if (custom == null) return;
    final minText = _minController!.text;
    final maxText = _maxController!.text;
    var minInt = int.tryParse(minText) ?? 0;
    var maxInt = int.tryParse(maxText) ?? 0;
    // Only normalize an inverted range when both bounds have actually been
    // entered. Otherwise an empty field (parsed as 0) would spuriously trigger
    // a swap and push a freshly-typed min value into the max field (or clear
    // the min field), losing the user's input.
    final bothEntered = minText.isNotEmpty && maxText.isNotEmpty;
    final swapped = bothEntered && minInt > maxInt;
    if (swapped) {
      final temp = minInt;
      minInt = maxInt;
      maxInt = temp;
    }
    custom.min = (minInt == 0) ? null : minInt;
    custom.max = (maxInt == 0) ? null : maxInt;
    // Reflect the canonical (swapped) order back into the fields so the display
    // immediately shows "left small, right big" instead of the raw typed order.
    if (swapped) {
      _minController?.text = custom.min?.toString() ?? '';
      _maxController?.text = custom.max?.toString() ?? '';
    }
    final index = widget.entries.indexOf(custom);
    widget.onChanged(index, custom);
  }

  bool get inputNotEmpty =>
      (_minController?.text.isNotEmpty ?? false) ||
      (_maxController?.text.isNotEmpty ?? false);

  void _clearAllInput() {
    if (inputNotEmpty) {
      _minController?.clear();
      _maxController?.clear();
    }
  }

  bool get inputHasFocus =>
      (_minFocusNode?.hasFocus ?? false) || (_maxFocusNode?.hasFocus ?? false);

  void _unfocusAllInput() {
    if (inputHasFocus) {
      _minFocusNode?.unfocus();
      _maxFocusNode?.unfocus();
    }
  }

  void _onItemTap(int index, SelectEntry item) {
    // Clear custom input
    _clearAllInput();
    _unfocusAllInput();
    widget.onChanged(index, item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SelectChipBarTheme.of(context);

    final effectiveVariant =
        widget.variant ?? theme.variant ?? SelectChipVariant.filled;

    final defaults = _SelectChipBarDefaults(context, effectiveVariant);

    final effectiveBackgroundColor = widget.backgroundColor ??
        theme.backgroundColor ??
        defaults.backgroundColor!;

    final effectivePadding = widget.padding ??
        theme.padding ??
        (widget.isWrapable
            ? defaults.padding!
            : const EdgeInsets.only(left: 12));

    final effectiveChipColor =
        widget.chipColor ?? theme.chipColor ?? defaults.chipColor!;

    final effectiveSelectedChipColor = widget.selectedChipColor ??
        theme.selectedChipColor ??
        defaults.selectedChipColor!;

    final selectedTextColor = effectiveVariant == SelectChipVariant.filled
        ? (ThemeData.estimateBrightnessForColor(effectiveSelectedChipColor) ==
                Brightness.dark
            ? Colors.white
            : Colors.black)
        : effectiveSelectedChipColor;

    final effectiveLabelStyle =
        (widget.labelStyle ?? theme.labelStyle ?? defaults.labelStyle!)
            .copyWith(inherit: true);

    final effectiveSelectedLabelStyle = (widget.selectedLabelStyle ??
            theme.selectedLabelStyle ??
            defaults.selectedLabelStyle!)
        .copyWith(inherit: true, color: selectedTextColor);

    // Custom entries render as input fields, not chips; their original indexes
    // are preserved for the [onChanged] callback.
    final children = [
      for (final entry in widget.entries.asMap().entries)
        if (testNotCustomItem(entry.value))
          (() {
            final index = entry.key;
            final item = entry.value;
            final selected = _selectedEntries.contains(item);
            return _Chip(
              label: item.name ?? '',
              selected: selected,
              variant: effectiveVariant,
              color: effectiveChipColor,
              selectedColor: effectiveSelectedChipColor,
              labelStyle: effectiveLabelStyle,
              selectedLabelStyle: effectiveSelectedLabelStyle,
              enabled: item.enabled,
              onTap: () => _onItemTap(index, item),
            );
          })(),
    ];

    final chipGroup = widget.isWrapable
        ? Wrap(
            spacing: widget.spacing,
            runSpacing: widget.runSpacing,
            children: children,
          )
        : SingleChildScrollView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: children.separateWith(SizedBox(width: widget.spacing)),
            ),
          );

    // In vertical layout the title sits above the chip group, so the bar
    // height must grow to fit the chips rather than being fixed.
    final useVertical = widget.direction == Axis.vertical;
    final hasCustom = _firstCustomEntry != null || _lastCustomEntry != null;
    final isFixedHeight = !widget.isWrapable && !useVertical && !hasCustom;

    Widget content = useVertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category label
              if (widget.showTitle && widget.category?.name != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
              chipGroup,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category label
              if (widget.showTitle && widget.category?.name != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
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
              Expanded(child: chipGroup),
              const SizedBox(width: 12),
            ],
          );

    // A custom range entry renders as a min/max input field around the chip
    // group (header above, footer below), mirroring [SelectGridView].
    if (hasCustom) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // An input item at header
          if (_firstCustomEntry != null)
            SelectFieldTile(
              _firstCustomEntry!,
              padding: const EdgeInsets.only(bottom: 10.0),
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              variant: widget.fieldVariant,
              separator: widget.toText,
            ),
          content,
          // An input item at footer
          if (_lastCustomEntry != null)
            SelectFieldTile(
              _lastCustomEntry!,
              padding: const EdgeInsets.only(top: 10.0),
              minController: _minController,
              maxController: _maxController,
              minFocusNode: _minFocusNode,
              maxFocusNode: _maxFocusNode,
              variant: widget.fieldVariant,
              separator: widget.toText,
            ),
        ],
      );
    }

    return Container(
      height: isFixedHeight ? kSelectChipBarHeight : null,
      color: effectiveBackgroundColor,
      padding: effectivePadding,
      child: content,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.selected = false,
    required this.variant,
    required this.color,
    required this.selectedColor,
    required this.labelStyle,
    required this.selectedLabelStyle,
    this.enabled = true,
    required this.onTap,
  });

  final String label;

  final bool selected;

  final SelectChipVariant variant;

  final Color color;
  final Color selectedColor;

  final TextStyle labelStyle;
  final TextStyle selectedLabelStyle;

  final bool enabled;

  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? selected
            ? selectedColor
            : color
        : Colors.grey[500]!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: variant == SelectChipVariant.filled ? effectiveColor : null,
          border: variant == SelectChipVariant.filled
              ? null
              : Border.all(color: effectiveColor, width: 1.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: selected ? selectedLabelStyle : labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SelectChipBarDefaults extends SelectChipBarTheme {
  _SelectChipBarDefaults(
    this.context, [
    SelectChipVariant? variant,
  ]) : super(variant: variant);

  final BuildContext context;

  late final SelectThemeData _theme = SelectTheme.of(context);
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get backgroundColor => Colors.transparent;

  @override
  EdgeInsetsGeometry? get padding => EdgeInsets.zero;

  /// Default [chipColor] based on [variant].
  ///
  /// Mirrors [_SelectGridTileDefaults.tileColor]: a light tint derived from
  /// [SelectThemeData.onBackgroundColorHighest] toward white in light theme;
  /// blends surface colors for harmony in dark theme.
  @override
  Color? get chipColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      final blendAmount = variant == SelectChipVariant.outlined ? 0.2 : 0.35;
      return Color.lerp(
          _theme.backgroundColor, _theme.backgroundColorHighest, blendAmount);
    }
    if (variant == SelectChipVariant.outlined) {
      return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.55);
    }
    return Color.lerp(_theme.onBackgroundColorHighest, Colors.white, 0.8);
  }

  /// Default [selectedChipColor].
  ///
  /// Mirrors [_SelectGridTileDefaults.selectedTileColor]: blends with
  /// background in dark theme for a harmonious look.
  @override
  Color? get selectedChipColor {
    final baseSelected = _theme.selectedColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Color.lerp(_theme.backgroundColor, baseSelected, 0.35);
    }
    return baseSelected;
  }

  @override
  TextStyle? get labelStyle => _textTheme.labelLarge?.copyWith(
        color: _theme.onBackgroundColorHighest,
      );

  @override
  TextStyle? get selectedLabelStyle => _textTheme.labelLarge?.copyWith(
        color: _theme.onSelectedColor,
      );
}
