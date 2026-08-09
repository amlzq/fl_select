import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

/// Where the select is rendered inside the simulated phone.
enum EntryPoint {
  view,
  popupBar,
  popupButton,
  dialog,
  bottomSheet,
}

/// Select delegate family.
enum Delegate {
  cascading,
  grid,
  flatten,
  list,
}

/// Visual style of grid / chip tiles.
enum TileVariant {
  filled,
  outlined,
}

/// Default [PlaygroundParams.crossAxisCount] per [Delegate]. Only the grid and
/// flatten delegates are column-based, so they get dedicated defaults (4 and 2
/// respectively); the others fall back to 4.
const Map<Delegate, int> defaultCrossAxisCountByDelegate = <Delegate, int>{
  Delegate.cascading: 4,
  Delegate.grid: 4,
  Delegate.flatten: 2,
  Delegate.list: 4,
};

/// Default [PlaygroundParams.childAspectRatio] per [Delegate]. Only the grid
/// and flatten delegates are column-based, so they get dedicated defaults
/// (2.5 and 2.8 respectively); the others fall back to 2.5.
const Map<Delegate, double> defaultChildAspectRatioByDelegate =
    <Delegate, double>{
  Delegate.cascading: 2.5,
  Delegate.grid: 2.5,
  Delegate.flatten: 3.0,
  Delegate.list: 2.5,
};

/// All tunable parameters of the interactive demo, held in a single immutable
/// value so the controls panel can replace it in one [setState] call.
class PlaygroundParams {
  final EntryPoint entryPoint;
  final Delegate delegate;
  final SelectionMode selectionMode;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final TileVariant tileVariant;
  final Color seedColor;
  final bool useMaterial3;

  /// Explicit brightness of the simulated phone preview. When `null`, the
  /// preview follows the app's resolved brightness (the [ThemeMode] set by the
  /// top-right button, including `system`). This keeps the independent-preview
  /// ability while allowing a one-click "follow app" sync.
  final Brightness? brightness;

  const PlaygroundParams({
    required this.entryPoint,
    required this.delegate,
    required this.selectionMode,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.spacing,
    required this.tileVariant,
    required this.seedColor,
    required this.useMaterial3,
    this.brightness,
  });

  PlaygroundParams copyWith({
    EntryPoint? entryPoint,
    Delegate? delegate,
    SelectionMode? selectionMode,
    int? crossAxisCount,
    double? childAspectRatio,
    double? spacing,
    TileVariant? tileVariant,
    Color? seedColor,
    bool? useMaterial3,
    Brightness? brightness,
    // Nullable fields need an explicit "clear" flag because `?? this.x` cannot
    // tell "not provided" apart from "provided as null".
    bool clearBrightness = false,
  }) {
    return PlaygroundParams(
      entryPoint: entryPoint ?? this.entryPoint,
      delegate: delegate ?? this.delegate,
      selectionMode: selectionMode ?? this.selectionMode,
      crossAxisCount: crossAxisCount ?? this.crossAxisCount,
      childAspectRatio: childAspectRatio ?? this.childAspectRatio,
      spacing: spacing ?? this.spacing,
      tileVariant: tileVariant ?? this.tileVariant,
      seedColor: seedColor ?? this.seedColor,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      brightness: clearBrightness ? null : (brightness ?? this.brightness),
    );
  }
}

/// Preset seed colors shown as swatches in the controls panel.
const List<Color> seedColorPresets = <Color>[
  Colors.deepPurple,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.red,
  Colors.pink,
  Colors.indigo,
];
