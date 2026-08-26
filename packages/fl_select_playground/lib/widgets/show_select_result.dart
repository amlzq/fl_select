import 'dart:async';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

/// Debounce delay: consecutive calls within this duration cancel the previous
/// pending call so that only the **last** result is shown.
const Duration _resultDebounceInterval = Duration(seconds: 1);

Timer? _debounceTimer;

/// Shows a snack bar that displays the selected filter result.
///
/// Tapping the "view" action opens a bottom sheet with the flattened
/// [SelectEntries] result.
///
/// Calls are debounced by [debounceInterval]: intermediate calls cancel the
/// previous pending timer so that only the last result within the window is
/// actually displayed. This avoids stacking snack bars when [onChanged] fires
/// frequently.
void showSelectResult(
  BuildContext context,
  SelectEntries result, {
  Duration debounceInterval = _resultDebounceInterval,
}) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(debounceInterval, () {
    _debounceTimer = null;
    if (context.mounted) {
      _showSnackBar(context, result);
    }
  });
}

void _showSnackBar(BuildContext context, SelectEntries result) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('Selection updated'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            if (context.mounted) {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return SafeArea(
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: 0.8,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: SelectableText('Result: $result'),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
}
