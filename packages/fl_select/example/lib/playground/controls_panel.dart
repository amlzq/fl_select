import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import 'playground_l10n.dart';
import 'playground_params.dart';

/// The left-hand parameter panel. Every control reports changes through
/// [onChanged] with a new immutable [PlaygroundParams].
///
/// Controls are rendered declaratively from [PlaygroundControlSpec]: private
/// controls come first (per entry point, then per delegate), followed by the
/// common controls. Controls that the active entry point or delegate does not
/// support are hidden entirely.
class ControlsPanel extends StatelessWidget {
  final PlaygroundParams params;
  final ValueChanged<PlaygroundParams> onChanged;
  final PlaygroundL10n l10n;

  const ControlsPanel({
    required this.params,
    required this.onChanged,
    required this.l10n,
    super.key,
  });

  /// Whether the grid geometry sliders (columns / aspect ratio) take effect:
  /// only the inline view's column-based delegates (grid / flatten) read
  /// them; cascading and list carry no grid geometry.
  bool get _gridGeometryActive =>
      PlaygroundControlSpec.isGeometryActive(params);

  /// Whether the spacing slider takes effect: every non-view entry point
  /// embeds a grid-family sample, while the view limits it to the
  /// column-based delegates.
  bool get _spacingActive => PlaygroundControlSpec.isSpacingActive(params);

  @override
  Widget build(BuildContext context) {
    // Private controls of the active entry point, then of the active
    // delegate; controls unsupported by either are hidden entirely.
    final entryPointControls =
        PlaygroundControlSpec.entryPointPrivateControls[params.entryPoint] ??
            const <PlaygroundControl>[];
    final delegateControls = <PlaygroundControl>[
      if (_gridGeometryActive)
        ...PlaygroundControlSpec.columnBasedDelegateControls,
      if (_spacingActive) PlaygroundControl.spacing,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionTitle(l10n.entryPoint),
          _EnumDropdown<EntryPoint>(
            value: params.entryPoint,
            items: const {
              EntryPoint.view: 'SelectView',
              EntryPoint.popupBar: 'PopupSelectBar',
              EntryPoint.popupButton: 'PopupSelectButton',
              EntryPoint.dialog: 'showSelect',
              EntryPoint.bottomSheet: 'showModalBottomSelect',
            },
            // Switching the entry point swaps the visible control set below.
            onChanged: (v) => onChanged(params.copyWith(entryPoint: v)),
          ),
          const SizedBox(height: 16),
          ..._buildControls(entryPointControls),
          ..._buildControls(delegateControls),
          ..._buildControls(PlaygroundControlSpec.commonControls),
        ],
      ),
    );
  }

  List<Widget> _buildControls(Iterable<PlaygroundControl> controls) =>
      <Widget>[for (final control in controls) _buildControl(control)];

  Widget _buildControl(PlaygroundControl control) {
    return switch (control) {
      PlaygroundControl.selectionMode => _buildSelectionMode(),
      PlaygroundControl.tileVariant => _buildTileVariant(),
      PlaygroundControl.spacing => _buildSpacing(),
      PlaygroundControl.brightness => _buildBrightness(),
      PlaygroundControl.seedColor => _buildSeedColor(),
      PlaygroundControl.useMaterial3 => _buildUseMaterial3(),
      PlaygroundControl.delegate => _buildDelegate(),
      PlaygroundControl.crossAxisCount => _buildCrossAxisCount(),
      PlaygroundControl.childAspectRatio => _buildChildAspectRatio(),
    };
  }

  Widget _buildSelectionMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.selectionMode),
        SegmentedButton<SelectionMode>(
          selected: {params.selectionMode},
          onSelectionChanged: (set) =>
              onChanged(params.copyWith(selectionMode: set.first)),
          segments: <ButtonSegment<SelectionMode>>[
            ButtonSegment(
                value: SelectionMode.single, label: Text(l10n.single)),
            ButtonSegment(
                value: SelectionMode.multiple, label: Text(l10n.multiple)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTileVariant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.tileVariant),
        SegmentedButton<TileVariant>(
          selected: {params.tileVariant},
          onSelectionChanged: (set) =>
              onChanged(params.copyWith(tileVariant: set.first)),
          segments: <ButtonSegment<TileVariant>>[
            ButtonSegment(value: TileVariant.filled, label: Text(l10n.filled)),
            ButtonSegment(
                value: TileVariant.outlined, label: Text(l10n.outlined)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBrightness() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.brightness),
        SegmentedButton<Brightness?>(
          selected: {params.brightness},
          onSelectionChanged: (set) {
            final brightness = set.first;
            onChanged(params.copyWith(
              brightness: brightness,
              clearBrightness: brightness == null,
            ));
          },
          segments: <ButtonSegment<Brightness?>>[
            ButtonSegment(value: null, label: Text(l10n.follow)),
            ButtonSegment(value: Brightness.light, label: Text(l10n.light)),
            ButtonSegment(value: Brightness.dark, label: Text(l10n.dark)),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSeedColor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.seedColor),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final color in seedColorPresets)
              _ColorSwatch(
                color: color,
                selected: color.toARGB32 == params.seedColor.toARGB32,
                onTap: () => onChanged(params.copyWith(seedColor: color)),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUseMaterial3() {
    return SwitchListTile(
      title: Text(l10n.material3),
      value: params.useMaterial3,
      onChanged: (v) => onChanged(params.copyWith(useMaterial3: v)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDelegate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.delegate),
        _EnumDropdown<Delegate>(
          value: params.delegate,
          items: {
            Delegate.cascading: l10n.layoutCascading,
            Delegate.list: l10n.layoutList,
            Delegate.grid: l10n.layoutGrid,
            Delegate.flatten: l10n.layoutFlatten,
          },
          onChanged: (v) => onChanged(params.copyWith(
            delegate: v,
            crossAxisCount: defaultCrossAxisCountByDelegate[v],
            childAspectRatio: defaultChildAspectRatioByDelegate[v],
          )),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCrossAxisCount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.columns(params.crossAxisCount)),
        Slider(
          value: params.crossAxisCount.toDouble(),
          min: 2,
          max: 6,
          divisions: 4,
          label: '${params.crossAxisCount}',
          onChanged: (v) =>
              onChanged(params.copyWith(crossAxisCount: v.round())),
        ),
      ],
    );
  }

  Widget _buildChildAspectRatio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(
            l10n.aspectRatio(params.childAspectRatio.toStringAsFixed(1))),
        Slider(
          value: params.childAspectRatio,
          min: 1.0,
          max: 4.0,
          divisions: 30,
          label: params.childAspectRatio.toStringAsFixed(1),
          onChanged: (v) => onChanged(params.copyWith(childAspectRatio: v)),
        ),
      ],
    );
  }

  Widget _buildSpacing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(l10n.spacing(params.spacing.round())),
        Slider(
          value: params.spacing,
          min: 0,
          max: 16,
          divisions: 16,
          label: params.spacing.round().toString(),
          onChanged: (v) => onChanged(params.copyWith(spacing: v)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const _EnumDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: <DropdownMenuItem<T>>[
        for (final entry in items.entries)
          DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: enabled ? (v) => onChanged(v as T) : null,
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black87 : Colors.transparent,
            width: 3,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
