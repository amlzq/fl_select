import 'package:material_ui/material_ui.dart';

import 'playground_l10n.dart';

/// Footer panel that shows the most recent `onChanged` / `onApplied` values
/// for the active entry point.
///
/// A snackbar-style action button in the header toggles the panel: tapping it
/// expands the panel upwards over most of the body so long values stay
/// readable; tapping again collapses it back to the compact strip.
class ResultPanel extends StatefulWidget {
  const ResultPanel({
    super.key,
    required this.l10n,
    this.changed,
    this.applied,
  });

  final PlaygroundL10n l10n;
  final Object? changed;
  final Object? applied;

  @override
  State<ResultPanel> createState() => ResultPanelState();
}

class ResultPanelState extends State<ResultPanel> {
  static const double _collapsedHeight = 112;

  /// Share of the body height the panel covers when expanded.
  static const double _expandedFactor = 0.65;

  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodySmall;

    String format(Object? value) => value == null ? '—' : value.toString();

    // In the wide layout the phone preview renders inside a [FittedBox], so
    // the incoming layout constraints are unbounded (maxHeight = infinity);
    // in the compact layout the demo fills the screen below the app bar. In
    // both cases the scoped [MediaQuery] above the phone [Navigator] carries
    // the effective screen size, so measure the expanded height against it
    // instead of the constraints.
    final expandedHeight = MediaQuery.sizeOf(context).height * _expandedFactor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: _expanded ? expandedHeight : _collapsedHeight,
      decoration: BoxDecoration(color: background),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(l10n.resultPanelTitle, style: labelStyle)),
                // Snackbar-style action: compact text button, arrow hints
                // the expand direction.
                TextButton.icon(
                  onPressed: _toggle,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 16,
                  ),
                  label: Text(
                    _expanded
                        ? l10n.resultPanelCollapse
                        : l10n.resultPanelExpand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${l10n.onChangedLabel}: ${format(widget.changed)}',
                      style: valueStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.onAppliedLabel}: ${format(widget.applied)}',
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
