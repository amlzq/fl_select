## 0.0.1

- Initial experimental release.

- **FEATURE** Add `FlSelectCatalogItems.selectFilter`: renders a fl_select panel (`SelectView`) from an agent-authored JSON payload — delegate (list / grid / flatten / cascading), `selectionMode`, `crossAxisCount`, and an `entries` tree in the `SelectEntryCodec` format.

- **FEATURE** Add selection write-back: user selections are stored at `<id>.value` as a  `Map<String, List<String>>` (same shape as fl_select's `toQueryMap()`).

- **FEATURE** Add `FlSelectCatalogItems.systemPromptFragment` and catalog registration helpers (`.asCatalog()` / `.all`).

- Invalid agent payloads render an inline error card instead of crashing.
