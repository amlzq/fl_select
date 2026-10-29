# Theme reference

How `fl_select` resolves colors and styles, and which global token reaches which
widget. For setup examples see the *Theming* section of the
[README](../README.md).

## Resolution order

Every visual value is resolved from the most specific source to the least:

1. **Widget parameter**, e.g. `SelectListTile(selectedColor: ...)`.
2. **Component theme** in `SelectThemeData`, e.g. `listTileTheme.selectedColor`.
3. **Global token** in `SelectThemeData`, e.g. `selectedColor`.
4. **Material `ThemeData`**, e.g. `ColorScheme.primary`.

`SelectThemeData` is an override bag: every color and component field is
optional, and an unset value falls through to the next level. Defaults therefore
follow the surrounding `ThemeData` (light/dark switches, seed colors).

Resolve global tokens with the helpers on `SelectTheme` rather than reading
`SelectTheme.of(context)` fields directly:

| Helper | Falls back to |
| --- | --- |
| `SelectTheme.selectedColorOf` | `ColorScheme.primary` |
| `SelectTheme.onSelectedColorOf` | `ColorScheme.onPrimary` |
| `SelectTheme.backgroundColorOf` | `ColorScheme.surface` |
| `SelectTheme.onBackgroundColorOf` | `ColorScheme.onSurface` |
| `SelectTheme.radioThemeOf` | `ThemeData.radioTheme` |
| `SelectTheme.checkboxThemeOf` | `ThemeData.checkboxTheme` |

## Global tokens

### `selectedColor`

The accent of selected entries.

| Widget | What it colors |
| --- | --- |
| `SelectListTile` | Selected text, icon and check mark |
| `SelectGridTile`, `SelectFieldTile` | Default `selectedTileColor` (blended into the background in dark mode); selected text on outlined tiles and on light filled tiles |
| `SelectChip` (chip bar, wrap view) | Default `selectedChipColor`; selected label of outlined chips |
| `SelectTabBar` | Default selected color |
| `SelectSideBar` | Default selected color and indicator |
| `SelectExpansionTile` | Selected title |
| `SelectCounter` | Selected value |
| `SelectRangeSlider` | Selected color, active track and thumb border |
| Side-nav and cascading select | Selected color handed to the category sidebar |

### `onSelectedColor`

Text and icon color on top of a **filled** selected surface.

| Widget | What it colors |
| --- | --- |
| `SelectGridTile`, `SelectFieldTile` (filled) | Selected text |
| `SelectChip` (filled) in chip bar and wrap view | Selected label |

Without it, filled tiles and chips pick white or black from the brightness of
their background. It is applied regardless of `selectedTileColor` /
`selectedChipColor`, so pair it with those when you customize them. Outlined
variants are not affected.

### `backgroundColor`

The base surface of the panel.

| Widget | What it colors |
| --- | --- |
| `SelectPanel` | Panel background |
| `SelectActionBar`, `SelectTabBar` | Default bar background |
| `SelectSideBar` | Default sidebar background |
| `SelectCascadingView` | Start of the column background ramp |
| Tiles, chips, range slider | Base for the dark-mode tile and chip colors |

### `onBackgroundColor`

The default **unselected** text color on the panel.

| Widget | What it colors |
| --- | --- |
| `SelectListTile`, `SelectGridTile`, `SelectFieldTile` | Unselected text |
| `SelectChip` | Unselected label |
| `SelectCounter` | Unselected value |

Unset, these use `ColorScheme.onSurfaceVariant` (not `onSurface`, which is what
`SelectTheme.onBackgroundColorOf` returns).

### `radioTheme` and `checkboxTheme`

Used by the radio and checkbox controls of `SelectListTile` variants. Unset,
the ambient `ThemeData.radioTheme` / `ThemeData.checkboxTheme` apply.

### Deprecated

`backgroundColorHigh`, `backgroundColorHighest` and `onBackgroundColorHighest`
are no longer read by any widget and are ignored by `==`. Use the component
themes' own colors instead.

## Exceptions to the order

- A color on an explicit `selectedLabelStyle` (widget parameter or
  `chipBarTheme` / `wrapViewTheme`) wins over `onSelectedColor` and the
  brightness-derived label color. Other style properties are kept either way.
- A `TextStyle` passed as `labelStyle` to `SelectGridTile` refines the tile's
  compact base style; the color always comes from the color tokens.

## Merging

- `SelectTheme.merge(data: ...)` layers a partial `SelectThemeData` over the
  ambient one. A color or control theme is replaced only when the new data sets
  it; each component theme is merged field by field.
- A merge can add or replace values but cannot reset an inherited one back to
  unset.
- Delegate-level theme and color fields are merged on top of the ambient
  theme when the panel is built.
- `PopupSelectBar` and `PopupSelectButton` take their `selectTheme` from the
  widget or from the `PopupSelectBarTheme` / `PopupSelectButtonTheme` extension.
  Inside the popup it is merged over any `SelectTheme` the overlay inherits,
  so values the trigger's theme leaves unset keep the ambient value.

## Adding a themed field

1. Add the field to the component theme's constructor, `copyWith`, `merge`,
   `lerp`, `==` and `hashCode`.
2. Add it to the matching entry in `test/select/component_theme_fields_test.dart`
   (the `_values` table and the theme's field list); the test fails if any of
   the five is missed.
3. Read it in the widget with the order above, and add a row to this document if
   it is a global token.
