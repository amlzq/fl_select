# Theming and internationalization

## Per instance

Delegates carry the styling. Quick path: `selectedColor` / `onSelectedColor`; fine-grained control via the `*Theme` fields:

| Field | Covers |
| --- | --- |
| `categoryTheme` | Category sidebar/body chrome |
| `bodyTheme` | Select body |
| `categoryItemTheme` | Sidebar items |
| `entryTheme` | Entry tiles |
| `rangeEntryTheme` | Range slider/input entries |
| `counterEntryTheme` | Counter (`SelectCounterLayout`) entries |
| `actionBarTheme` | Apply/Reset action bar |
| `searchBarTheme` | `SelectSearchBar` |
| `skeletonTheme` | Loading skeletons |
| `panelTheme` | Panel background decoration (dialog/sheet panel) |

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

Precedence: widget parameter → `selectTheme` on the widget → theme extension → defaults.

## Internationalization

Add `SelectLocalizationsDelegate()` to `MaterialApp`. It ships translations for `de`, `en`, `es`, `fr`, `id`, `ja`, `ko`, `pt`, `vi`, and `zh` (Hans/Hant), localizing the "Apply" / "Reset" / "Multiple" labels automatically.

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
