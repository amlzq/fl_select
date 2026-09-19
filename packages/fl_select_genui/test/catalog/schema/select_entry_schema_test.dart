import 'dart:convert';

import 'package:fl_select_genui/src/catalog/schema/select_entry_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// The `type` discriminator values the payload supports, mirroring the switch
/// in `SelectEntryCodec.fromJson` (package:fl_select).
const List<String> _nodeTypes = ['category', 'text', 'range', 'any', 'custom'];

/// Every field a node may carry, mirroring what `SelectEntryCodec` reads.
/// Listing them here makes a drift on either side fail this test.
const List<String> _nodeFields = [
  'type',
  'id',
  'name',
  'min',
  'max',
  'divisions',
  'inputLabel',
  'minHintText',
  'maxHintText',
  'selectionMode',
  'layout',
  'header',
  'footer',
  'immediate',
  'enabled',
  'children',
];

ObjectSchema _node() => SelectEntrySchema.node() as ObjectSchema;

ListSchema _tree() => SelectEntrySchema.tree() as ListSchema;

/// Serialized form of a schema, so two independently built schemas can be
/// compared by value instead of by instance identity.
Object? _json(Schema schema) => jsonDecode(schema.toJson());

void main() {
  group('SelectEntrySchema.node', () {
    test('requires only the "type" discriminator', () {
      final node = _node();
      expect(node.type, 'object');
      expect(node.required, ['type']);
      expect(node.properties, isNotNull);
    });

    test('enumerates exactly the node types the codec decodes', () {
      expect(_node().properties!['type']!.enumValues, _nodeTypes);
    });

    test('documents exactly the fields a node may carry', () {
      expect(_node().properties!.keys, unorderedEquals(_nodeFields));
    });

    test('describes every field for the agent', () {
      for (final property in _node().properties!.entries) {
        expect(
          property.value.description,
          isNotEmpty,
          reason: '"${property.key}" would reach the agent undocumented',
        );
      }
    });

    test('types the fields the codec casts', () {
      final properties = _node().properties!;
      expect(properties['type']!.type, 'string');
      expect(properties['id']!.type, 'string');
      expect(properties['name']!.type, 'string');
      expect(properties['min']!.type, 'number');
      expect(properties['max']!.type, 'number');
      expect(properties['divisions']!.type, 'integer');
      expect(properties['immediate']!.type, 'boolean');
      expect(properties['enabled']!.type, 'boolean');
      expect(properties['layout']!.type, 'object');
      expect(properties['header']!.type, 'object');
      expect(properties['footer']!.type, 'object');
      expect(properties['selectionMode']!.enumValues, ['single', 'multiple']);
    });

    test('leaves "children" open since the builder cannot recurse', () {
      final children = _node().properties!['children']! as ListSchema;
      final items = children.items! as ObjectSchema;

      // A loose bag of same-shaped nodes: recursion is documented in prose
      // instead, because this schema builder has no `$ref`.
      expect(items.properties, isNull);
      expect(items.value['additionalProperties'], isTrue);
    });

    test('is rebuilt fresh, not shared mutable state', () {
      expect(_json(_node()), _json(_node()));
      expect(identical(_node(), _node()), isFalse);
    });
  });

  group('SelectEntrySchema.tree', () {
    test('is a non-empty list of node schemas', () {
      final tree = _tree();
      expect(tree.type, 'array');
      expect(tree.minItems, 1);
      expect(_json(tree.items!), _json(_node()));
    });

    test('points agents at flatKey for flat entry lists', () {
      expect(_tree().description, contains('flatKey'));
    });
  });
}
