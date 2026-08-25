import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';

/// Shares an application-wide [ThemeMode] [ValueNotifier] through the widget
/// tree so any page can read and update the current theme mode.
///
/// Wrap the app with [ThemeModeScope] and read/update the mode from a descendant
/// via [ThemeModeScope.of].
class ThemeModeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeModeScope({
    super.key,
    required ValueNotifier<ThemeMode> controller,
    required super.child,
  }) : super(notifier: controller);

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'ThemeModeScope not found in widget tree');
    return scope!.notifier!;
  }
}

/// A popup button intended for an [AppBar.actions] slot that lets the user
/// switch between system, light, and dark theme modes.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ThemeModeScope.of(context);
    return PopupMenuButton<ThemeMode>(
      initialValue: controller.value,
      onSelected: (mode) => controller.value = mode,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Text(l10n?.themeSystem ?? 'System'),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Text(l10n?.themeLight ?? 'Light'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Text(l10n?.themeDark ?? 'Dark'),
        ),
      ],
      icon: const Icon(Icons.brightness_6_outlined),
      tooltip: l10n?.themeMode ?? 'Theme',
    );
  }
}
