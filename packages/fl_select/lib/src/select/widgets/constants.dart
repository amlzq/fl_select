import 'package:flutter/material.dart';

import '../select_entry.dart';

/// Generic callback invoked when an item in a select view changes.
///
/// [index] is the position of the affected item within the list and [entry] is
/// the corresponding data model. For custom range entries the view has already
/// parsed and normalized the min/max values onto [entry] before invoking this
/// callback, so the listener only needs to update selection state.
typedef OnChanged<T extends SelectEntry> = Function(int index, T entry);

/// Builds a custom toggle widget (radio/checkbox).
typedef ToggleWidgetBuilder = Widget Function(
    BuildContext context, bool selected);
