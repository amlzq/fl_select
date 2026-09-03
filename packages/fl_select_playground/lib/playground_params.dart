import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

/// Where the select is rendered inside the simulated phone.
enum EntryPoint { view, bar, button, dialog, bottomSheet }

/// Select delegate family.
enum Delegate { list, grid, wrap, cascading, tabNav, sideNav, expandable }

/// Visual style of grid / chip tiles.
enum TileVariant { filled, outlined }

/// All tunable parameters of the interactive demo, held in a single immutable
/// value so the controls panel can replace it in one [setState] call.
class PlaygroundParams {
  final EntryPoint entryPoint;
  final Delegate delegate;
  final SelectionMode selectionMode;

  /// Geometry of [GridSelectDelegate]: column count, tile aspect ratio and
  /// the two gutters.
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  /// Geometry of [WrapSelectDelegate]: the chip gaps within a row and
  /// between rows.
  final double spacing;
  final double runSpacing;

  /// [CascadingSelectDelegate.isScrollable]: whether the cascading columns
  /// scroll horizontally instead of dividing the available width equally.
  final bool cascadingScrollable;

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

  /// [PopupSelectBar.isScrollable]: whether the bar's tabs scroll
  /// horizontally instead of dividing the available width equally.
  final bool isScrollable;

  /// [PopupSelectDirection] of the overlay opened by [PopupSelectBar] /
  /// [PopupSelectButton].
  final PopupSelectDirection direction;

  /// [PopupSelectButton.variant] when the entry point is
  /// [EntryPoint.button].
  final PopupSelectButtonVariant buttonVariant;

  /// [SelectDelegate.searchEnabled]: whether the select shows a search bar
  /// that filters the displayed entries (via `searchPredicate`).
  final bool searchEnabled;

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
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.spacing,
    required this.runSpacing,
    this.cascadingScrollable = false,
    required this.tileVariant,
    required this.seedColor,
    required this.useMaterial3,
    required this.isScrollable,
    required this.direction,
    required this.buttonVariant,
    this.searchEnabled = true,
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
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? spacing,
    double? runSpacing,
    bool? cascadingScrollable,
    TileVariant? tileVariant,
    Color? seedColor,
    bool? useMaterial3,
    bool? isScrollable,
    PopupSelectDirection? direction,
    PopupSelectButtonVariant? buttonVariant,
    bool? searchEnabled,
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
      crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
      spacing: spacing ?? this.spacing,
      runSpacing: runSpacing ?? this.runSpacing,
      cascadingScrollable: cascadingScrollable ?? this.cascadingScrollable,
      tileVariant: tileVariant ?? this.tileVariant,
      seedColor: seedColor ?? this.seedColor,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      isScrollable: isScrollable ?? this.isScrollable,
      direction: direction ?? this.direction,
      buttonVariant: buttonVariant ?? this.buttonVariant,
      searchEnabled: searchEnabled ?? this.searchEnabled,
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

  /// [SelectDelegate.searchEnabled] search-bar switch (every delegate).
  searchEnabled,

  /// Filled vs. outlined tiles (grid tiles / wrap chips only).
  tileVariant,

  /// [GridSelectDelegate.crossAxisCount].
  crossAxisCount,

  /// [GridSelectDelegate.childAspectRatio].
  childAspectRatio,

  /// [GridSelectDelegate.crossAxisSpacing].
  crossAxisSpacing,

  /// [GridSelectDelegate.mainAxisSpacing].
  mainAxisSpacing,

  /// [WrapSelectDelegate.spacing].
  spacing,

  /// [WrapSelectDelegate.runSpacing].
  runSpacing,

  /// [CascadingSelectDelegate.isScrollable].
  cascadingScrollable,

  /// Theme seed color swatches.
  seedColor,

  /// Light / dark brightness of the preview.
  brightness,

  /// Material 3 switch.
  useMaterial3,

  /// [PopupSelectBar.isScrollable].
  isScrollable,

  /// [PopupSelectDirection] of the bar / button overlay.
  direction,

  /// [PopupSelectButton.variant].
  buttonVariant,

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
/// - common (公共): controls shared by every entry point — selection mode and
///   the theme controls.
/// - entry-point private (私有): the bar exposes its own [PopupSelectBar]
///   parameters, the button its [PopupSelectButton] ones, and the dialog /
///   bottom sheet the header switches of `showSelect` / `showModalBottomSelect`.
/// - delegate private (私有): the delegate picker drives every entry point
///   except the bar (which renders all seven delegate families at once as
///   tabs); grid and wrap carry geometry parameters and consume a tile
///   variant, and cascading exposes its column scroll mode. The other
///   families hide the whole group.
///
/// Controls that the active combination does not support are hidden entirely
/// rather than disabled.
abstract final class PlaygroundControlSpec {
  const PlaygroundControlSpec._();

  /// Controls shared by every entry point, in panel display order.
  static const List<PlaygroundControl> commonControls = <PlaygroundControl>[
    PlaygroundControl.selectionMode,
    PlaygroundControl.searchEnabled,
    PlaygroundControl.brightness,
    PlaygroundControl.seedColor,
    PlaygroundControl.useMaterial3,
  ];

  /// Controls private to specific entry points, in panel display order.
  /// Entry points missing from this map expose the common controls only.
  static const Map<EntryPoint, List<PlaygroundControl>>
  entryPointPrivateControls = <EntryPoint, List<PlaygroundControl>>{
    // The bar renders one tab per delegate family, so there is no single
    // "active delegate" to tune; its own parameters take the slot instead.
    EntryPoint.bar: <PlaygroundControl>[
      PlaygroundControl.isScrollable,
      PlaygroundControl.direction,
    ],
    EntryPoint.button: <PlaygroundControl>[
      PlaygroundControl.buttonVariant,
      PlaygroundControl.direction,
    ],
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

  /// Controls private to specific delegates, in panel display order.
  /// Delegates missing from this map carry no private controls.
  static const Map<Delegate, List<PlaygroundControl>> delegatePrivateControls =
      <Delegate, List<PlaygroundControl>>{
        Delegate.grid: <PlaygroundControl>[
          PlaygroundControl.crossAxisCount,
          PlaygroundControl.childAspectRatio,
          PlaygroundControl.crossAxisSpacing,
          PlaygroundControl.mainAxisSpacing,
          PlaygroundControl.tileVariant,
        ],
        Delegate.wrap: <PlaygroundControl>[
          PlaygroundControl.spacing,
          PlaygroundControl.runSpacing,
          PlaygroundControl.tileVariant,
        ],
        Delegate.cascading: <PlaygroundControl>[
          PlaygroundControl.cascadingScrollable,
        ],
      };

  /// Whether the delegate picker drives the active entry point: every entry
  /// point but the bar opens a single select whose content is chosen by it.
  static bool isDelegateVisible(EntryPoint entryPoint) =>
      entryPoint != EntryPoint.bar;

  /// The full control list the panel renders for [params], in display order:
  /// entry-point private, then the delegate picker with the delegate private
  /// ones, then common.
  static List<PlaygroundControl> visibleControls(PlaygroundParams params) =>
      <PlaygroundControl>[
        ...?entryPointPrivateControls[params.entryPoint],
        if (isDelegateVisible(params.entryPoint)) ...<PlaygroundControl>[
          PlaygroundControl.delegate,
          ...?delegatePrivateControls[params.delegate],
        ],
        ...commonControls,
      ];
}
