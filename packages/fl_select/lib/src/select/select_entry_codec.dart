/// JSON codec for [SelectEntry] trees.
///
/// Converts between the fl_select entry model and a plain-JSON
/// representation suitable for transport (server-driven filter configs,
/// low-code platforms, or AI agents via the `fl_select_genui` bridge).
///
/// The JSON shape uses a `type` discriminator on every node:
///
/// ```json
/// [
///   {
///     "type": "category",
///     "id": "price",
///     "name": "Price",
///     "selectionMode": "multiple",
///     "layout": {"kind": "grid", "crossAxisCount": 4},
///     "children": [
///       {"type": "any", "name": "Any"},
///       {"type": "range", "id": "0-100", "name": "0-100", "min": 0, "max": 100},
///       {"type": "custom", "name": "Custom", "min": 0, "max": 1000}
///     ]
///   }
/// ]
/// ```
///
/// Node types:
///
/// | `type`  | Dart class                    | Notes                              |
/// |--------|-------------------------------|------------------------------------|
/// | category | [SelectCategoryEntry]       | Root node; nests any children.     |
/// | text   | [SelectTextEntry]             | Leaf or branch (with `children`).  |
/// | range  | [SelectRangeEntry]            | `id` required; `min`/`max` bounds. |
/// | any    | [SelectTextEntry.any] or range| `id` is always `"any"`.            |
/// | custom | [SelectRangeEntry.custom]     | `id` is always `"custom"`.         |
///
/// Layout objects use a `kind` discriminator: `list`, `grid`, `chip`,
/// `counter`, `range` — mirroring the [SelectLayout] subclasses.
///
/// Limitations (by design):
/// * `extra` payload fields are runtime-only and never serialized.
/// * `parentId` is derived from the tree structure and ignored in input
///   (the `SelectCategoryEntry.children` / `SelectChildEntry.children`
///   factories re-inject it on decode).
/// * Range bounds decode as plain [num] (`int` when integral in JSON,
///   `double` otherwise).
library;

import 'constants.dart';
import 'select_entry.dart';
import 'select_layout.dart';

/// Encoding and decoding of [SelectEntry] trees as JSON-compatible maps.
abstract final class SelectEntryCodec {
  /// Decodes a JSON-encoded entry list (as produced by [toJson]) into an
  /// entry set, preserving order.
  ///
  /// Children gain their `parentId` automatically via the `.children`
  /// factories, exactly as with hand-built trees.
  ///
  /// Throws [FormatException] when a node is missing required fields, has
  /// an unknown `type`/`kind`, or a list/category is empty.
  static Set<SelectEntry> fromJson(List<dynamic> json) {
    if (json.isEmpty) {
      throw const FormatException('entry list must not be empty');
    }
    final result = <SelectEntry>{};
    for (final node in json) {
      result.add(_decodeEntry(_asMap(node)));
    }
    return result;
  }

  /// Encodes an entry set into a JSON-compatible list of node maps.
  ///
  /// `extra` payloads and `parentId` are not emitted; `enabled: false` and
  /// `immediate: true` are emitted only when they differ from the defaults,
  /// keeping the output compact.
  ///
  /// Throws [UnsupportedError] for entry subclasses outside the built-in
  /// family.
  static List<Map<String, dynamic>> toJson(Set<SelectEntry> entries) {
    return [for (final e in entries) _encodeEntry(e)];
  }

  // ---------------------------------------------------------------------------
  // Decoding
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _asMap(Object? node) {
    if (node is! Map) {
      throw FormatException('entry node must be a map, got: $node');
    }
    return Map<String, dynamic>.from(node);
  }

  static SelectEntry _decodeEntry(Map<String, dynamic> node) {
    switch (node['type']) {
      case 'category':
        return _decodeCategory(node);
      case 'text':
        return _decodeText(node);
      case 'range':
        return _decodeRange(node);
      case 'any':
        return _decodeAny(node);
      case 'custom':
        return _decodeCustom(node);
      case null:
        throw const FormatException('entry node is missing "type"');
      default:
        throw FormatException('unknown entry type: ${node['type']}');
    }
  }

  static SelectEntry _decodeCategory(Map<String, dynamic> node) {
    final childrenJson = node['children'] as List<dynamic>? ?? <dynamic>[];
    if (childrenJson.isEmpty) {
      throw const FormatException(
          'category node requires non-empty "children"');
    }
    return SelectCategoryEntry.children(
      id: _requiredId(node),
      name: _requiredName(node),
      children: {
        for (final child in childrenJson) _decodeEntry(_asMap(child)),
      },
      selectionMode: _decodeSelectionMode(node['selectionMode']),
      header: _decodeOptionalEntry(node['header']),
      footer: _decodeOptionalEntry(node['footer']),
      layout: _decodeLayout(node['layout']),
      enabled: node['enabled'] != false,
      immediate: node['immediate'] == true,
    );
  }

  static SelectEntry _decodeText(Map<String, dynamic> node) {
    final id = _requiredId(node);
    final name = _requiredName(node);
    final childrenJson = node['children'] as List<dynamic>?;
    if (childrenJson != null && childrenJson.isNotEmpty) {
      return SelectTextEntry.children(
        id: id,
        name: name,
        children: {
          for (final child in childrenJson) _decodeEntry(_asMap(child)),
        },
        enabled: node['enabled'] != false,
        immediate: node['immediate'] == true,
      );
    }
    return SelectTextEntry.name(
      id: id,
      name: name,
      enabled: node['enabled'] != false,
      immediate: node['immediate'] == true,
    );
  }

  static SelectEntry _decodeRange(Map<String, dynamic> node) {
    return SelectRangeEntry(
      id: _requiredId(node),
      name: (node['name'] as String?) ?? _requiredId(node),
      min: node['min'] as num?,
      max: node['max'] as num?,
      divisions: node['divisions'] as int?,
      inputLabel: node['inputLabel'] as String?,
      minHintText: node['minHintText'] as String?,
      maxHintText: node['maxHintText'] as String?,
      enabled: node['enabled'] != false,
      immediate: node['immediate'] == true,
    );
  }

  static SelectEntry _decodeAny(Map<String, dynamic> node) {
    final name = node['name'] as String? ?? 'Any';
    final min = node['min'] as num?;
    final max = node['max'] as num?;
    if (min != null || max != null) {
      return SelectRangeEntry.any(
        name: name,
        min: min,
        max: max,
        enabled: node['enabled'] != false,
      );
    }
    return SelectTextEntry.any(
      parentId: '',
      name: name,
      enabled: node['enabled'] != false,
    );
  }

  static SelectEntry _decodeCustom(Map<String, dynamic> node) {
    return SelectRangeEntry.custom(
      name: node['name'] as String? ?? 'Custom',
      min: node['min'] as num?,
      max: node['max'] as num?,
      divisions: node['divisions'] as int?,
      inputLabel: node['inputLabel'] as String?,
      minHintText: node['minHintText'] as String?,
      maxHintText: node['maxHintText'] as String?,
      enabled: node['enabled'] != false,
    );
  }

  static SelectEntry? _decodeOptionalEntry(Object? node) {
    return node == null ? null : _decodeEntry(_asMap(node));
  }

  static SelectionMode? _decodeSelectionMode(Object? value) {
    return switch (value) {
      null => null,
      'single' => SelectionMode.single,
      'multiple' => SelectionMode.multiple,
      final v => throw FormatException('unknown selectionMode: $v'),
    };
  }

  static SelectLayout? _decodeLayout(Object? node) {
    if (node == null) return null;
    if (node is! Map) {
      throw const FormatException('"layout" must be a map');
    }
    final map = Map<String, dynamic>.from(node);
    return switch (map['kind']) {
      'list' => SelectListLayout(toText: map['toText'] as String? ?? '-'),
      'grid' => SelectGridLayout(
          crossAxisCount: (map['crossAxisCount'] as num?)?.toInt() ??
              (throw const FormatException(
                  'grid layout requires "crossAxisCount"')),
          mainAxisSpacing: (map['mainAxisSpacing'] as num?)?.toDouble() ?? 0,
          crossAxisSpacing: (map['crossAxisSpacing'] as num?)?.toDouble() ?? 0,
          childAspectRatio: (map['childAspectRatio'] as num?)?.toDouble() ?? 1,
          toText: map['toText'] as String? ?? '-',
        ),
      'chip' => SelectChipLayout(
          spacing: (map['spacing'] as num?)?.toDouble() ?? 12,
          runSpacing: (map['runSpacing'] as num?)?.toDouble() ?? 12,
        ),
      'counter' => const SelectCounterLayout(),
      'range' => SelectRangeLayout(toText: map['toText'] as String? ?? '-'),
      null => throw const FormatException('layout is missing "kind"'),
      final v => throw FormatException('unknown layout kind: $v'),
    };
  }

  static String _requiredId(Map<String, dynamic> node) {
    final id = node['id'];
    if (id is! String || id.isEmpty) {
      throw FormatException(
          'entry is missing a non-empty "id": ${node['type']} node');
    }
    return id;
  }

  static String _requiredName(Map<String, dynamic> node) {
    final name = node['name'];
    if (name is! String || name.isEmpty) {
      throw FormatException(
          'entry is missing a non-empty "name": ${node['type']} node');
    }
    return name;
  }

  // ---------------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _encodeEntry(SelectEntry entry) {
    if (entry is SelectCategoryEntry) return _encodeCategory(entry);
    if (entry is SelectTextEntry) {
      return entry.isAny ? _encodeAnyText(entry) : _encodeText(entry);
    }
    if (entry is SelectRangeEntry) {
      return entry.isCustom ? _encodeCustom(entry) : _encodeRange(entry);
    }
    throw UnsupportedError(
        'SelectEntryCodec cannot serialize ${entry.runtimeType}; '
        'use built-in entry classes only');
  }

  static Map<String, dynamic> _encodeCategory(SelectCategoryEntry entry) {
    return {
      'type': 'category',
      'id': entry.id,
      'name': entry.name ?? entry.id,
      if (entry.selectionMode != null)
        'selectionMode': entry.selectionMode!.name,
      if (entry.layout != null) 'layout': _encodeLayout(entry.layout!),
      if (entry.header != null) 'header': _encodeHeaderFooter(entry.header!),
      if (entry.footer != null) 'footer': _encodeHeaderFooter(entry.footer!),
      if (!entry.enabled) 'enabled': false,
      if (entry.immediate) 'immediate': true,
      'children': [
        for (final c in entry.children ?? const <SelectEntry>{}) _encodeEntry(c),
      ],
    };
  }

  /// Header/footer subtrees render as flattened option rows keyed by their
  /// own id, so they serialize as a `text` branch node.
  static Map<String, dynamic> _encodeHeaderFooter(SelectEntry entry) {
    return {
      'type': 'text',
      'id': entry.id,
      'name': entry.name ?? entry.id,
      if (!entry.enabled) 'enabled': false,
      'children': [
        for (final c in entry.children ?? const <SelectEntry>{}) _encodeEntry(c),
      ],
    };
  }

  static Map<String, dynamic> _encodeText(SelectTextEntry entry) {
    final children = entry.children;
    return {
      'type': 'text',
      'id': entry.id,
      'name': entry.name ?? entry.id,
      if (!entry.enabled) 'enabled': false,
      if (entry.immediate) 'immediate': true,
      if (children != null && children.isNotEmpty)
        'children': [for (final c in children) _encodeEntry(c)],
    };
  }

  static Map<String, dynamic> _encodeRange(SelectRangeEntry entry) {
    return {
      'type': 'range',
      'id': entry.id,
      'name': entry.name ?? entry.id,
      if (entry.min != null) 'min': entry.min,
      if (entry.max != null) 'max': entry.max,
      if (entry.divisions != null) 'divisions': entry.divisions,
      if (entry.inputLabel != null) 'inputLabel': entry.inputLabel,
      if (entry.minHintText != null) 'minHintText': entry.minHintText,
      if (entry.maxHintText != null) 'maxHintText': entry.maxHintText,
      if (!entry.enabled) 'enabled': false,
      if (entry.immediate) 'immediate': true,
    };
  }

  static Map<String, dynamic> _encodeAnyText(SelectEntry entry) {
    return {
      'type': 'any',
      'name': entry.name ?? 'Any',
      if (!entry.enabled) 'enabled': false,
    };
  }

  static Map<String, dynamic> _encodeCustom(SelectRangeEntry entry) {
    return {
      'type': 'custom',
      'name': entry.name ?? 'Custom',
      if (entry.min != null) 'min': entry.min,
      if (entry.max != null) 'max': entry.max,
      if (entry.divisions != null) 'divisions': entry.divisions,
      if (entry.inputLabel != null) 'inputLabel': entry.inputLabel,
      if (entry.minHintText != null) 'minHintText': entry.minHintText,
      if (entry.maxHintText != null) 'maxHintText': entry.maxHintText,
      if (!entry.enabled) 'enabled': false,
    };
  }

  static Map<String, dynamic> _encodeLayout(SelectLayout layout) {
    return switch (layout) {
      SelectListLayout(:final toText) => {'kind': 'list', 'toText': toText},
      SelectGridLayout(
        :final crossAxisCount,
        :final mainAxisSpacing,
        :final crossAxisSpacing,
        :final childAspectRatio,
        :final toText,
      ) =>
        {
          'kind': 'grid',
          'crossAxisCount': crossAxisCount,
          'mainAxisSpacing': mainAxisSpacing,
          'crossAxisSpacing': crossAxisSpacing,
          'childAspectRatio': childAspectRatio,
          'toText': toText,
        },
      SelectChipLayout(:final spacing, :final runSpacing) => {
          'kind': 'chip',
          'spacing': spacing,
          'runSpacing': runSpacing,
        },
      SelectCounterLayout() => {'kind': 'counter'},
      SelectRangeLayout(:final toText) => {'kind': 'range', 'toText': toText},
    };
  }
}
