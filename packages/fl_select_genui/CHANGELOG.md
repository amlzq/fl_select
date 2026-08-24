## 0.1.0

- Initial experimental release.

- **FEATURE** `FlSelectCatalogItems.selectFilter`: a GenUI (A2UI) `CatalogItem` that renders a full fl_select panel (`SelectView`) from an agent-authored JSON payload — `delegate` (list / grid / flatten / cascading), `selectionMode`, `crossAxisCount`, and an `entries` tree in the `SelectEntryCodec` JSON format (powered by fl_select's new `SelectEntryCodec`).

- **FEATURE** selection write-back: user selections are written to the GenUI data model at `<id>.value` as a `Map<String, List<String>>` (same shape as fl_select's `toQueryMap()`), ready for the next agent turn or a query layer.

- **FEATURE** `FlSelectCatalogItems.systemPromptFragment`: agent-facing documentation of the `SelectFilter` vocabulary, ready to embed in a system prompt.

- **FEATURE** `FlSelectCatalogItems.asCatalog()` / `.all` / `.selectFilter` registration helpers for `SurfaceController`.

- Invalid agent payloads render an inline error card instead of crashing.
