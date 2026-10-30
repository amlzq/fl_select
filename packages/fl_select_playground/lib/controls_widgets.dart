import 'package:material_ui/material_ui.dart';

/// Vertical spacer shared by every self-contained control group, so the
/// panel keeps a uniform rhythm no matter which subset is visible.
class ControlGroup extends StatelessWidget {
  final List<Widget> children;

  const ControlGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[...children, const SizedBox(height: 16)],
    );
  }
}

class ControlSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  /// Technical parameter name revealed by the help tooltip, e.g.
  /// `GridSelectDelegate.crossAxisCount`.
  final String? techParam;

  const ControlSlider({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    this.techParam,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionTitle(title, techParam: techParam),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Section title with an optional help icon whose tooltip reveals the
/// technical parameter name (`fl_select` / Flutter API) behind the control —
/// see CONTROLS.md §1. The technical name is never translated.
class SectionTitle extends StatelessWidget {
  final String text;

  /// Technical parameter name, e.g. `GridSelectDelegate.crossAxisSpacing`.
  final String? techParam;

  const SectionTitle(this.text, {super.key, this.techParam});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        spacing: 4,
        children: <Widget>[
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (techParam != null) TechHelpIcon(techParam!),
        ],
      ),
    );
  }
}

/// A switch-list title that carries the same optional technical-parameter
/// tooltip as [SectionTitle], keeping switches consistent with section
/// titles.
class TechSwitchTitle extends StatelessWidget {
  final String text;
  final String? techParam;

  const TechSwitchTitle(this.text, {super.key, this.techParam});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      children: <Widget>[
        Flexible(child: Text(text)),
        if (techParam != null) TechHelpIcon(techParam!),
      ],
    );
  }
}

/// Small help icon that shows the technical parameter name on hover /
/// long-press.
class TechHelpIcon extends StatelessWidget {
  final String techParam;

  const TechHelpIcon(this.techParam, {super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: techParam,
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(
        Icons.help_outline,
        size: 14,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}

class EnumDropdown<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const EnumDropdown({
    super.key,
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

class SeedColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const SeedColorSwatch({
    super.key,
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
