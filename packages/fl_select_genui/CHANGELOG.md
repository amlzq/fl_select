## Unreleased

- **BREAKING** Move from `genui` to the A2UI Dart SDKs `a2ui_core` (`^0.6.0`) and `a2ui_flutter` (`^0.2.0`). Agents keep speaking A2UI v0.9.

- **BREAKING** `FlSelectCatalogItems.select` is an `a2ui_flutter` `ComponentImplementation` instead of a genui `CatalogItem`, `all` returns `List<ComponentImplementation>`, and `asCatalog()` returns a `CatalogImplementation` with the id `fl_select`. Register them with a `MessageProcessor` and render surfaces with `A2uiSurface`, as the README shows. `dataSchema` and `widgetBuilder` are now `schema` and `builder`; `exampleData` and `isImplicitlyFlexible` are gone, since `ComponentImplementation` has neither.

- **BREAKING** The `MessageProcessor` checks every `Select` payload against its schema before rendering it. A payload with a wrong type, an unknown `delegate` token, empty `entries`, or a property the schema does not declare (such as `weight` or `accessibility`) is rejected with a `VALIDATION_FAILED` error instead of rendering a fallback or the error card. Payloads that match the schema but are still invalid render the error card as before.

- **IMPROVEMENT** The example app renders through `MessageProcessor` and `A2uiSurface`, and its Agent chat page prompts the model through `a2ui_agent`, which asks for `<a2ui-json>` blocks instead of fenced JSON.

## 0.8.0

- **BREAKING** Remove the `flatten` and `chips` delegate tokens; use `wrap` or `sideNav` instead ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#delegate-token-routing)).

- **IMPROVEMENT** `Select` accepts optional `defaultLayout` and `isScrollable`, and `tabNav` scrolls on its own when its tabs do not fit.

- **IMPROVEMENT** The example app gains an Agent chat page that talks to a real model.

- **BUGFIX** `Select` keeps its search text and selection when its parent rebuilds.

- **BUGFIX** Malformed `crossAxisCount`, `flatKey` or `delegate` values no longer throw.

## 0.7.0

- **IMPROVEMENT** Bump fl_select to `^0.17.0` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#fl_select-bumped-to-0170)).

- **IMPROVEMENT** Follow fl_select onto the standalone `material_ui` package — add the `material_ui: ^1.6.0` dependency and raise the minimum SDK to Dart ^3.13.5 / Flutter 3.47 ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#material_ui)).

- **IMPROVEMENT** Bump genui to `^0.10.4`.

- **IMPROVEMENT** upgrade the shipped agent skill for the Dart Skills CLI 1.0.x: rename it from `fl_select_genui-code-generation` to `fl-select-genui-code-generation` (hyphen-only names, as required by the Agent Skills spec), quote its frontmatter `description`, add the `## Instructions` / `## Guidelines` sections introduced by the 1.0.1 template, and document the 1.0.x `skills get --all` / `--package` invocations in the README.

## 0.6.0

- **IMPROVEMENT** Bump fl_select to `^0.16.0` ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-060)).

- **FEATURE** Document fl_select 0.16.0's `cascading` category layout for the agent ([Migration guide](https://github.com/amlzq/fl_select/blob/main/packages/fl_select_genui/MIGRATION.md#migrate-to-060)).

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

- **FEATURE** Add selection write-back: user selections are stored at `<id>.value` as a `Map<String, List<String>>` (same shape as fl_select's `toQueryMap()`).

- **FEATURE** Add `FlSelectCatalogItems.systemPromptFragment` and catalog registration helpers (`.asCatalog()` / `.all`).

- Invalid agent payloads render an inline error card instead of crashing.
