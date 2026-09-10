import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'schema/select_entry_schema.dart';

/// Catalog items exposing fl_select widgets to GenUI/A2UI agents.
abstract final class FlSelectCatalogItems {
  /// All fl_select catalog items.
  ///
  /// Includes the deprecated `SelectFilter` payload alias so legacy agent
  /// payloads keep rendering; the alias will be dropped in a future minor
  /// release.
  static List<CatalogItem> get all => [select, _legacySelectFilter];

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
  static CatalogItem get select => _buildItem('Select');

  /// Deprecated alias of [select], kept for backward compatibility.
  ///
  /// Legacy agent payloads typed `SelectFilter` keep rendering through
  /// [all]. Both the alias and this getter will be removed in a future
  /// minor release — migrate payloads to the `Select` type and Dart call
  /// sites to [select].
  @Deprecated(
    'Use `select` instead. Will be removed in a future minor release.',
  )
  static CatalogItem get selectFilter => _legacySelectFilter;

  /// The deprecated `SelectFilter` payload alias, registered in [all] so
  /// legacy agent payloads keep rendering.
  static final CatalogItem _legacySelectFilter = _buildItem('SelectFilter');

  /// Builds the selection catalog item under the given payload [name].
  ///
  /// [name] exists twice: `Select` (current) and `SelectFilter` (deprecated
  /// alias, see the `selectFilter` getter).
  static CatalogItem _buildItem(String name) => CatalogItem(
    name: name,
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
    the category children).
  - `text`: option (leaf) or sub-branch (with `children`); requires `id`,`name`.
  - `range`: slider option with `min`/`max`; requires `id`,`name`.
  - `any`: resets the category to "any" (no bounds) — omit `id`.
  - `custom`: user-typed range with optional `minHintText`/`maxHintText`.
- User selections are returned as `Map<String, List<String>>`
  (e.g. `{"price": ["0-100"], "amenities": ["wifi", "pool"]}`); a selected
  category without leaf picks maps to its own id.
- Flat panels (top-level `text`/`range` leaves, no `category`) additionally
  require `flatKey`: the key under which the selection is written back
  (e.g. `"sort"` → `{"sort": ["recent"]}`).
- Legacy payloads typed `SelectFilter` keep rendering this component.''';
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

      // Cascading — drill-down tree, renders both shapes natively.
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
