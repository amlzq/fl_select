# Migration Guide

## MIGRATE TO 0.3.0

### Agent skill shipped inside the package

The package now ships a Dart Skills CLI (0.3.1) agent skill at
`skills/fl_select_genui-code-generation`: projects depending on
`fl_select_genui` auto-discover and install it via `skills get`. It covers:

- catalog registration (`FlSelectCatalogItems`, `.asCatalog()` / `.all`);
- authoring `Select` payloads (`delegate` + `entries` in the
  `SelectEntryCodec` format);
- selection write-back (`<id>.value`, `flatKey`);
- `systemPromptFragment` and `SelectEntrySchema`.

No code changes are required — the skill is additive.

### fl_select bumped to `^0.13.0`

fl_select 0.13.0 removes and internalizes several symbols; none of them are
referenced by this package, so no source changes were needed:

| fl_select 0.13.0 change | Why fl_select_genui is unaffected |
| --- | --- |
| `FlattenSelectDelegate` removed; `GridSelectDelegate` / `ListSelectDelegate` are flat-only now | every `delegate` token already routes to the single-purpose delegates (see the routing table under 0.1.0) |
| `SelectItemBuilder` gains `categoryId` and returns `Widget?` | the catalog never passes an `itemBuilder` |
| Panel widgets internalized (deprecated aliases) | rendering goes through the public entry point `SelectView` only |
| `SelectListViewState` / `SelectGridViewState` private, `SkeletonBuilder` removed | not referenced |
| Dart `^3.10.0` / Flutter 3.35.7 minimum | already this package's constraints |

Agent payloads are unaffected: existing JSON keeps rendering identically.

## MIGRATE TO 0.2.0

The catalog item is renamed to `Select` to reflect that it is a selection
component, not a filter panel.

| | up to 0.1.0 | Next |
| --- | --- | --- |
| Dart getter | `FlSelectCatalogItems.selectFilter` | `FlSelectCatalogItems.select` |
| payload `type` | `SelectFilter` | `Select` |

The old getter and payload type keep working as deprecated aliases; both will
be removed in a future minor release. Update the agent system prompt to the
latest `FlSelectCatalogItems.systemPromptFragment` (it now documents `Select`
and keeps accepting legacy `SelectFilter` payloads).

## MIGRATE TO 0.1.0

The `delegate` token now routes to fl_select's single-purpose delegates instead
of the deprecated dual-mode paths ([fl_select migration](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-0110)).
No payload changes are required — every legacy token keeps rendering the same
panel (the deprecated paths already forwarded to the same delegates) — and no
deprecated delegate is constructed anymore. New tokens are registered in the
schema `enum` and the system prompt fragment.

### Delegate token routing

| payload `delegate` | category data | flat data |
| --- | --- | --- |
| `tabNav` (new) | `TabNavSelectDelegate` | falls back to `ListSelectDelegate` |
| `sideNav` (new) | `SideNavSelectDelegate` | falls back to `ListSelectDelegate` |
| `expandable` (new) | `ExpandableSelectDelegate` | falls back to `ListSelectDelegate` |
| `grid` | `TabNavSelectDelegate`¹ | `GridSelectDelegate` |
| `wrap` / `chips` / `flatten` | `SideNavSelectDelegate` | `WrapSelectDelegate` |
| `list` (default) / unknown | `ExpandableSelectDelegate` | `ListSelectDelegate` |
| `cascading`² | `CascadingSelectDelegate` | `CascadingSelectDelegate` |

¹ `crossAxisCount` maps onto the delegate's `defaultLayout` grid.
² `cascading` is a multi-level cascade (unlimited depth), not one of the two-level category layouts — it renders both entry-tree shapes natively and ignores `category.layout`.

### Recommendations for new payloads

- Two-level (category) data: prefer `sideNav` (one scrollable panel with a
  left category rail) or `tabNav` (category tabs on top); use `expandable`
  for accordion groups.
- Flat data: prefer `wrap` for a chip cloud; `"flatten"` and `"chips"` keep
  working as aliases.
