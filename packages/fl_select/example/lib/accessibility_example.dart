import 'package:example/entry_repository.dart';
import 'package:example/log.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Demonstrates the accessibility (a11y) support that `fl_select` ships with.
///
/// Nothing on this page has to be switched on — the demos simply make the
/// built-in behaviour observable:
///
/// 1. every tile exposes `selected` / `enabled` semantics out of the box;
/// 2. every trigger is exposed as a button, and opening, closing and applying
///    are announced to the screen reader automatically;
/// 3. a custom `itemBuilder` keeps those semantics as long as it wraps its
///    content in a `Semantics` widget.
///
/// Turn on TalkBack (Android) or VoiceOver (iOS), or switch on the *Semantics*
/// overlay in the Flutter inspector, to hear and see the result.
class AccessibilityExample extends StatefulWidget {
  const AccessibilityExample({super.key});

  @override
  State<AccessibilityExample> createState() => _AccessibilityExampleState();
}

class _AccessibilityExampleState extends State<AccessibilityExample> {
  SelectEntries _applied = const {};

  /// Speaks [message] through the platform screen reader.
  ///
  /// `fl_select` already does this on open / close / apply; the buttons further
  /// down trigger the very same announcements by hand.
  void _announce(String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectL10n = SelectLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Note(
              'Accessibility is on by default. The widgets below are the same '
              'ones used everywhere else — the semantic labels are added for '
              'you, in the language the app is running in.',
            ),

            // -----------------------------------------------------------------
            // 1. Tiles expose selected / enabled.
            // -----------------------------------------------------------------
            const _SectionHeader(
              'Tile semantics',
              'Every tile is a button that reports whether it is selected and '
                  'whether it is enabled. Its label comes from the entry name.',
            ),
            SelectView(
              margin: const EdgeInsets.symmetric(vertical: 8),
              delegate: ListSelectDelegate(entries: listData),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
              },
            ),

            // -----------------------------------------------------------------
            // 2. The counter reports the enabled state of each step.
            // -----------------------------------------------------------------
            const _SectionHeader(
              'Counter',
              'The − and + buttons expose their enabled state, so a screen '
                  'reader announces when a step is no longer available.',
            ),
            SelectView(
              margin: const EdgeInsets.symmetric(vertical: 8),
              delegate: SideNavSelectDelegate(
                entries: _bedroomsData,
                selectionMode: SelectionMode.single,
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
              },
            ),

            // -----------------------------------------------------------------
            // 3. Trigger semantics + automatic announcements.
            // -----------------------------------------------------------------
            const _SectionHeader(
              'Trigger announcements',
              'The trigger is exposed as a button. Opening the panel, closing '
                  'it and applying a selection are announced automatically.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: PopupSelectButton(
                label: 'Announcements',
                labelLoader: (selected) => '${selected.length} selected',
                selectDelegate: ListSelectDelegate(entries: listDataWithAny),
                onApplied: (selected) {
                  setState(() => _applied = selected);
                  largePrint('onApplied: ${selected.toIdList()}');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Last applied: ${_applied.toIdList()}'),
            ),

            // -----------------------------------------------------------------
            // 4. Keeping semantics in a custom itemBuilder.
            // -----------------------------------------------------------------
            const _SectionHeader(
              'Custom itemBuilder',
              'When you replace the default tile, wrap it in `Semantics` — '
                  'otherwise the screen reader only sees an unlabelled node.',
            ),
            const _CodeBlock(
              'itemBuilder: (context, entry, {required selected, required onTap, categoryId}) {\n'
              '  return Semantics(\n'
              '    button: true,\n'
              '    selected: selected,\n'
              '    enabled: entry.enabled,\n'
              '    label: entry.name,\n'
              '    child: InkWell(onTap: onTap, child: YourTile(entry: entry)),\n'
              '  );\n'
              '}',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: PopupSelectButton(
                label: 'Custom itemBuilder',
                selectDelegate: ListSelectDelegate(
                  entries: listData,
                  itemBuilder:
                      (
                        context,
                        entry, {
                        required selected,
                        required onTap,
                        categoryId,
                      }) {
                        return Semantics(
                          button: true,
                          selected: selected,
                          enabled: entry.enabled,
                          label: entry.name,
                          child: InkWell(
                            onTap: onTap,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 42),
                              alignment: Alignment.center,
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              child: Text(
                                entry.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                ),
                onApplied: (selected) {
                  largePrint('onApplied: ${selected.toIdList()}');
                },
              ),
            ),

            // -----------------------------------------------------------------
            // 5. Manual announcements using the localized strings.
            // -----------------------------------------------------------------
            const _SectionHeader(
              'Manual announcements',
              'The exact strings `fl_select` speaks, triggered on demand. They '
                  'follow the app locale — switch the app language to hear them '
                  'change.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _announce(
                    selectL10n?.panelOpened ?? 'Select panel opened',
                  ),
                  child: const Text('panelOpened'),
                ),
                FilledButton.tonal(
                  onPressed: () => _announce(
                    selectL10n?.panelClosed ?? 'Select panel closed',
                  ),
                  child: const Text('panelClosed'),
                ),
                FilledButton.tonal(
                  onPressed: () => _announce(selectL10n?.cleared ?? 'Cleared'),
                  child: const Text('cleared'),
                ),
                FilledButton.tonal(
                  onPressed: () => _announce(
                    selectL10n?.applied(3) ?? 'Applied, 3 selected',
                  ),
                  child: const Text('applied(3)'),
                ),
                FilledButton.tonal(
                  onPressed: () =>
                      _announce(selectL10n?.clearSearch ?? 'Clear search'),
                  child: const Text('clearSearch'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _SectionHeader(
              'Localized strings',
              'The values currently resolved from `SelectLocalizations` for the '
                  'active locale.',
            ),
            _KeyValue('panelOpened', selectL10n?.panelOpened),
            _KeyValue('panelClosed', selectL10n?.panelClosed),
            _KeyValue('cleared', selectL10n?.cleared),
            _KeyValue('applied(3)', selectL10n?.applied(3)),
            _KeyValue('clearSearch', selectL10n?.clearSearch),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A bedrooms-style category rendered by `SelectCounterLayout`.
///
/// The category layout is the only thing needed to render the counter — the
/// `−` and `+` buttons then expose `enabled` semantics for free.
SelectEntries get _bedroomsData => {
  SelectCategoryEntry(
    id: 'bedrooms',
    name: 'Bedrooms',
    selectionMode: SelectionMode.single,
    layout: const SelectCounterLayout(),
    children: {
      SelectTextEntry.any(parentId: 'bedrooms', name: 'Any'),
      SelectTextEntry(parentId: 'bedrooms', id: 'b1', name: '1'),
      SelectTextEntry(parentId: 'bedrooms', id: 'b1p', name: '1+'),
      SelectTextEntry(parentId: 'bedrooms', id: 'b2', name: '2'),
      SelectTextEntry(parentId: 'bedrooms', id: 'b2p', name: '2+'),
      SelectTextEntry(parentId: 'bedrooms', id: 'b3', name: '3'),
    },
  ),
};

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.description);

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.accessibility_new,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
