import 'package:flutter/material.dart';

import '../select_theme.dart';
import '../select_theme_data.dart';
import 'range_slider_theme.dart';

/// A custom-drawn dual-thumb range slider.
///
/// Unlike Material's [RangeSlider], this widget:
///
/// * does **not** render a tooltip / value indicator above the thumbs,
/// * does **not** paint tick marks on the track,
/// * renders two extreme-value labels ([minLabel] / [maxLabel]) at the bottom
///   corners (e.g. "$0" / "$20M+").
///
/// The widget is controlled: the parent provides [min], [max] and the current
/// [values]; updates are reported back through [onChanged] (while dragging,
/// snapped to the nearest division step when [divisions] is set) and
/// [onChangeEnd] (on release, with the final snap-to-step).
class SelectRangeSlider extends StatefulWidget {
  const SelectRangeSlider({
    super.key,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
    this.onChangeEnd,
    this.divisions,
    this.minLabel,
    this.maxLabel,
    this.selectedColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.thumbFillColor,
    this.trackHeight,
    this.thumbRadius,
  });

  /// Lower bound of the selectable range.
  final double min;

  /// Upper bound of the selectable range.
  final double max;

  /// Current selection. The widget treats [RangeValues.start] as the lower
  /// handle position and [RangeValues.end] as the upper handle position.
  final RangeValues values;

  /// Called when the user drags either thumb. Receives the new
  /// [RangeValues] (clamped, ordering preserved).
  final ValueChanged<RangeValues> onChanged;

  /// Called when the user releases the active thumb. When [divisions] is
  /// non-null, the values are quantized to the nearest step before being
  /// emitted.
  final ValueChanged<RangeValues>? onChangeEnd;

  /// Optional step count. When set, [onChangeEnd] snaps the released values
  /// to the nearest multiple of `(max - min) / divisions`. No tick marks are
  /// drawn on the track regardless of this value.
  final int? divisions;

  /// Text shown at the bottom-left of the slider (e.g. "$0").
  final String? minLabel;

  /// Text shown at the bottom-right of the slider (e.g. "$20M+").
  final String? maxLabel;

  /// Overrides the default accent color (used for the selected track segment
  /// and thumb border when the more specific colors are not provided).
  final Color? selectedColor;

  /// Overrides the color of the selected track segment.
  final Color? activeTrackColor;

  /// Overrides the color of the unselected track segments.
  final Color? inactiveTrackColor;

  /// Overrides the border color of the thumbs.
  final Color? thumbColor;

  /// Overrides the fill color of the thumbs.
  final Color? thumbFillColor;

  /// Overrides the track height in logical pixels.
  final double? trackHeight;

  /// Overrides the thumb radius in logical pixels.
  final double? thumbRadius;

  @override
  State<SelectRangeSlider> createState() => _SelectRangeSliderState();
}

class _SelectRangeSliderState extends State<SelectRangeSlider> {
  _ActiveThumb? _activeThumb;

  /// Effective thumb radius, cached from [build] so the pan handlers can use
  /// the same thumb-inset math as the layout code.
  double _thumbRadius = 10.0;

  /// Value of the active thumb when the current drag began.
  ///
  /// Used together with [_dragStartX] to derive the new value from the
  /// *absolute* pointer position rather than by accumulating incremental
  /// deltas. The latter approach stacked deltas on top of an already-snapped
  /// value, which made the handle feel sticky / resistant.
  double _dragStartValue = 0.0;

  /// Pointer x (within the slider's coordinate space) when the current drag
  /// began.
  double _dragStartX = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = SelectRangeSliderTheme.of(context);
    final defaults = _SelectRangeSliderDefaults(context);

    final effectiveTrackHeight =
        widget.trackHeight ?? theme.trackHeight ?? defaults.trackHeight ?? 4.0;
    final effectiveThumbRadius =
        widget.thumbRadius ?? theme.thumbRadius ?? defaults.thumbRadius ?? 10.0;
    _thumbRadius = effectiveThumbRadius;
    final effectiveActiveColor = widget.activeTrackColor ??
        theme.activeTrackColor ??
        widget.selectedColor ??
        theme.selectedColor ??
        defaults.selectedColor ??
        Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor = widget.inactiveTrackColor ??
        theme.inactiveTrackColor ??
        defaults.inactiveTrackColor ??
        Colors.grey.shade300;
    final effectiveThumbBorder =
        widget.thumbColor ?? theme.thumbColor ?? effectiveActiveColor;
    final effectiveThumbFill = widget.thumbFillColor ??
        theme.thumbFillColor ??
        defaults.thumbFillColor ??
        Colors.white;
    final effectiveEndLabelStyle =
        theme.endLabelStyle ?? defaults.endLabelStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Reserve enough width for both thumbs plus a small minimum
            // track segment so the active segment is always visible.
            final trackWidth = constraints.maxWidth;
            // Leave vertical room for a pressed thumb that scales up to 1.25x,
            // so it never clips.
            final areaHeight = effectiveThumbRadius * 2.5;

            final startX = _toPx(widget.values.start, trackWidth);
            final endX = _toPx(widget.values.end, trackWidth);
            final thumbDiameter = effectiveThumbRadius * 2;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _onPanStart(d.localPosition.dx, trackWidth),
              onPanUpdate: (d) => _onPanUpdate(d.localPosition.dx, trackWidth),
              onPanEnd: (_) => _onPanEnd(),
              onPanCancel: _clearActiveThumb,
              child: SizedBox(
                height: areaHeight,
                width: trackWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Inactive track (full width).
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (areaHeight - effectiveTrackHeight) / 2,
                      child: Container(
                        height: effectiveTrackHeight,
                        decoration: BoxDecoration(
                          color: effectiveInactiveColor,
                          borderRadius:
                              BorderRadius.circular(effectiveTrackHeight / 2),
                        ),
                      ),
                    ),
                    // Active track (between the two thumbs).
                    Positioned(
                      left: startX,
                      top: (areaHeight - effectiveTrackHeight) / 2,
                      width: (endX - startX).clamp(0.0, trackWidth),
                      child: Container(
                        height: effectiveTrackHeight,
                        decoration: BoxDecoration(
                          color: effectiveActiveColor,
                          borderRadius:
                              BorderRadius.circular(effectiveTrackHeight / 2),
                        ),
                      ),
                    ),
                    // Start thumb (scales to 1.25x while pressed).
                    Positioned(
                      left: startX - effectiveThumbRadius,
                      top: (areaHeight - thumbDiameter) / 2,
                      width: thumbDiameter,
                      height: thumbDiameter,
                      child: AnimatedScale(
                        scale: _activeThumb == _ActiveThumb.start ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: _Thumb(
                          fill: effectiveThumbFill,
                          border: effectiveThumbBorder,
                          highlighted: _activeThumb == _ActiveThumb.start,
                        ),
                      ),
                    ),
                    // End thumb (scales to 1.25x while pressed).
                    Positioned(
                      left: endX - effectiveThumbRadius,
                      top: (areaHeight - thumbDiameter) / 2,
                      width: thumbDiameter,
                      height: thumbDiameter,
                      child: AnimatedScale(
                        scale: _activeThumb == _ActiveThumb.end ? 1.25 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: _Thumb(
                          fill: effectiveThumbFill,
                          border: effectiveThumbBorder,
                          highlighted: _activeThumb == _ActiveThumb.end,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.minLabel != null || widget.maxLabel != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.minLabel != null)
                Text(
                  widget.minLabel!,
                  style: effectiveEndLabelStyle,
                )
              else
                const SizedBox.shrink(),
              if (widget.maxLabel != null)
                Text(
                  widget.maxLabel!,
                  style: effectiveEndLabelStyle,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ],
    );
  }

  double _toPx(double value, double trackWidth) {
    final range = widget.max - widget.min;
    if (range <= 0 || trackWidth <= 0) return 0;
    final usable = (trackWidth - _thumbRadius * 2).clamp(0.0, double.infinity);
    // Inset each handle by one thumb radius so that, at the extremes, the
    // handle's outer edge sits flush with the track's end (fully visible,
    // not hanging off the edge).
    return _thumbRadius +
        ((value - widget.min) / range).clamp(0.0, 1.0) * usable;
  }

  double _fromPx(double px, double trackWidth) {
    if (trackWidth <= 0) return widget.min;
    final range = widget.max - widget.min;
    final usable = (trackWidth - _thumbRadius * 2).clamp(0.0, double.infinity);
    final t = ((px - _thumbRadius) / usable).clamp(0.0, 1.0);
    return widget.min + t * range;
  }

  void _onPanStart(double localX, double trackWidth) {
    final startX = _toPx(widget.values.start, trackWidth);
    final endX = _toPx(widget.values.end, trackWidth);
    // Pick the closer thumb; break ties toward the start thumb.
    final dStart = (localX - startX).abs();
    final dEnd = (localX - endX).abs();
    final active = dStart <= dEnd ? _ActiveThumb.start : _ActiveThumb.end;
    // Anchor the drag at the active thumb's current value and the pointer
    // position, so subsequent moves are resolved from the absolute pointer
    // location (1:1 with the finger) instead of by stacking deltas.
    _dragStartX = localX;
    _dragStartValue =
        active == _ActiveThumb.start ? widget.values.start : widget.values.end;
    setState(() {
      _activeThumb = active;
    });
  }

  void _onPanUpdate(double localX, double trackWidth) {
    final active = _activeThumb;
    if (active == null) return;
    // Resolve the new value from the absolute pointer position relative to
    // where the drag started. Because the base is the *unsnapped* thumb value
    // at drag start (not an already-snapped, parent-fed value), the thumb
    // tracks the finger continuously and no movement is lost — eliminating the
    // previous sticky / resistant feel.
    final valueAtStart = _fromPx(_dragStartX, trackWidth);
    final valueAtCurrent = _fromPx(localX, trackWidth);
    var newValue = (_dragStartValue + (valueAtCurrent - valueAtStart))
        .clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    if (divisions != null && divisions > 0) {
      // Snap the dragged value to the nearest division step so the handle —
      // and the mirrored field value — move in discrete increments while
      // dragging, instead of only snapping on release.
      newValue = _snapOne(newValue, divisions);
    }
    final newStart =
        active == _ActiveThumb.start ? newValue : widget.values.start;
    final newEnd = active == _ActiveThumb.end ? newValue : widget.values.end;
    // Preserve ordering: when the active thumb crosses the other, the other
    // thumb follows so the user can "push" the range.
    if (newStart > newEnd) {
      widget.onChanged(RangeValues(newEnd, newStart));
    } else {
      widget.onChanged(RangeValues(newStart, newEnd));
    }
  }

  void _onPanEnd() {
    // Reset the pressed-thumb zoom (this triggers a rebuild via setState).
    _clearActiveThumb();
    final onChangeEnd = widget.onChangeEnd;
    if (onChangeEnd == null) return;
    final divisions = widget.divisions;
    if (divisions == null || divisions <= 0) {
      onChangeEnd(widget.values);
      return;
    }
    onChangeEnd(_snap(widget.values, divisions));
  }

  void _clearActiveThumb() {
    if (_activeThumb != null) {
      setState(() {
        _activeThumb = null;
      });
    }
  }

  RangeValues _snap(RangeValues v, int divisions) {
    return RangeValues(
      _snapOne(v.start, divisions),
      _snapOne(v.end, divisions),
    );
  }

  /// Quantizes a single value to the nearest division step.
  double _snapOne(double x, int divisions) {
    final range = widget.max - widget.min;
    if (range <= 0) return x;
    final step = range / divisions;
    final raw = (x - widget.min) / step;
    final rounded = raw.round();
    return (widget.min + rounded * step).clamp(widget.min, widget.max);
  }
}

enum _ActiveThumb { start, end }

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.fill,
    required this.border,
    required this.highlighted,
  });

  final Color fill;
  final Color border;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: highlighted ? 2.0 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Computes theme-aware default values for [SelectRangeSlider].
///
/// Mirrors the pattern used by [SelectGridTile] / [SelectFieldTile]:
/// fall back to Material brightness-aware colors when neither the widget
/// props nor the merged theme provide an explicit value.
class _SelectRangeSliderDefaults extends SelectRangeSliderTheme {
  _SelectRangeSliderDefaults(this.context);

  final BuildContext context;

  late final SelectThemeData _theme = SelectTheme.of(context);
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  TextStyle? get endLabelStyle => _textTheme.bodyMedium?.copyWith(
        color: _theme.onBackgroundColorHighest.withValues(alpha: 0.7),
      );

  @override
  Color? get selectedColor => _theme.selectedColor;

  @override
  Color? get activeTrackColor => _theme.selectedColor;

  @override
  Color? get thumbColor => _theme.selectedColor;

  @override
  Color? get thumbFillColor => Colors.white;

  @override
  Color? get inactiveTrackColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Color.lerp(
        _theme.backgroundColor,
        _theme.backgroundColorHighest,
        0.5,
      );
    }
    return Color.lerp(
      _theme.onBackgroundColorHighest,
      Colors.white,
      0.8,
    );
  }

  @override
  double? get trackHeight => 4.0;

  @override
  double? get thumbRadius => 10.0;
}
