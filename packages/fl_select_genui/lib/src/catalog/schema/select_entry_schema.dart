import 'package:json_schema_builder/json_schema_builder.dart';

/// JSON-schema description of the `SelectEntryCodec` node format, used to
/// tell AI agents how to author `entries` payloads for `SelectFilter`.
///
/// Mirrors `SelectEntryCodec` in package:fl_select. Node shape:
///
/// ```json
/// {"type": "category", "id": "price", "name": "Price", "children": [...]}
/// ```
abstract final class SelectEntrySchema {
  /// Schema for one (possibly nested) entry node.
  ///
  /// `children` is deliberately loose (`type: object`) because this schema
  /// builder has no `$ref` recursion; the system-prompt fragment documents
  /// the recursive shape instead.
  static Schema node() => S.object(
    description:
        'One select entry node. `type` discriminates the node: '
        'category (group with children), text (option or sub-branch), '
        'range (slider with min/max), any (selects-everything sentinel), '
        'custom (user-typed range). `id`/`name` are required except for '
        'any/custom which use fixed ids.',
    properties: {
      'type': S.string(
        description: 'category | text | range | any | custom',
        enumValues: ['category', 'text', 'range', 'any', 'custom'],
      ),
      'id': S.string(
        description:
            'Stable identifier used in query results. Required '
            'for category/text/range; `any`/`custom` use fixed ids.',
      ),
      'name': S.string(description: 'Human-visible label.'),
      'min': S.number(description: 'Inclusive lower bound (range/any/custom).'),
      'max': S.number(description: 'Inclusive upper bound (range/any/custom).'),
      'divisions': S.integer(description: 'Slider divisions (range).'),
      'inputLabel': S.string(description: 'Label for custom range input.'),
      'minHintText': S.string(description: 'Hint for custom min field.'),
      'maxHintText': S.string(description: 'Hint for custom max field.'),
      'selectionMode': S.string(
        description: 'category only.',
        enumValues: ['single', 'multiple'],
      ),
      'layout': S.object(
        description:
            'category only: {"kind": "list"|"grid"|"chip"|"counter"'
            '|"range", ...}; grid also needs crossAxisCount.',
        additionalProperties: true,
      ),
      'header': S.object(
        description:
            'category only: a branch node whose `children` render as a chip '
            'row pinned above the category children (e.g. `{"type":"any"}` '
            'as a reset).',
        additionalProperties: true,
      ),
      'footer': S.object(
        description:
            'category only: a branch node whose `children` render as a chip '
            'row pinned below the category children.',
        additionalProperties: true,
      ),
      'immediate': S.boolean(
        description: 'Apply the pick without waiting for the apply button.',
      ),
      'enabled': S.boolean(description: 'false disables the entry.'),
      'children': S.list(
        description:
            'Nested nodes with the same shape as this object '
            '(recursion depth is unlimited).',
        items: S.object(additionalProperties: true),
      ),
    },
    required: const ['type'],
  );

  /// Schema for a list of root entry nodes (the `entries` payload).
  static Schema tree() => S.list(
    description: 'Root select entries; top-level nodes are categories.',
    minItems: 1,
    items: node(),
  );
}
