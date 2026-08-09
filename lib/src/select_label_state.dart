import 'select/select_entry.dart';

/// Builds a custom label for a select / tab from the applied selection.
///
/// Receives only the [selected] entries. This is the canonical label-loader type
/// and is used by [PopupTabData.labelLoader] / [PopupTab.labelLoader] /
/// [PopupSelectButton.labelLoader].
typedef SelectLabelLoader = String Function(SelectEntries selected);

/// Tab-agnostic label / selection state shared by [PopupSelectBar]
/// (via [PopupTabData]) and [PopupSelectButton].
///
/// It carries only what both a single-trigger button and a multi-tab bar need:
/// an original (default) label, the currently displayed label, and whether a
/// result has been applied. Tab identity ([PopupTabData.index] /
/// [PopupTabData.tag]) lives exclusively in [PopupTabData].
class SelectLabelState {
  SelectLabelState({this.originalLabel, this.labelLoader});

  /// The default label shown before any result is applied.
  String? originalLabel;

  /// The label produced by the last applied result, if any.
  String? resultLabel;

  /// Optional custom label loader based on the current selection result.
  ///
  /// Receives only the selected entries; the canonical [SelectLabelLoader]
  /// form.
  SelectLabelLoader? labelLoader;

  /// The currently displayed label: the result label when one has been applied,
  /// otherwise the original label.
  String? get label => resultLabel ?? originalLabel;

  /// Whether the displayed label differs from the original (i.e. a result is active).
  bool get isResulted => originalLabel != label;

  /// The effective label loader applied to the current selection.
  SelectLabelLoader? get resolvedLabelLoader => labelLoader;

  @override
  String toString() =>
      'SelectLabelState(originalLabel: $originalLabel, resultLabel: $resultLabel)';
}
