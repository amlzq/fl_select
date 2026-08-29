# Migration Guide

## MIGRATE TO Next

The `delegate` token now routes to fl_select's single-purpose delegates instead
of the deprecated dual-mode paths ([fl_select migration](https://github.com/amlzq/fl_select/blob/main/packages/fl_select/MIGRATION.md#migrate-to-next)).
No payload changes are required — every legacy token keeps rendering the same
panel — but new tokens are available.

### Delegate token routing

| payload `delegate` | two-level (category) data | flat data |
| --- | --- | --- |
| `tabNav` (new) | `TabNavSelectDelegate` | falls back to `ListSelectDelegate` |
| `sideNav` (new) | `SideNavSelectDelegate` | falls back to `ListSelectDelegate` |
| `expandable` (new) | `ExpandableSelectDelegate` | falls back to `ListSelectDelegate` |
| `grid` | `TabNavSelectDelegate`¹ | `GridSelectDelegate` |
| `wrap` / `chips` / `flatten` | `SideNavSelectDelegate` | `WrapSelectDelegate` |
| `list` (default) / unknown | `ExpandableSelectDelegate` | `ListSelectDelegate` |
| `cascading` | `CascadingSelectDelegate` | `CascadingSelectDelegate` |

¹ `crossAxisCount` maps onto the delegate's `defaultLayout` grid.

### Recommendations for new payloads

- Two-level (category) data: prefer `sideNav` (one scrollable panel with a
  left category rail) or `tabNav` (category tabs on top); use `expandable`
  for accordion groups.
- Flat data: prefer `wrap` for a chip cloud; `"flatten"` and `"chips"` keep
  working as aliases.
