import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'schema/select_entry_schema.dart';

/// Catalog items exposing fl_select widgets to GenUI/A2UI agents.
abstract final class FlSelectCatalogItems {
  /// All fl_select catalog items.
  static List<CatalogItem> get all => [select];

  /// The catalog as a whole, ready to be merged into a surface controller:
  ///
  /// ```dart
  /// SurfaceController(
  ///   catalogs: [BasicCatalogItems.asCatalog().copyWith(newItems: FlSelectCatalogItems.all)],
  /// )
  /// ```
  static Catalog asCatalog() => Catalog(all, catalogId: 'fl_select');

  /// A selection component backed by [SelectView].
  ///
  /// The agent supplies an entry tree (`SelectEntryCodec` JSON format) and a
  /// delegate type; user selections are written back to the data model as a
  /// `Map<String, List<String>>` (same shape as `toQueryMap`).
  static CatalogItem get select => _buildItem();

  /// Builds the selection catalog item.
  static CatalogItem _buildItem() => CatalogItem(
    name: 'Select',
    dataSchema: S.object(
      description:
          'A selection component with categories, options, sliders and '
          'range pickers. Use it whenever the user should pick one or more '
          'values from a structured option set.',
      properties: {
        'delegate': S.string(
          description:
              'Body layout: "list"/"grid" fit any shape, "wrap" is a flat '
              'chip cloud, "cascading" is a drill-down tree, "tabNav"/'
              '"sideNav"/"expandable" render category groups, "flatten" is a '
              'legacy alias. Layouts auto-fallback to match the entries '
              'shape.',
          enumValues: [
            'list',
            'grid',
            'wrap',
            'cascading',
            'tabNav',
            'sideNav',
            'expandable',
            'flatten',
          ],
        ),
        'selectionMode': S.string(
          description: 'Per panel; default multiple.',
          enumValues: ['single', 'multiple'],
        ),
        'crossAxisCount': S.integer(
          description: 'Grid delegate only: columns.',
        ),
        'search': S.boolean(description: 'Enable search field.'),
        'flatKey': S.string(
          description:
              'Key under which a flat (non-category) selection is written '
              'back, e.g. "sort". Required when top-level entries are not '
              'categories; ignored for category trees.',
        ),
        'entries': SelectEntrySchema.tree(),
      },
      required: const ['delegate', 'entries'],
    ),
    isImplicitlyFlexible: true,
    exampleData: [
      () =>
          '{"delegate":"sideNav","selectionMode":"multiple","entries":['
          '{"type":"category","id":"price","name":"Price","children":['
          '{"type":"any","name":"Any"},'
          '{"type":"range","id":"0-100","name":"\$0 - \$100","min":0,"max":100},'
          '{"type":"range","id":"100-300","name":"\$100 - \$300","min":100,"max":300},'
          '{"type":"custom","name":"Custom","min":0,"max":1000}]},'
          '{"type":"category","id":"amenities","name":"Amenities","children":['
          '{"type":"text","id":"wifi","name":"Wi-Fi"},'
          '{"type":"text","id":"parking","name":"Parking"},'
          '{"type":"text","id":"pool","name":"Pool"}]}]}',
    ],
    widgetBuilder: (itemContext) {
      final data = itemContext.data;
      final path = data is JsonMap && data['path'] is String
          ? data['path']! as String
          : '${itemContext.id}.value';

      return _SelectWidget(itemContext: itemContext, dataPath: path);
    },
  );

  /// System-prompt fragment documenting the entry-tree JSON format for
  /// agents using [select]. Append it to your agent instructions.
  static const String systemPromptFragment = '''
When the user needs to pick values from a structured option set, render a `Select`:
- `delegate`: "list", "grid" (with `crossAxisCount`), "wrap" (flat chip
  cloud), "cascading" (drill-down menus), "tabNav" (category tabs on top),
  "sideNav" (recommended for category groups: left rail, options in one
  scrollable panel), or "expandable" (accordion groups). Layouts
  auto-fallback to match the `entries` shape; "flatten" is a legacy alias.
- `entries`: a tree of nodes, each with a `type`:
  - `category`: group; requires `id`, `name`, non-empty `children`; optional
    `selectionMode` ("single"/"multiple"), `layout`
    (`{"kind":"grid","crossAxisCount":3}` etc.), and `header`/`footer`
    (branch nodes whose `children` render as chip rows pinned above/below
    the category children). A `header`/`footer` row renders chips only, so
    its `children` must not contain a `custom` entry — put `custom` under the
    category's own `children` instead.
  - `text`: option (leaf) or sub-branch (with `children`); requires `id`,`name`.
  - `range`: slider option with `min`/`max`; requires `id`,`name`.
  - `any`: resets the category to "any" (no bounds) — omit `id`.
  - `custom`: user-typed range with optional `minHintText`/`maxHintText`.
  - Siblings — the top-level entries, one node's `children`, and a `header`/
    `footer` row — must carry distinct `id`s; a duplicate sibling id is
    rejected with the error card.
- User selections are returned as `Map<String, List<String>>`
  (e.g. `{"price": ["0-100"], "amenities": ["wifi", "pool"]}`); a selected
  category without leaf picks maps to its own id.
- Flat panels (top-level `text`/`range` leaves, no `category`) additionally
  require `flatKey`: the key under which the selection is written back
  (e.g. `"sort"` → `{"sort": ["recent"]}`).''';
}

class _SelectWidget extends StatelessWidget {
  const _SelectWidget({required this.itemContext, required this.dataPath});

  final CatalogItemContext itemContext;
  final String dataPath;

  @override
  Widget build(BuildContext context) {
    final data = (itemContext.data is JsonMap
        ? itemContext.data as JsonMap
        : const <String, Object?>{});

    final entriesJson = data['entries'];
    if (entriesJson is! List || entriesJson.isEmpty) {
      return _SchemaError(
        '${itemContext.type} requires a non-empty "entries" array.',
      );
    }

    Set<SelectEntry> entries;
    try {
      entries = SelectEntryCodec.fromJson(entriesJson);
    } on FormatException catch (e) {
      return _SchemaError('Invalid entries: ${e.message}');
    } on UnsupportedError catch (e) {
      return _SchemaError('Unsupported entries: ${e.message}');
    }

    // fl_select 0.15.0 validates the entry tree when the panel binds it and
    // rejects duplicate sibling ids (and, before that, a stale `parentId` or a
    // non-category entry beside a category). Validate the decoded tree here as
    // well, so a bad payload is reported through this catalog's error card
    // instead of reaching the panel and surfacing as its own error UI — which
    // would also log a `FlutterError` and hang the frame's build phase.
    try {
      SelectController.validateEntries(entries.toList());
    } on ArgumentError catch (e) {
      return _SchemaError('Invalid entries: ${e.message}');
    }

    // A category's header/footer renders as a single-row chip bar, which has
    // no room for a custom range entry's min/max input field: rendering one
    // throws inside the chip bar, so reject it up front and surface the
    // payload error as a schema error card instead.
    final chipRowError = _chipRowError(entries);
    if (chipRowError != null) return _SchemaError(chipRowError);

    // Flat vs category shape decides both the delegate fallback below and
    // the write-back encoding.
    final isCategoryData =
        entries.isNotEmpty && entries.first is SelectCategoryEntry;

    // A flat selection has no category ids to key the write-back by, so the
    // agent must name the key explicitly.
    final flatKey = data['flatKey'] as String?;
    if (!isCategoryData && (flatKey == null || flatKey.isEmpty)) {
      return _SchemaError(
        '${itemContext.type} with flat (non-category) entries requires a '
        '"flatKey" so selections can be written back.',
      );
    }

    return SelectView(
      delegate: _buildDelegate(data, entries, isCategoryData),
      onChanged: (selected) {
        // Write the selection back so the agent (and other widgets) can
        // react to it. Category trees yield Map<String, List<String>> via
        // `toQueryMap`; flat selections yield their ids under `flatKey`.
        itemContext.dataContext.update(
          DataPath(dataPath),
          selected.isEmpty
              ? <String, List<String>>{}
              : _encodeSelection(selected, flatKey),
        );
      },
    );
  }

  SelectDelegate _buildDelegate(
    JsonMap data,
    Set<SelectEntry> entries,
    bool isCategoryData,
  ) {
    final delegateName = data['delegate'] as String? ?? 'list';
    final selectionMode = switch (data['selectionMode']) {
      'single' => SelectionMode.single,
      _ => SelectionMode.multiple,
    };
    final searchEnabled = data['search'] == true;
    // Category-aware delegates assert on flat data (and flat delegates on
    // category data), so the requested layout is matched to the actual
    // entry-tree shape: grouped layouts fall back to their flat equivalent
    // and vice versa.
    return switch (delegateName) {
      // List — flat list panel; category data falls through to the default
      // arm below.
      'list' when !isCategoryData => ListSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // Grid — flat grid; two-level data renders as tabNav with a grid
      // layout.
      'grid' when isCategoryData => TabNavSelectDelegate(
        defaultLayout: SelectGridLayout(
          crossAxisCount: data['crossAxisCount'] as int? ?? 3,
        ),
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
      'grid' => GridSelectDelegate(
        crossAxisCount: data['crossAxisCount'] as int? ?? 3,
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // Wrap — flat chip cloud; two-level data (including the legacy
      // sideNav share below) renders as sideNav.
      'sideNav' ||
      'wrap' ||
      'chips' ||
      'flatten' when isCategoryData => SideNavSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
      'wrap' || 'chips' || 'flatten' => WrapSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // Cascading — drill-down tree; flat data falls back to the list,
      // because the cascading body only renders category trees.
      'cascading' when !isCategoryData => ListSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
      'cascading' => CascadingSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // TabNav — category tabs on top; flat data falls back to the list.
      'tabNav' when isCategoryData => TabNavSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
      'tabNav' => ListSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // SideNav — left category rail; flat data falls back to the list.
      'sideNav' => ListSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // Expandable — accordion groups; flat data falls back to the list.
      'expandable' when isCategoryData => ExpandableSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
      'expandable' => ListSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),

      // default / unknown tokens: category data groups as expandable,
      // flat data as list.
      _ when isCategoryData => ExpandableSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
      _ => ListSelectDelegate(
        searchEnabled: searchEnabled,
        selectionMode: selectionMode,
        entries: entries,
      ),
    };
  }

  static Map<String, List<String>> _encodeSelection(
    Set<SelectEntry> selected,
    String? flatKey,
  ) {
    final isCategoryTree = selected.any((e) => e is SelectCategoryEntry);
    if (isCategoryTree) return selected.toQueryMap();
    // Flat selection: `flatKey` is guaranteed non-null by the build-time
    // validation above.
    return {flatKey!: selected.toIdList()};
  }

  /// Describes the first `header`/`footer` row that carries a custom range
  /// entry, or null when every category in [entries] is chip-bar safe.
  ///
  /// Both rows render as a single row of chips and a custom range entry has
  /// no chip representation, so the chip bar throws a `FlutterError` while
  /// building on one.
  static String? _chipRowError(Set<SelectEntry> entries) {
    for (final entry in entries) {
      if (entry is SelectCategoryEntry) {
        for (final (label, row) in [
          ('header', entry.header),
          ('footer', entry.footer),
        ]) {
          final customId = _customIdIn(row?.children);
          if (customId != null) {
            return 'Category "${entry.id}" $label contains the custom range '
                'entry "$customId", but a $label renders as a single-row chip '
                'bar with no room for its min/max input field. Move the custom '
                'entry into the category\'s "children".';
          }
        }
      }

      // Categories nest (e.g. "cascading"), so keep walking the tree.
      final children = entry.children;
      if (children != null && children.isNotEmpty) {
        final error = _chipRowError(children);
        if (error != null) return error;
      }
    }
    return null;
  }

  /// The id of the first custom range entry in [entries] or their descendants,
  /// or null when the row carries no custom entry.
  static String? _customIdIn(Set<SelectEntry>? entries) {
    if (entries == null) return null;
    for (final entry in entries) {
      if (entry is SelectRangeEntry && entry.isCustom) return entry.id;
      final nested = _customIdIn(entry.children);
      if (nested != null) return nested;
    }
    return null;
  }
}

class _SchemaError extends StatelessWidget {
  const _SchemaError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
