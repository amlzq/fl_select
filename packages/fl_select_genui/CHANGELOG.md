## Next

- **FEATURE** add the `tabNav`, `sideNav` and `expandable` delegate tokens (schema `enum`, system prompt and routing): `tabNav` renders a `TabNavSelectDelegate` (category tabs on top), `sideNav` a `SideNavSelectDelegate` (left category rail; recommended for category groups), `expandable` an `ExpandableSelectDelegate` (accordion groups). `wrap` (with its `chips` alias) is now a first-class token for the flat chip cloud.

- **IMPROVEMENT** route the `delegate` tokens to fl_select's single-purpose delegates instead of the deprecated dual-mode paths, tracking [fl_select's Next migration](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-next). Rendering is unchanged for existing payloads (the deprecated paths already forwarded to the same delegates), but no deprecated delegate is constructed anymore:
  - `flatten` / `chips` / `wrap` now route by data shape — flat data renders `WrapSelectDelegate`, two-level data renders `SideNavSelectDelegate` — instead of the deprecated `FlattenSelectDelegate`; `"flatten"` remains as a legacy alias.
  - `grid` with two-level data renders `TabNavSelectDelegate` directly, with `crossAxisCount` mapped onto its `defaultLayout` grid, instead of the deprecated `GridSelectDelegate` two-level path; `grid` with flat data is unaffected.
  - the `list` fallback renders `ExpandableSelectDelegate` for two-level data and `ListSelectDelegate` for flat data.

## 0.0.1

- Initial experimental release.

- **FEATURE** Add `FlSelectCatalogItems.selectFilter`: renders a fl_select panel (`SelectView`) from an agent-authored JSON payload — delegate (list / grid / flatten / cascading), `selectionMode`, `crossAxisCount`, and an `entries` tree in the `SelectEntryCodec` format.

- **FEATURE** Add selection write-back: user selections are stored at `<id>.value` as a  `Map<String, List<String>>` (same shape as fl_select's `toQueryMap()`).

- **FEATURE** Add `FlSelectCatalogItems.systemPromptFragment` and catalog registration helpers (`.asCatalog()` / `.all`).

- Invalid agent payloads render an inline error card instead of crashing.
