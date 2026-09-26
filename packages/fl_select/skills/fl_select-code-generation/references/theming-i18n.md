# Theming and internationalization

## Per instance

Delegates carry the styling. Quick path: `selectedColor` / `onSelectedColor`; fine-grained control via the `*Theme` fields:

| Field | Covers |
| --- | --- |
| `actionBarTheme` | Apply/Reset action bar |
| `searchBarTheme` | Built-in search bar |
| `tabBarTheme` | Category tabs (`TabNavSelectDelegate`) |
| `sideBarTheme` | Category sidebar (`CascadingSelectDelegate`) |
| `expansionTileTheme` | Category tiles (`ExpandableSelectDelegate`) |
| `listTileTheme` | List entries |
| `gridTileTheme` | Grid entries |
| `fieldTileTheme` | Min/max fields of custom range entries |
| `rangeSliderTheme` | Range slider entries |
| `wrapViewTheme` | Wrapping chip view (`WrapSelectDelegate` / chip layouts) |
| `chipBarTheme` | Legacy shared chip theme — only fills `wrapViewTheme` defaults |
| `panelTheme` | Panel background decoration (dialog/sheet panel) |

The same fields exist on `SelectThemeData` for app-wide styling, where a delegate's own value wins. `SelectThemeData` additionally carries the color fields (`selectedColor` / `onSelectedColor`, `backgroundColor` / `onBackgroundColor`, `backgroundColorHigh` / `backgroundColorHighest` / `onBackgroundColorHighest`) and `radioTheme` / `checkboxTheme` (`RadioThemeData` / `CheckboxThemeData`), which are global-only — per delegate you replace those controls with `radioBuilder` / `checkboxBuilder` instead.

```dart
ListSelectDelegate(
  entriesLoader: _fetchSort,
  selectedColor: Theme.of(context).colorScheme.primary,
  onSelectedColor: Theme.of(context).colorScheme.onPrimary,
);
```

`PopupSelectBar` also accepts a single `selectTheme` that overrides the styling of every tab's delegate:

```dart
PopupSelectBar(
  tabs: ...,
  selectDelegates: ...,
  selectTheme: SelectThemeData(Theme.of(context)),
  onApplied: (tabData, selected) {},
);
```

## Globally

Every select resolves its base theme from the ambient `SelectTheme` — an `InheritedTheme` carrying a `SelectThemeData` (read back via `SelectTheme.of(context)`), which falls back to a `SelectThemeData` derived from the Material `ThemeData` when none is in scope. Delegate-level theme fields merge field-wise on top of it. Wrap it above the `Navigator` so inline views, dialogs, sheets and popup overlays are all covered, and use `SelectTheme.merge` to layer a partial `SelectThemeData` over the ambient one:

```dart
MaterialApp(
  builder: (context, child) => SelectTheme.merge(
    data: SelectThemeData(Theme.of(context), selectedColor: Colors.teal),
    child: child!,
  ),
  home: const HomePage(),
);
```

Register `PopupSelectBarTheme` and `PopupSelectButtonTheme` as `ThemeData` extensions so every bar/button picks them up automatically:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      PopupSelectBarTheme(
        height: 48,
        labelColor: Colors.blue,
        selectTheme: SelectThemeData(ThemeData.light()),
      ),
      PopupSelectButtonTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    ],
  ),
);
```

`PopupSelectBarTheme` fields include `height`, `labelColor`, `unselectedLabelColor`, `labelStyle`, `unselectedLabelStyle`, `indicator`, `unselectedIndicator`, `overlayStyle`, `selectTheme`. `PopupSelectButtonTheme` fields include `backgroundColor`, `foregroundColor`, `iconColor`, `elevation`, `side`, `shape`, `textStyle`, `padding`, `overlayStyle`, `selectTheme`.

Precedence: widget parameter → `selectTheme` on the widget → theme extension → ambient `SelectTheme` → `SelectThemeData` derived from the Material `ThemeData`.

A `PopupSelectBar` / `PopupSelectButton` overlay sits above the trigger's route, so a `SelectTheme` wrapped around the trigger alone does not reach it — the trigger injects the `selectTheme` it resolved around the panel instead. Set the theme above the `Navigator`, or through those two extensions.

Chip styling: the wrapping chip view resolves `wrapViewTheme` (`SelectWrapViewTheme`: `variant` (filled/outlined), `chipColor`, `selectedChipColor`, `labelStyle`, `selectedLabelStyle`, `backgroundColor`, `padding`) — set it on the delegate or globally on `SelectThemeData`; a delegate's own value wins over the one on `SelectThemeData`. `SelectThemeData.chipBarTheme` is the shared chip-bar theme — the `SelectThemeData(...)` factory and `SelectThemeData.raw(...)` accept it by that name. It no longer styles the wrap view directly — it is folded into `wrapViewTheme` as a lowest-priority fallback (a field set on both resolves from `wrapViewTheme`), so prefer `wrapViewTheme`.

## Internationalization

Add `SelectLocalizationsDelegate()` to `MaterialApp`. It ships translations for `de`, `en`, `es`, `fr`, `id`, `ja`, `ko`, `pt`, `vi`, and `zh` (Hans/Hant), localizing the "Apply" / "Reset" / "Multiple" labels automatically, plus the screen-reader announcement strings (`panelOpened` / `panelClosed` / `cleared` / `applied` / `clearSearch`).

```dart
const localizationsDelegates = <LocalizationsDelegate>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  SelectLocalizationsDelegate(),
];

const supportedLocales = SelectLocalizationsDelegate.supportedLocales;

MaterialApp(
  localizationsDelegates: localizationsDelegates,
  supportedLocales: supportedLocales,
  home: const HomePage(),
);
```

To override the labels for a single delegate, set `applyText` / `resetText` on it directly.

## Accessibility

Screen-reader support is built in — nothing to switch on: tiles and chips are exposed as buttons carrying their `selected` / `enabled` state, `PopupSelectBar` / `PopupSelectButton` triggers report `expanded`, search fields get a localized label plus a labelled clear button, and slider thumbs report their values. Opening, closing and applying are announced through the localized `SelectLocalizations` strings; apps can speak their own messages with the same strings via `SemanticsService.sendAnnouncement` (the example package's accessibility screen does this).

The one thing that does not come for free is a custom `itemBuilder` — it fully replaces the item widget, built-in semantics included. Wrap the returned widget in `Semantics` yourself:

```dart
itemBuilder: (context, entry, {required selected, required onTap, categoryId}) {
  return Semantics(
    button: true,
    selected: selected,
    label: entry.name,
    child: InkWell(onTap: onTap, child: YourCustomWidget(entry: entry)),
  );
}
```

See [delegates.md](delegates.md) for the rest of the `itemBuilder` contract.
