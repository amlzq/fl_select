---
name: fl-select-genui-code-generation
description: "A2UI bridge for fl_select — registers a `Select` catalog component (`FlSelectCatalogItems.select` / `.all` / `.asCatalog()`) with an A2UI `MessageProcessor` (package:a2ui_core, package:a2ui_flutter) so AI agents render real fl_select panels from JSON payloads (`delegate` plus an `entries` tree in `SelectEntryCodec` format) and receive selections back as a map of string lists, written to the surface's data model per payload. Also covers `FlSelectCatalogItems.systemPromptFragment` and the `SelectEntrySchema` JSON Schema. This skill should be used when integrating fl_select with the A2UI Dart SDKs, building A2UI or chat surfaces with catalog components, authoring or debugging `Select` agent payloads, or handling selection write-back in A2UI data models. For the fl_select widgets, delegates, and entry trees themselves, use the `fl-select-code-generation` skill shipped with fl_select."
---

# fl_select_genui

A2UI integration for [fl_select](https://pub.dev/packages/fl_select): exposes a real selection panel as an A2UI catalog component (`ComponentImplementation`) so conversational AI agents can render interactive selection UIs inside chat surfaces — and receive the user's selections back as structured query data.

```
agent ──Select payload (JSON)──▶ fl_select panel ──onChanged──▶ Map<String, List<String>> at <id>.value
```

## Instructions

1. Register the catalog — add `FlSelectCatalogItems.all` to the catalog the `MessageProcessor` renders with (see [Wiring it up](#wiring-it-up)); `asCatalog()` is available when you need the whole `fl_select` catalog.
2. Append `FlSelectCatalogItems.systemPromptFragment` to the agent's system prompt so it learns the `Select` payload vocabulary.
3. Emit (or debug) a payload with a required `delegate` plus a non-empty `entries` tree in `SelectEntryCodec` format; add `flatKey` whenever the top level is flat.
4. Read the selection back from the surface's data model at `<id>.value` as a `Map<String, List<String>>` — do not intercept `onChanged` yourself.
5. Use `SelectEntrySchema.node()` / `.tree()` when you need the JSON Schema of an entry tree. The `MessageProcessor` rejects payloads that do not match the `Select` schema; other invalid payloads render the inline error card rather than crashing.

## Requirements

Requires `fl_select: ^0.17.0`, `a2ui_core: ^0.6.0` and `a2ui_flutter: ^0.2.0`. The minimum SDK is Dart ^3.13.5 / Flutter 3.47, because fl_select renders through the standalone `material_ui` package — the host app should import `material_ui` rather than the SDK's Material library so the `MaterialApp` and the rendered select share one Material library. Payloads are unaffected by these versions.

## Wiring it up

```dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/v0_9/basic_catalog.dart' as v0_9;
import 'package:fl_select_genui/fl_select_genui.dart';

final processor = MessageProcessor<ComponentImplementation>(
  catalogs: [
    v0_9.basicCatalog().copyWith(
      components: [...v0_9.BasicComponents.all, ...FlSelectCatalogItems.all],
    ),
  ],
);

// Pass the agent's A2UI messages to processor.processMessages(...) and render
// each surface it creates with A2uiSurface(surface: surface).

// Append to your agent's system prompt so it learns the Select vocabulary:
FlSelectCatalogItems.systemPromptFragment;
```

The API surface hangs off `FlSelectCatalogItems`:

- `select` — the `ComponentImplementation` for the `Select` payload type (backed by `SelectView`).
- `all` — every catalog component (currently `[select]`).
- `asCatalog()` — the whole catalog (id `'fl_select'`), ready for `MessageProcessor(catalogs: [...])`.
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

## Guidelines

Required: `delegate` + a non-empty `entries` array.

- `delegate`: `list` / `grid` (with `crossAxisCount`) / `wrap` (flat chip cloud) / `cascading` (drill-down tree) / `tabNav` (category tabs) / `sideNav` (recommended for category data — left rail) / `expandable` (accordion groups). A `category` tree at the top level is required by `cascading` / `tabNav` / `sideNav` / `expandable`; `list` / `grid` / `wrap` take flat nodes. Use `wrap` for flat chips and `sideNav` for categories. A bad `crossAxisCount` falls back to 3 columns. Layouts auto-fallback to match the `entries` shape, so a category layout on flat data (or vice versa) never asserts.
- `selectionMode`: `single` / `multiple` (default `multiple`). `search`: boolean.
- `defaultLayout` (optional; `tabNav` / `sideNav` / `expandable` only): the layout used by categories that do not set their own `layout`, in the same `{"kind": ...}` shape, e.g. `{"kind":"chip"}` or `{"kind":"grid","crossAxisCount":2}`. A value that is not an object is rejected by the schema, and a malformed layout object renders the error card. Without it `sideNav` falls back to a spaced chip wrap and the others to their own default.
- `isScrollable` (optional boolean; `tabNav` / `sideNav` / `cascading` only): whether the tab bar / category rail scrolls. When omitted, `tabNav` scrolls automatically if its category names do not fit the available width, `sideNav` scrolls, and `cascading` does not; an explicit value always wins.
- `flatKey`: required when the top-level entries are not categories (flat panel) — the key the selection is written back under, e.g. `"sort"`; ignored for category trees.
- `entries`: an entry tree in the `SelectEntryCodec` JSON format. Node `type`s: `category` (optional `selectionMode`, `layout`, and `header`/`footer` — branch nodes whose `children` render as a single-row chip bar pinned above/below the category children, each row taking an optional `headerSelectionMode`/`footerSelectionMode` and otherwise inheriting the category's mode; `layout` picks how the category's children render — `{"kind":"list"}`, `{"kind":"grid","crossAxisCount":3}`, `{"kind":"chip"}`, `{"kind":"counter"}` and `{"kind":"range"}` render one level, while `{"kind":"cascading","isScrollable":true}` renders one column per level and drills into nested children at unlimited depth; only the category delegates (`tabNav` / `sideNav` / `expandable`) hand a category to its `layout` — `delegate: cascading` always renders columns and ignores it), `text` (option or sub-branch), `range` (`min`/`max`/`divisions`), `any` (reset sentinel — omit `id`), `custom` (user-typed range, `minHintText`/`maxHintText`). A `header`/`footer` row renders chips only, so its `children` must not contain a `custom` entry — a custom range entry is rejected with the error card; put it under the category's own `children` instead. Siblings — the top-level entries, one node's `children`, and a `header`/`footer` row — must carry distinct `id`s; the same `id` may still be reused under a different parent (the built-in `any`/`custom` entries rely on that). Do not author `parentId`: it is derived from the tree, and is not part of the payload format.

## Selection write-back

Selections are written to the surface's data model at `<id>.value` as a `Map<String, List<String>>`:

- Category trees — same shape as fl_select's `toQueryMap()` (e.g. `{"price": ["0-100"], "amenities": ["wifi", "pool"]}`); a selected category without leaf picks maps to its own id.
- Flat panels — `{flatKey: [ids]}` (fl_select's `toIdList()`).
- An empty selection writes `{}`.

The `MessageProcessor` rejects a payload that does not match the `Select` schema (a wrong type, an unknown `delegate` token, empty `entries`, or a property the schema does not declare) with a `VALIDATION_FAILED` error, so it never renders. Other invalid payloads (a flat panel missing `flatKey`, a `custom` entry inside a `header`/`footer`, a malformed `defaultLayout` object, or an entry tree fl_select rejects — duplicate sibling ids, a non-category entry beside a category) render an inline error card instead of crashing.

Package: <https://pub.dev/packages/fl_select_genui> · fl_select: <https://pub.dev/packages/fl_select>
