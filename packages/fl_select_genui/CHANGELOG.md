## 0.5.0

- **IMPROVEMENT** Bump fl_select to `^0.15.0` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-050)).

- **IMPROVEMENT** Validate the decoded entry tree so that an invalid payload renders the schema error card ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-050)).

## 0.4.0

- **BREAKING** remove the deprecated `FlSelectCatalogItems.selectFilter` getter and the `SelectFilter` payload alias ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-020)).

- **BUGFIX** `"delegate": "cascading"` with flat (non-category) `entries` now falls back to the flat list delegate instead of crashing.

- **BUGFIX** a `custom` range entry inside a category `header`/`footer` now renders the schema error card instead of crashing the surface.

- **IMPROVEMENT** Bump fl_select to `^0.14.0`.

- **IMPROVEMENT** Keep the shipped agent skill validator-clean and in sync with the catalog.

## 0.3.0

- **FEATURE** Ship a Dart Skills CLI agent skill inside the package ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-030)).

- **IMPROVEMENT** Bump fl_select to `^0.13.0` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-030)).

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
