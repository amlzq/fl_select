[GenUI SDK](https://pub.dev/packages/genui) (A2UI) integration for
[fl_select](https://pub.dev/packages/fl_select): exposes fl_select filter
panels as `CatalogItem`s so conversational AI agents can render real,
interactive filter UIs inside chat surfaces — and receive the user's
selections back as structured query data.

```
agent ──JSON payload──▶ SelectFilter (fl_select UI) ──selection──▶ Map<String, List<String>>
```

## How it works

1. You register [`FlSelectCatalogItems.asCatalog()`] (or `.all`) with your
   GenUI `SurfaceController` alongside the core catalog.
2. Your agent's system prompt includes
   [`FlSelectCatalogItems.systemPromptFragment`], which teaches it the
   `SelectFilter` vocabulary.
3. When the user needs to narrow down results, the agent emits a
   `SelectFilter` payload — a `delegate` (list / grid / wrap / cascading /
   tabNav / sideNav / expandable) plus an `entries` tree authored
   in the `SelectEntryCodec` JSON format.
4. The user interacts with a real fl_select panel; selections are written
   back to the GenUI data model at `<id>.value` as a
   `Map<String, List<String>>` (same shape as fl_select's `toQueryMap`),
   ready for the next agent turn or your query layer.

Invalid agent payloads render an inline error card instead of crashing.

## Usage

```dart
import 'package:fl_select_genui/fl_select_genui.dart';
import 'package:genui/genui.dart';

final controller = SurfaceController(
  catalogs: [
    CoreCatalogItems.asCatalog().copyWith(
      newItems: FlSelectCatalogItems.all,
    ),
  ],
  // ...agent transport
);

// System prompt:
FlSelectCatalogItems.systemPromptFragment;
```

See [`example/`](example/) for an end-to-end demo of the payload →
render → write-back loop.

## Entry tree format

```json
{"type": "category", "id": "price", "name": "Price", "children": [
  {"type": "any", "name": "Any"},
  {"type": "range", "id": "0-100", "name": "$0 - $100", "min": 0, "max": 100},
  {"type": "custom", "name": "Custom", "min": 0, "max": 1000}
]}
```

Node `type`s: `category` (group, optional `selectionMode` / `layout`),
`text` (option or sub-branch), `range` (slider), `any` (reset sentinel),
`custom` (user-typed range). See `SelectEntrySchema` for the generated
JSON Schema and `FlSelectCatalogItems.systemPromptFragment` for the
agent-facing documentation.
