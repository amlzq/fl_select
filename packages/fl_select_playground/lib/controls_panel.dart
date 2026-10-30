import 'package:fl_select/fl_select.dart';
import 'package:material_ui/material_ui.dart';

import 'controls_widgets.dart';
import 'playground_l10n.dart';
import 'playground_params.dart';

/// The left-hand parameter panel. Every control reports changes through
/// [onChanged] with a new immutable [PlaygroundParams].
///
/// Controls are rendered declaratively from [PlaygroundControlSpec]:
/// entry-point private controls come first, then the delegate picker with the
/// delegate private ones, then the common ones. Controls that the active
/// entry point or delegate does not support are hidden entirely — the panel
/// never renders a control whose parameter would be ignored.
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            l10n.entryPoint,
            techParam: 'PlaygroundParams.entryPoint',
          ),
          EnumDropdown<EntryPoint>(
            value: params.entryPoint,
            items: const {
              EntryPoint.view: 'SelectView',
              EntryPoint.button: 'PopupSelectButton',
              EntryPoint.bar: 'PopupSelectBar',
              EntryPoint.dialog: 'showSelect',
              EntryPoint.bottomSheet: 'showModalBottomSelect',
            },
            // Switching the entry point swaps the visible control set below.
            onChanged: (v) => onChanged(params.copyWith(entryPoint: v)),
          ),
          const SizedBox(height: 16),
          // Entry-point private, then the delegate picker + delegate
          // private, then common.
          for (final control in PlaygroundControlSpec.visibleControls(params))
            _buildControl(control),
        ],
      ),
    );
  }

  Widget _buildControl(PlaygroundControl control) {
    return switch (control) {
      PlaygroundControl.delegate => _buildDelegate(),
      PlaygroundControl.selectionMode => _buildSelectionMode(),
      PlaygroundControl.searchEnabled => _buildSearchEnabled(),
      PlaygroundControl.tileVariant => _buildTileVariant(),
      PlaygroundControl.crossAxisCount => _buildCrossAxisCount(),
      PlaygroundControl.childAspectRatio => _buildChildAspectRatio(),
      PlaygroundControl.crossAxisSpacing => _buildCrossAxisSpacing(),
      PlaygroundControl.mainAxisSpacing => _buildMainAxisSpacing(),
      PlaygroundControl.spacing => _buildSpacing(),
      PlaygroundControl.runSpacing => _buildRunSpacing(),
      PlaygroundControl.cascadingScrollable => _buildCascadingScrollable(),
      PlaygroundControl.brightness => _buildBrightness(),
      PlaygroundControl.seedColor => _buildSeedColor(),
      PlaygroundControl.useMaterial3 => _buildUseMaterial3(),
      PlaygroundControl.isScrollable => _buildIsScrollable(),
      PlaygroundControl.direction => _buildDirection(),
      PlaygroundControl.buttonVariant => _buildButtonVariant(),
      PlaygroundControl.headerLeading => _buildHeaderLeading(),
      PlaygroundControl.headerTrailing => _buildHeaderTrailing(),
      PlaygroundControl.headerCenterTitle => _buildHeaderCenterTitle(),
    };
  }

  // ---- Delegate picker ----

  Widget _buildDelegate() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(l10n.delegate, techParam: 'PlaygroundParams.delegate'),
        EnumDropdown<Delegate>(
          value: params.delegate,
          items: {
            Delegate.list: l10n.layoutList,
            Delegate.grid: l10n.layoutGrid,
            Delegate.wrap: l10n.layoutWrap,
            Delegate.cascading: l10n.layoutCascading,
            Delegate.tabNav: l10n.layoutTabNav,
            Delegate.sideNav: l10n.layoutSideNav,
            Delegate.expandable: l10n.layoutExpandable,
          },
          onChanged: (v) => onChanged(params.copyWith(delegate: v)),
        ),
      ],
    );
  }

  // ---- Entry point private ----

  Widget _buildIsScrollable() {
    return SwitchListTile(
      title: TechSwitchTitle(
        l10n.scrollable,
        techParam: 'PopupSelectBar.isScrollable',
      ),
      value: params.isScrollable,
      onChanged: (v) => onChanged(params.copyWith(isScrollable: v)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDirection() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(
          l10n.direction,
          techParam: params.entryPoint == EntryPoint.button
              ? 'PopupSelectButton.direction'
              : 'PopupSelectBar.direction',
        ),
        EnumDropdown<PopupSelectDirection>(
          value: params.direction,
          items: {
            PopupSelectDirection.below: l10n.directionBelow,
            PopupSelectDirection.above: l10n.directionAbove,
            PopupSelectDirection.adaptive: l10n.directionAdaptive,
          },
          onChanged: (v) => onChanged(params.copyWith(direction: v)),
        ),
      ],
    );
  }

  Widget _buildButtonVariant() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(
          l10n.buttonVariant,
          techParam: 'PopupSelectButton.variant',
        ),
        EnumDropdown<PopupSelectButtonVariant>(
          value: params.buttonVariant,
          items: {
            PopupSelectButtonVariant.elevated: l10n.elevated,
            PopupSelectButtonVariant.filled: l10n.filled,
            PopupSelectButtonVariant.outlined: l10n.outlined,
            PopupSelectButtonVariant.text: l10n.text,
          },
          onChanged: (v) => onChanged(params.copyWith(buttonVariant: v)),
        ),
      ],
    );
  }

  Widget _buildHeaderLeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(l10n.headerOptions),
        SwitchListTile(
          title: TechSwitchTitle(l10n.leadingOption, techParam: 'leading'),
          value: params.headerLeading,
          onChanged: (v) => onChanged(params.copyWith(headerLeading: v)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildHeaderTrailing() {
    return SwitchListTile(
      title: TechSwitchTitle(l10n.trailingOption, techParam: 'trailing'),
      value: params.headerTrailing,
      onChanged: (v) => onChanged(params.copyWith(headerTrailing: v)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildHeaderCenterTitle() {
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: TechSwitchTitle(
            l10n.centerTitleOption,
            techParam: 'centerTitle',
          ),
          value: params.centerTitle,
          onChanged: (v) => onChanged(params.copyWith(centerTitle: v)),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---- Delegate private ----

  Widget _buildCascadingScrollable() {
    return SwitchListTile(
      title: TechSwitchTitle(
        l10n.scrollable,
        techParam: 'CascadingSelectDelegate.isScrollable',
      ),
      value: params.cascadingScrollable,
      onChanged: (v) => onChanged(params.copyWith(cascadingScrollable: v)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCrossAxisCount() {
    return ControlSlider(
      title: l10n.columns(params.crossAxisCount),
      value: params.crossAxisCount.toDouble(),
      min: 2,
      max: 6,
      divisions: 4,
      label: '${params.crossAxisCount}',
      techParam: 'GridSelectDelegate.crossAxisCount',
      onChanged: (v) => onChanged(params.copyWith(crossAxisCount: v.round())),
    );
  }

  Widget _buildChildAspectRatio() {
    return ControlSlider(
      title: l10n.aspectRatio(params.childAspectRatio.toStringAsFixed(1)),
      value: params.childAspectRatio,
      min: 1.0,
      max: 4.0,
      divisions: 30,
      label: params.childAspectRatio.toStringAsFixed(1),
      techParam: 'GridSelectDelegate.childAspectRatio',
      onChanged: (v) => onChanged(params.copyWith(childAspectRatio: v)),
    );
  }

  Widget _buildCrossAxisSpacing() {
    return ControlSlider(
      title: l10n.columnSpacing(params.crossAxisSpacing.round()),
      value: params.crossAxisSpacing,
      min: 0,
      max: 16,
      divisions: 16,
      label: params.crossAxisSpacing.round().toString(),
      techParam: 'GridSelectDelegate.crossAxisSpacing',
      onChanged: (v) => onChanged(params.copyWith(crossAxisSpacing: v)),
    );
  }

  Widget _buildMainAxisSpacing() {
    return ControlSlider(
      title: l10n.rowSpacing(params.mainAxisSpacing.round()),
      value: params.mainAxisSpacing,
      min: 0,
      max: 16,
      divisions: 16,
      label: params.mainAxisSpacing.round().toString(),
      techParam: 'GridSelectDelegate.mainAxisSpacing',
      onChanged: (v) => onChanged(params.copyWith(mainAxisSpacing: v)),
    );
  }

  Widget _buildSpacing() {
    return ControlSlider(
      title: l10n.spacing(params.spacing.round()),
      value: params.spacing,
      min: 0,
      max: 16,
      divisions: 16,
      label: params.spacing.round().toString(),
      techParam: 'WrapSelectDelegate.spacing',
      onChanged: (v) => onChanged(params.copyWith(spacing: v)),
    );
  }

  Widget _buildRunSpacing() {
    return ControlSlider(
      title: l10n.runSpacing(params.runSpacing.round()),
      value: params.runSpacing,
      min: 0,
      max: 16,
      divisions: 16,
      label: params.runSpacing.round().toString(),
      techParam: 'WrapSelectDelegate.runSpacing',
      onChanged: (v) => onChanged(params.copyWith(runSpacing: v)),
    );
  }

  Widget _buildTileVariant() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(
          l10n.tileVariant,
          techParam: params.delegate == Delegate.grid
              ? 'SelectGridTileTheme.variant'
              : 'SelectWrapViewTheme.variant',
        ),
        SegmentedButton<TileVariant>(
          selected: {params.tileVariant},
          onSelectionChanged: (set) =>
              onChanged(params.copyWith(tileVariant: set.first)),
          segments: <ButtonSegment<TileVariant>>[
            ButtonSegment(value: TileVariant.filled, label: Text(l10n.filled)),
            ButtonSegment(
              value: TileVariant.outlined,
              label: Text(l10n.outlined),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Common ----

  Widget _buildSearchEnabled() {
    return SwitchListTile(
      title: TechSwitchTitle(
        l10n.searchEnabled,
        techParam: 'SelectDelegate.searchEnabled',
      ),
      value: params.searchEnabled,
      onChanged: (v) => onChanged(params.copyWith(searchEnabled: v)),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSelectionMode() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(
          l10n.selectionMode,
          techParam: 'SelectDelegate.selectionMode',
        ),
        SegmentedButton<SelectionMode>(
          selected: {params.selectionMode},
          onSelectionChanged: (set) =>
              onChanged(params.copyWith(selectionMode: set.first)),
          segments: <ButtonSegment<SelectionMode>>[
            ButtonSegment(
              value: SelectionMode.single,
              label: Text(l10n.single),
            ),
            ButtonSegment(
              value: SelectionMode.multiple,
              label: Text(l10n.multiple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrightness() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(l10n.brightness, techParam: 'ThemeData.brightness'),
        SegmentedButton<Brightness?>(
          selected: {params.brightness},
          onSelectionChanged: (set) {
            final brightness = set.first;
            onChanged(
              params.copyWith(
                brightness: brightness,
                clearBrightness: brightness == null,
              ),
            );
          },
          segments: <ButtonSegment<Brightness?>>[
            ButtonSegment(value: null, label: Text(l10n.follow)),
            ButtonSegment(value: Brightness.light, label: Text(l10n.light)),
            ButtonSegment(value: Brightness.dark, label: Text(l10n.dark)),
          ],
        ),
      ],
    );
  }

  Widget _buildSeedColor() {
    return ControlGroup(
      children: <Widget>[
        SectionTitle(l10n.seedColor, techParam: 'ColorScheme.fromSeed'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final color in seedColorPresets)
              SeedColorSwatch(
                color: color,
                selected: color.toARGB32 == params.seedColor.toARGB32,
                onTap: () => onChanged(params.copyWith(seedColor: color)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUseMaterial3() {
    return SwitchListTile(
      title: TechSwitchTitle(
        l10n.material3,
        techParam: 'ThemeData.useMaterial3',
      ),
      value: params.useMaterial3,
      onChanged: (v) => onChanged(params.copyWith(useMaterial3: v)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
