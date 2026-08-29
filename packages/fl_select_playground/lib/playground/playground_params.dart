import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

/// Where the select is rendered inside the simulated phone.
enum EntryPoint { view, popupBar, popupButton, dialog, bottomSheet }

/// Select delegate family.
enum Delegate { list, grid, wrap, cascading, tabNav, sideNav, expandable }

/// Visual style of grid / chip tiles.
enum TileVariant { filled, outlined }

/// Default [PlaygroundParams.crossAxisCount] per [Delegate]. Only the
/// column-based delegates own the value (see [PlaygroundControlSpec.
/// isColumnBased]): grid defaults to 4 columns, sideNav to 2 (the side bar
/// takes width), tabNav / expandable to 3 (the library's tab-nav default);
/// the others fall back to 4.
const Map<Delegate, int> defaultCrossAxisCountByDelegate = <Delegate, int>{
  Delegate.list: 4,
  Delegate.grid: 4,
  Delegate.wrap: 4,
  Delegate.cascading: 4,
  Delegate.tabNav: 3,
  Delegate.sideNav: 2,
  Delegate.expandable: 3,
};

/// Default [PlaygroundParams.childAspectRatio] per [Delegate]. Only the
/// column-based delegates own the value; sideNav pairs its 2-column grid
/// with shorter tiles (3.0), the others fall back to 2.5.
const Map<Delegate, double> defaultChildAspectRatioByDelegate =
    <Delegate, double>{
      Delegate.list: 2.5,
      Delegate.grid: 2.5,
      Delegate.wrap: 2.5,
      Delegate.cascading: 2.5,
      Delegate.tabNav: 2.5,
      Delegate.sideNav: 3.0,
      Delegate.expandable: 2.5,
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

  /// Whether the [showSelect] / [showModalBottomSelect] header shows a sample
  /// leading widget (close icon).
  final bool headerLeading;

  /// Whether the [showSelect] / [showModalBottomSelect] header shows a sample
  /// trailing widget (confirm icon).
  final bool headerTrailing;

  /// Explicit [SelectHeader.centerTitle] for [showSelect] /
  /// [showModalBottomSelect].
  final bool centerTitle;

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
    this.headerLeading = false,
    this.headerTrailing = false,
    this.centerTitle = true,
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
    bool? headerLeading,
    bool? headerTrailing,
    bool? centerTitle,
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
      headerLeading: headerLeading ?? this.headerLeading,
      headerTrailing: headerTrailing ?? this.headerTrailing,
      centerTitle: centerTitle ?? this.centerTitle,
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

/// One tunable control exposed by the playground controls panel.
enum PlaygroundControl {
  /// Inline delegate family picker.
  delegate,

  /// Single vs. multiple selection.
  selectionMode,

  /// Filled vs. outlined tiles.
  tileVariant,

  /// Grid column count.
  crossAxisCount,

  /// Grid tile aspect ratio.
  childAspectRatio,

  /// Grid gutter between tiles.
  spacing,

  /// Theme seed color swatches.
  seedColor,

  /// Light / dark brightness of the preview.
  brightness,

  /// Material 3 switch.
  useMaterial3,

  /// Header leading widget switch (Dialog / Bottom Sheet only).
  headerLeading,

  /// Header trailing widget switch (Dialog / Bottom Sheet only).
  headerTrailing,

  /// Header center-title switch (Dialog / Bottom Sheet only).
  headerCenterTitle,
}

/// Declares which [PlaygroundControl]s the controls panel shows, scoped along
/// two axes:
///
/// - common (公共): controls shared by every entry point — selection mode,
///   tile variant and the theme controls.
/// - entry-point private (私有): the delegate picker only drives the inline
///   [SelectView]; the popup / dialog entry points render all four delegate
///   families at once with their own per-family defaults.
/// - delegate private (私有): the grid geometry sliders (Columns / Aspect
///   Ratio) belong to the column-based delegates only — [Delegate.grid] and
///   the two-level delegates ([Delegate.tabNav], [Delegate.sideNav],
///   [Delegate.expandable]). The others carry no such parameters, so the
///   sliders hide while they are active.
abstract final class PlaygroundControlSpec {
  const PlaygroundControlSpec._();

  /// Controls shared by every entry point, in panel display order.
  static const List<PlaygroundControl> commonControls = <PlaygroundControl>[
    PlaygroundControl.selectionMode,
    PlaygroundControl.tileVariant,
    PlaygroundControl.brightness,
    PlaygroundControl.seedColor,
    PlaygroundControl.useMaterial3,
  ];

  /// Controls private to specific entry points, in panel display order.
  /// Entry points missing from this map expose the common controls only.
  static const Map<EntryPoint, List<PlaygroundControl>>
  entryPointPrivateControls = <EntryPoint, List<PlaygroundControl>>{
    EntryPoint.view: <PlaygroundControl>[PlaygroundControl.delegate],
    // The dialog / bottom sheet entry points additionally expose the header
    // (leading / trailing / centerTitle) parameters of showSelect /
    // showModalBottomSelect.
    EntryPoint.dialog: <PlaygroundControl>[
      PlaygroundControl.headerLeading,
      PlaygroundControl.headerTrailing,
      PlaygroundControl.headerCenterTitle,
    ],
    EntryPoint.bottomSheet: <PlaygroundControl>[
      PlaygroundControl.headerLeading,
      PlaygroundControl.headerTrailing,
      PlaygroundControl.headerCenterTitle,
    ],
  };

  /// Controls private to the column-based delegates, in panel display order.
  static const List<PlaygroundControl> columnBasedDelegateControls =
      <PlaygroundControl>[
        PlaygroundControl.crossAxisCount,
        PlaygroundControl.childAspectRatio,
      ];

  /// Whether [delegate] renders a column-based grid that owns the
  /// Columns / Aspect Ratio / Spacing parameters.
  static bool isColumnBased(Delegate delegate) =>
      delegate == Delegate.grid ||
      delegate == Delegate.tabNav ||
      delegate == Delegate.sideNav ||
      delegate == Delegate.expandable;

  /// Whether the Columns / Aspect Ratio sliders take effect: they only drive
  /// the inline view's column-based delegate (the popup / dialog entry points
  /// pin per-family defaults instead).
  static bool isGeometryActive(PlaygroundParams params) =>
      params.entryPoint == EntryPoint.view && isColumnBased(params.delegate);

  /// Whether the spacing slider takes effect: every non-view entry point
  /// embeds grid-family samples that read it, while the inline view limits it
  /// to the column-based delegates.
  static bool isSpacingActive(PlaygroundParams params) =>
      params.entryPoint != EntryPoint.view || isColumnBased(params.delegate);
}
