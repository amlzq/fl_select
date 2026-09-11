---
name: fl_select_genui-code-generation
description: GenUI SDK (A2UI) bridge for fl_select — registers a `Select` CatalogItem (`FlSelectCatalogItems.select` / `.all` / `.asCatalog()`) with a GenUI `SurfaceController` so AI agents render real fl_select panels from JSON payloads (`delegate` + `entries` tree in `SelectEntryCodec` format) and receive selections back as `Map<String, List<String>>` at `<id>.value`. Also covers `FlSelectCatalogItems.systemPromptFragment` and the `SelectEntrySchema` JSON Schema. Use this skill when integrating fl_select with the GenUI SDK (package:genui), building A2UI/chat surfaces with catalog items, authoring or debugging `Select` / `SelectFilter` agent payloads, or handling selection write-back in GenUI data models. For fl_select widgets, delegates, and entry trees themselves, use the `fl_select-code-generation` skill shipped with fl_select.
---

# fl_select_genui

GenUI SDK (A2UI) integration for [fl_select](https://pub.dev/packages/fl_select): exposes a real selection panel as a GenUI `CatalogItem` so conversational AI agents can render interactive selection UIs inside chat surfaces — and receive the user's selections back as structured query data.

```
agent ──Select payload (JSON)──▶ fl_select panel ──onChanged──▶ Map<String, List<String>> at <id>.value
```

## Wiring it up

```dart
import 'package:fl_select_genui/fl_select_genui.dart';
import 'package:genui/genui.dart';

final controller = SurfaceController(
  catalogs: [
    BasicCatalogItems.asCatalog().copyWith(newItems: FlSelectCatalogItems.all),
  ],
);

// Append to your agent's system prompt so it learns the Select vocabulary:
FlSelectCatalogItems.systemPromptFragment;
```

The API surface hangs off `FlSelectCatalogItems`:

- `select` — the `CatalogItem` for the `Select` payload type (backed by `SelectView`).
- `all` — `[select, selectFilter]`; includes the deprecated `SelectFilter` payload alias so legacy agent payloads keep rendering (the alias will be dropped in a future minor release).
- `asCatalog()` — the whole catalog (`catalogId: `fl_select`), ready for `SurfaceController(catalogs: [...])`.
- `systemPromptFragment` — const string documenting the payload format for agents.
- `SelectEntrySchema.node()` / `.tree()` — the generated JSON Schema of the entry tree.

## Select payload (what the agent emits)

```json
{
  "delegate": "sideNav",
  "selectionMode": "multiple",
  "entries": [
    {"type": "category", "id": "price", "name": "Price", "children": [
      {"type": "any", "name": "Any"},
      {"type": "range", "id": "0-100", "name": "$0 - $100", "min": 0, "max": 100},
      {"type": "custom", "name": "Custom", "min": 0, "max": 1000}]},
    {"type": "category", "id": "amenities", "name": "Amenities", "children": [
      {"type": "text", "id": "wifi", "name": "Wi-Fi"},
      {"type": "text", "id": "pool", "name": "Pool"}]}
  ]
}
```

Required: `delegate` + a non-empty `entries` array.

- `delegate`: `list` / `grid` (with `crossAxisCount`) / `wrap` (flat chip cloud) / `cascading` (drill-down tree) / `tabNav` (category tabs) / `sideNav` (recommended for category groups — left rail) / `expandable` (accordion groups). `flatten` is a legacy alias. Layouts auto-fallback to match the `entries` shape, so a grouped layout on flat data (or vice versa) never asserts.
- `selectionMode`: `single` / `multiple` (default `multiple`). `search`: boolean.
- `flatKey`: required when the top-level entries are not categories (flat panel) — the key the selection is written back under, e.g. `"sort"`; ignored for category trees.
- `entries`: an entry tree in the `SelectEntryCodec` JSON format. Node `type`s: `category` (optional `selectionMode`, `layout` such as `{"kind":"grid","crossAxisCount":3}`, and `header`/`footer` chip rows), `text` (option or sub-branch), `range` (`min`/`max`/`divisions`), `any` (reset sentinel — omit `id`), `custom` (user-typed range, `minHintText`/`maxHintText`).

## Selection write-back

Selections are written to the GenUI data model at `<id>.value` (or the payload's `path` when provided) as a `Map<String, List<String>>`:

- Category trees — same shape as fl_select's `toQueryMap()` (e.g. `{"price": ["0-100"], "amenities": ["wifi", "pool"]}`); a selected category without leaf picks maps to its own id.
- Flat panels — `{flatKey: [ids]}` (fl_select's `toIdList()`).
- An empty selection writes `{}`.

Invalid payloads (malformed JSON, empty `entries`, or a flat panel missing `flatKey`) render an inline error card instead of crashing.

Package: <https://pub.dev/packages/fl_select_genui> · fl_select: <https://pub.dev/packages/fl_select>
