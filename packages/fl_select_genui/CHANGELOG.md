## 0.2.1

- **FEATURE** flat (non-category) panels: add the required payload-level `flatKey` under which the selection is written back.

## 0.2.0

- **FEATURE** Wire the `search` payload flag through to the delegates' `searchEnabled`.

- **DEPRECATION** Rename the catalog item to `Select` (`FlSelectCatalogItems.select`, payload type `Select`). The old `FlSelectCatalogItems.selectFilter` getter and the `SelectFilter` payload type keep working as deprecated aliases; both will be removed in a future minor release.

- **IMPROVEMENT** Bump fl_select to `^0.12.0`.

## 0.1.0

- **FEATURE** Add `tabNav`, `sideNav` and `expandable` as first-class `delegate` tokens.

- **IMPROVEMENT** Route all `delegate` tokens to fl_select's single-purpose delegates instead of the deprecated dual-mode paths — rendering is unchanged for existing payloads.

## 0.0.1

- Initial experimental release.

- **FEATURE** Add `FlSelectCatalogItems.selectFilter`: renders a fl_select panel (`SelectView`) from an agent-authored JSON payload — delegate (list / grid / flatten / cascading), `selectionMode`, `crossAxisCount`, and an `entries` tree in the `SelectEntryCodec` format.

- **FEATURE** Add selection write-back: user selections are stored at `<id>.value` as a  `Map<String, List<String>>` (same shape as fl_select's `toQueryMap()`).

- **FEATURE** Add `FlSelectCatalogItems.systemPromptFragment` and catalog registration helpers (`.asCatalog()` / `.all`).

- Invalid agent payloads render an inline error card instead of crashing.
