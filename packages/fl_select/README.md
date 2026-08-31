A customizable Flutter select widget for building filter bars, cascading menus, and pickers with single/multiple selection, async loading, search filtering, theming, and i18n.

[Playground](https://flselect.zeaon.dev/)

![Highlights](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/highlights.gif)

### Agent Skills

This repo bundles an [Agent Skill](https://skills.sh/) so AI coding agents (Claude Code, Cursor, Codex, Windsurf, GitHub Copilot, etc.) use `fl_select` correctly — accurate APIs, no hallucinated parameters.

Install it with:

```bash
npx skills add amlzq/fl_select
```

Then just ask your agent to build a filter bar or select UI with `fl_select`. The skill lives in [`skills/fl-select`](https://github.com/amlzq/fl_select/tree/main/skills/fl-select).

### Features

Two layers work together: **entry points** decide _where_ the select appears, and **delegates** decide _how_ entries are laid out — any delegate plugs into any entry point.

- **Entry points** — five ways to show a select: `SelectView` , `PopupSelectBar` , `PopupSelectButton` , `showSelect` , `showModalBottomSelect` .
- **Delegates** — seven single-purpose styles. Flat data: `ListSelectDelegate` , `GridSelectDelegate` , `WrapSelectDelegate` ; two-level (category) data: `CascadingSelectDelegate` , `TabNavSelectDelegate` , `SideNavSelectDelegate` , `ExpandableSelectDelegate` . In the two-level styles (all but cascading), each category's children are laid out by `category.layout` — list / grid / chips / range slider / counter.
- Single & multiple selection via `SelectionMode` (per category or as a delegate fallback).
- Async data loading through `entriesLoader`, or synchronous data via `entries` / `selectedEntries` / `resetEntries` (rendered on the first frame, no skeleton).
- Search filtering: set `searchEnabled` on any delegate and a `SelectSearchBar` filters entries as you type (debounced, with a customizable predicate and theme).
- Flexible entries: the "Any" entry clears a category, `SelectRangeEntry.custom` takes user min/max input, and an `immediate` entry applies on tap without the action bar.
- `skeletonBuilder` & `errorBuilder` for loading and error states.
- Theming via `SelectThemeData` and the `PopupSelectBarTheme` / `PopupSelectButtonTheme` extensions.
- Built-in i18n in 10 languages via `SelectLocalizationsDelegate`.

### Getting started

#### Install

```bash
flutter pub add fl_select
```

#### Import

```dart
import 'package:fl_select/fl_select.dart';
```

### Usage

#### Delegates

A delegate controls both data loading and how the body is rendered, and works with every entry point above. Flat delegates (`ListSelectDelegate`, `GridSelectDelegate`, `WrapSelectDelegate`) render parentless leaves created with `.name(...)`, while category delegates (`CascadingSelectDelegate`, `TabNavSelectDelegate`, `SideNavSelectDelegate`, `ExpandableSelectDelegate`) render a tree of `SelectCategoryEntry` roots whose children follow `category.layout` (list / grid / chips / range slider / counter):

| `ListSelectDelegate`        | `GridSelectDelegate`        | `WrapSelectDelegate`        | `CascadingSelectDelegate`   | `TabNavSelectDelegate`      | `SideNavSelectDelegate`     | `ExpandableSelectDelegate`  |
| --------------------------- | --------------------------- | --------------------------- | --------------------------- | --------------------------- | --------------------------- | --------------------------- |
| ![ListSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/list.jpg) | ![GridSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/grid.jpg) | ![WrapSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/wrap.jpg) | ![CascadingSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/cascading.jpg) | ![TabNavSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/tabnav.jpg) | ![SideNavSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/sidenav.jpg) | ![ExpandableSelectDelegate](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/expandable.jpg) |

#### SelectEntry

Entries form a tree. `SelectCategoryEntry` is the root (a category) and `SelectChildEntry` is any non-root node, identified by its `parentId`. Prefer the `SelectCategoryEntry.children(...)` factory: it auto-injects `parentId` on every child (recursively), so you never write it by hand, and it also takes `header` / `footer` entries and the category's `layout`.

| Entry                    | Purpose                                                                                                                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SelectCategoryEntry`    | Root node. `.children(...)` auto-injects `parentId` on `children`; also takes `selectionMode`, `header`/`footer`, and `layout`.                                                |
| `SelectTextEntry`        | A plain text leaf. Use `.any(...)` for the "Any" (clear) entry. `.name(...)` creates a parentless leaf for flat lists.                                                        |
| `SelectRangeEntry<N, E>` | A numeric range leaf (`min`/`max`, snapped by `divisions`). Use `.any(...)` for "Any" and `.custom(...)` for a user-input range. `SelectIntEntry<E>` is a handy alias for `SelectRangeEntry<int, E>`. |

Selection is controlled by `SelectionMode` (`single` by default, or `multiple`), set on a `SelectCategoryEntry` (per category) or on the delegate (fallback). In multiple-selection mode, an entry with `immediate: true` applies on tap and skips the action bar.

Entries load asynchronously via `entriesLoader`, which returns a `Future<SelectEntries>` where `SelectEntries` is `Set<SelectEntry>`.

Flat data for `ListSelectDelegate` / `GridSelectDelegate` / `WrapSelectDelegate` — `SelectTextEntry.name(...)` creates a parentless leaf, and `SelectRangeEntry.custom()` adds a user-input range:

```dart
SelectEntries get listData => {
      SelectTextEntry.name(id: 'a', name: 'Kiwi'),
      SelectTextEntry.name(id: 'b', name: 'Grape'),
      SelectTextEntry.name(id: 'c', name: 'Strawberry'),
      SelectTextEntry.name(id: 'd', name: 'Pineapple'),
    };

SelectEntries get gridData => {
      SelectRangeEntry.custom(), // user-input min/max
      SelectTextEntry.name(id: 'a', name: '0-100'),
      SelectTextEntry.name(id: 'b', name: '100-500'),
      SelectTextEntry.name(id: 'c', name: '500-1000'),
      SelectTextEntry.name(id: 'd', name: '1000-2000'),
    };

SelectEntries get wrapData => {
      SelectTextEntry.name(id: 'a', name: 'Tiger'),
      SelectTextEntry.name(id: 'b', name: 'Lion'),
      SelectTextEntry.name(id: 'c', name: 'Bear'),
      SelectTextEntry.name(id: 'd', name: 'Elephant'),
      SelectTextEntry.name(id: 'e', name: 'Monkey'),
    };
```

Two-level data for `CascadingSelectDelegate` / `TabNavSelectDelegate` / `SideNavSelectDelegate` / `ExpandableSelectDelegate` — every category picks its own `selectionMode`, `layout`, and optional `header` / `footer`:

```dart
SelectEntries get multiCategoryData => {
      SelectCategoryEntry.children(
        id: 'cate1',
        name: 'Cate 1',
        children: {
          SelectTextEntry.name(id: 'a', name: 'Football'),
          SelectTextEntry.name(id: 'b', name: 'Basketball'),
          SelectTextEntry.name(id: 'c', name: 'Baseball'),
          SelectTextEntry.name(id: 'd', name: 'Tennis'),
        },
        selectionMode: SelectionMode.single,
        footer: SelectTextEntry.children(
          id: 'c1-f',
          name: 'Letter Grade',
          children: {
            SelectTextEntry.name(id: 'f-a', name: 'A'),
            SelectTextEntry.name(id: 'f-b', name: 'B'),
            SelectTextEntry.name(id: 'f-c', name: 'C'),
          },
        ),
        footerSelectionMode: SelectionMode.single,
      ),
      SelectCategoryEntry.children(
        id: 'cate2',
        name: 'Cate 2',
        header: SelectTextEntry.children(
          id: 'c2-h',
          name: 'Letter Grade',
          children: {
            SelectTextEntry.name(id: 'h-a', name: 'A'),
            SelectTextEntry.name(id: 'h-b', name: 'B'),
          },
        ),
        headerSelectionMode: SelectionMode.single,
        children: {
          SelectTextEntry.name(id: 'a', name: 'Mathematics'),
          SelectTextEntry.name(id: 'b', name: 'Language'),
        },
        selectionMode: SelectionMode.single,
      ),
      SelectCategoryEntry.children(
        id: 'cate5',
        name: 'Cate 5',
        children: {
          SelectRangeEntry(
            id: 'a',
            name: '\$0-\$2000000',
            min: 0,
            max: 2000000,
            divisions: 80,
          ),
          SelectRangeEntry.custom(),
        },
        selectionMode: SelectionMode.single,
        layout: const SelectRangeLayout(), // range slider
      ),
      SelectCategoryEntry.children(
        id: 'cate6',
        name: 'Cate 6',
        children: {
          SelectTextEntry.name(id: 'a', name: '1'),
          SelectTextEntry.name(id: 'b', name: '2'),
          SelectTextEntry.name(id: 'c', name: '3'),
        },
        selectionMode: SelectionMode.single,
        layout: const SelectCounterLayout(), // stepper
      ),
    };
```

An async loader (`entriesLoader`) — any `Future<SelectEntries>`, e.g. decoded from JSON:

```dart
Future<SelectEntries> fetchCascadingData() async {
  await Future.delayed(const Duration(milliseconds: 350)); // simulate a network delay
  return {
    SelectCategoryEntry.children(
      id: 'region',
      name: 'Region',
      children: {
        SelectTextEntry.any(parentId: '', name: 'Any', immediate: true), // parentId auto-injected
        SelectTextEntry.name(id: 'north', name: 'North'),
        SelectTextEntry.name(id: 'south', name: 'South'),
      },
      selectionMode: SelectionMode.multiple,
    ),
  };
}
```

For static data, skip the loader and pass the values directly — `entries` / `selectedEntries` / `resetEntries` are mutually exclusive with the loaders:

```dart
// Static data: no loader, no async — renders on the first frame
ListSelectDelegate(
  entries: listData,
  selectedEntries: {SelectTextEntry.name(id: 'a', name: 'Kiwi')},
  resetEntries: {SelectTextEntry.name(id: 'a', name: 'Kiwi')},
);
```

#### SelectView

`SelectView` embeds a select directly in a page or dialog body. Pass any `delegate`  — it controls both loading and rendering.

```dart
SelectView(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  delegate: ListSelectDelegate(entries: listData),
  onChanged: (SelectEntries selected) {
    // selected is the SelectEntries when the selection changes
    print('toQueryParameters: ${selected.toQueryParameters()}');
  },
);

SelectView(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  delegate: CascadingSelectDelegate(
    entriesLoader: fetchCascadingData,
    selectionMode: SelectionMode.multiple,
    sideBarTheme: const SelectSideBarTheme(width: 120),
    isScrollable: true,
  ),
  onChanged: (SelectEntries selected) {
    print('toQueryMap: ${selected.toQueryMap()}');
  },
);

SelectView(
  delegate: TabNavSelectDelegate(
    defaultLayout: SelectGridLayout(
      crossAxisCount: 3,
      childAspectRatio: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    entries: multiCategoryData,
    selectionMode: SelectionMode.multiple,
    gridTileTheme: const SelectGridTileTheme(
      variant: SelectGridTileVariant.outlined,
    ),
    fieldTileTheme: const SelectFieldTileTheme(
      variant: SelectFieldTileVariant.outlined,
    ),
  ),
  onChanged: (SelectEntries selected) {
    print('onChanged: $selected');
  },
);
```

![SelectView](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/view.gif)

#### PopupSelectButton

A single-trigger alternative to `PopupSelectBar` — opens a select overlay on tap, like `PopupMenuButton`. It takes one `selectDelegate`, a `label`/`child`, and a required `onApplied` callback. Four variants: text (default), `.filled(...)`, `.elevated(...)`, and `.outlined(...)`; use `direction` to open above the trigger.

```dart
PopupSelectButton(
  label: 'List',
  selectDelegate: ListSelectDelegate(entries: listData),
  onApplied: (selected) {
    print('toQueryMap: ${selected.toQueryMap()}');
    print('toQueryParameters: ${selected.toQueryParameters()}');
  },
);

PopupSelectButton.elevated(
  label: 'Grid',
  selectDelegate: GridSelectDelegate(
    entries: gridData,
    crossAxisCount: 3,
    childAspectRatio: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
  ),
  onApplied: (selected) {
    print('onApplied: $selected');
  },
);

PopupSelectButton.filled(
  label: 'Wrap',
  selectDelegate: WrapSelectDelegate(
    entries: wrapData,
    selectionMode: SelectionMode.multiple,
    spacing: 12.0,
    runSpacing: 12.0,
  ),
  onApplied: (selected) {
    print('onApplied: $selected');
  },
);

PopupSelectButton.outlined(
  label: 'Cascading',
  selectDelegate: CascadingSelectDelegate(
    entriesLoader: fetchCascadingData,
    selectionMode: SelectionMode.multiple,
    sideBarTheme: const SelectSideBarTheme(width: 120),
  ),
  onApplied: (selected) {
    print('onApplied: $selected');
  },
);
```

Category delegates work the same way — set `defaultLayout` to control how each category's children are laid out, and `direction` to open the overlay above the trigger:

```dart
PopupSelectButton(
  label: 'TabNav',
  selectDelegate: TabNavSelectDelegate(
    defaultLayout: SelectGridLayout(
      crossAxisCount: 3,
      childAspectRatio: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    entries: multiCategoryData,
    selectionMode: SelectionMode.multiple,
  ),
  onApplied: (selected) {
    print('onApplied: $selected');
  },
);

PopupSelectButton(
  direction: PopupSelectDirection.above,
  label: 'Expandable',
  selectDelegate: ExpandableSelectDelegate(
    defaultLayout: SelectListLayout(),
    entries: multiCategoryData,
    selectionMode: SelectionMode.multiple,
  ),
  onApplied: (selected) {
    print('onApplied: $selected');
  },
);
```

![PopupSelectButton](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/button.gif)

#### PopupSelectBar

A tab bar (`PreferredSizeWidget`) that opens an overlay select when a tab is tapped. Provide `tabs` for the bar and a matching `selectDelegates` list (one per tab), plus the required `onApplied` callback. Results also arrive via `onChanged` / `onReset`.

```dart
PopupSelectBar(
  isScrollable: true,
  tabs: const [
    PopupTab(label: 'List'),
    PopupTab(label: 'Grid'),
    PopupTab(child: Icon(Icons.wrap_text)),
    PopupTab(label: 'Cascading'),
    PopupTab(label: 'TabNav'),
    PopupTab(label: 'SideNav'),
    PopupTab(child: Icon(Icons.expand)),
  ],
  selectDelegates: [
    ListSelectDelegate(entries: listData),
    GridSelectDelegate(
      entries: gridData,
      crossAxisCount: 3,
      childAspectRatio: 3.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    WrapSelectDelegate(
      entries: wrapData,
      selectionMode: SelectionMode.multiple,
      spacing: 12.0,
      runSpacing: 12.0,
    ),
    CascadingSelectDelegate(
      entriesLoader: fetchCascadingData,
      selectionMode: SelectionMode.multiple,
      sideBarTheme: const SelectSideBarTheme(width: 120),
    ),
    TabNavSelectDelegate(
      defaultLayout: SelectGridLayout(
        crossAxisCount: 3,
        childAspectRatio: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      entries: multiCategoryData,
      selectionMode: SelectionMode.multiple,
    ),
    SideNavSelectDelegate(
      defaultLayout: SelectWrapLayout(spacing: 12, runSpacing: 12),
      entries: multiCategoryData,
      selectionMode: SelectionMode.multiple,
    ),
    ExpandableSelectDelegate(
      defaultLayout: SelectListLayout(),
      entries: multiCategoryData,
      selectionMode: SelectionMode.multiple,
    ),
  ],
  onApplied: (tabData, selected) {
    // tabData is the PopupTabData; selected is the SelectEntries
    print('onApplied: $tabData, $selected');
    print('toQueryMap: ${selected.toQueryMap()}');
    print('toQueryParameters: ${selected.toQueryParameters()}');
  },
);
```

![PopupSelectBar](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/bar.gif)

#### showSelect

Shows a select in a modal dialog. Returns the selected `SelectEntries` when applied, or `null` when dismissed. In single-selection mode, tapping an item applies immediately; in multi-selection mode, "Apply" in the action bar confirms.

```dart
final SelectEntries? result = await showSelect(
  context: context,
  delegate: ListSelectDelegate(entries: listData),
  leading: const Icon(Icons.list),
  title: const Text('ListSelect'),
);

if (result != null) {
  print('toQueryMap: ${result.toQueryMap()}');
  print('toQueryParameters: ${result.toQueryParameters()}');
}
```

Any delegate works, and the header is configurable:

```dart
await showSelect(
  context: context,
  delegate: CascadingSelectDelegate(
    entriesLoader: fetchCascadingData,
    selectionMode: SelectionMode.multiple,
    sideBarTheme: const SelectSideBarTheme(width: 120),
    isScrollable: true,
  ),
);

await showSelect(
  context: context,
  delegate: TabNavSelectDelegate(
    defaultLayout: SelectGridLayout(
      crossAxisCount: 2,
      childAspectRatio: 3.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
    ),
    entries: multiCategoryData,
    selectionMode: SelectionMode.multiple,
    isScrollable: true,
  ),
  title: const Text('TabNavSelect'),
  trailing: const CloseButton(),
  centerTitle: false,
);
```

![showSelect](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/dialog.gif)

#### showModalBottomSelect

Shows a select in a modal bottom sheet built on Flutter's `showModalBottomSheet`. Same interaction as `showSelect`. Standard sheet parameters (`isScrollControlled`, `isDismissible`, `enableDrag`, `showDragHandle`, `constraints`, etc.) are forwarded.

```dart
final SelectEntries? result = await showModalBottomSelect(
  context: context,
  delegate: ListSelectDelegate(entries: listData),
  leading: const Icon(Icons.list),
  title: const Text('ListSelect'),
);

if (result != null) {
  print('toQueryMap: ${result.toQueryMap()}');
  print('toQueryParameters: ${result.toQueryParameters()}');
}
```

`title` / `leading` / `trailing` / `centerTitle` behave like the `showSelect` dialog header, plus the forwarded sheet parameters:

```dart
await showModalBottomSelect(
  context: context,
  delegate: GridSelectDelegate(
    entries: gridData,
    crossAxisCount: 3,
    childAspectRatio: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
  ),
  title: const Text('GridSelect'),
  centerTitle: false,
  trailing: const CloseButton(),
);

await showModalBottomSelect(
  context: context,
  delegate: SideNavSelectDelegate(
    defaultLayout: SelectWrapLayout(spacing: 12, runSpacing: 12),
    entries: multiCategoryData,
    selectionMode: SelectionMode.multiple,
  ),
  title: const Text('SideNavSelect'),
);
```

![showModalBottomSelect](https://raw.githubusercontent.com/amlzq/fl_select/main/screenshots/bottom_sheet.gif)

#### Search

Set `searchEnabled: true` on any delegate to render a `SelectSearchBar` above the body. Typing filters the displayed entries (debounced 300 ms by default) while preserving the layout and selection state — canceling the search restores the original entries.

```dart
CascadingSelectDelegate(
  entriesLoader: fetchCascadingData,
  searchEnabled: true,
  searchHintText: 'Search',
  searchDebounceDuration: const Duration(milliseconds: 300),
  // searchPredicate: (entry, query) {
  //   return entry.name?.contains(query) == true;
  // },
);

ListSelectDelegate(
  entries: listData,
  searchEnabled: true,
);
```

The default predicate (`defaultSelectSearchPredicate`) matches `SelectEntry.name` case-insensitively; provide a custom `searchPredicate` to match `id`, `extra`, or any other field. Style the bar via `searchBarTheme` (`SelectSearchBarTheme`) on the delegate, or globally through `SelectThemeData`.

#### Serializing selections

Selections arrive as a `SelectEntries` tree. Two extensions turn that tree into URL query parameters — each category contributes key/value pairs keyed by its own id with the deepest selected leaf ids as values; an "Any" leaf resolves to its parent id; a custom `SelectRangeEntry` formats as `min-max`:

```dart
final selected = await showSelect(context: context, delegate: ...);

// Map<String, List<String>>, mirroring Uri.queryParametersAll
final map = selected?.toQueryMap(); // {price: [0-100], more: [near_subway]}

// Or a ready-made query string
selected?.toQueryParameters(); // price=0-100&more=near_subway

// Multi-value layouts via SelectArrayFormat
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.brackets); // more[]=a&more[]=b
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.comma);    // more=a,b
selected?.toQueryParameters(arrayFormat: SelectArrayFormat.indices);  // more[0]=a
selected?.toQueryParameters(
  arrayFormat: SelectArrayFormat.delimited,
  delimiter: '|',
); // more=a|b (covers OpenAPI pipeDelimited / spaceDelimited)
```

Values are percent-encoded by default; pass `encode: false` when the caller handles encoding.

#### Theming

**Per instance** — delegates carry the styling: set `selectedColor` / `onSelectedColor` (or any finer-grained `*Theme` field) directly on a delegate. `PopupSelectBar` also accepts a single `selectTheme` that overrides the styling of every tab's delegate:

```dart
GridSelectDelegate(
  entries: gridData,
  crossAxisCount: 3,
  selectedColor: Theme.of(context).colorScheme.primary,
  onSelectedColor: Theme.of(context).colorScheme.onPrimary,
  gridTileTheme: const SelectGridTileTheme(
    variant: SelectGridTileVariant.outlined,
  ),
  fieldTileTheme: const SelectFieldTileTheme(
    variant: SelectFieldTileVariant.outlined,
  ),
);

CascadingSelectDelegate(
  entriesLoader: fetchCascadingData,
  sideBarTheme: const SelectSideBarTheme(width: 120),
);

PopupSelectBar(
  tabs: ...,
  selectDelegates: ...,
  selectTheme: SelectThemeData(Theme.of(context)),
  onApplied: (tabData, selected) {
    // tabData is the PopupTabData; selected is the SelectEntries
  },
);
```

**Globally** — register `PopupSelectBarTheme` and `PopupSelectButtonTheme` as `ThemeData` extensions so every bar/button picks them up automatically:

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

Or derive the extensions from the active theme in `builder`, so they follow light/dark mode and the app's seed color:

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  builder: (context, child) {
    final baseTheme = Theme.of(context);
    final theme = baseTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        PopupSelectBarTheme(
          overlayStyle: const SelectOverlayStyle(
            barrierColor: Colors.black54,
          ),
          selectTheme: SelectThemeData(baseTheme),
        ),
        PopupSelectButtonTheme(
          backgroundColor: baseTheme.colorScheme.primary,
          foregroundColor: baseTheme.colorScheme.onPrimary,
        ),
      ],
    );
    return Theme(
      data: theme,
      child: child ?? const SizedBox.shrink(),
    );
  },
);
```

#### Internationalization

Add `SelectLocalizationsDelegate()` to your `MaterialApp`. It ships translations for `de`, `en`, `es`, `fr`, `id`, `ja`, `ko`, `pt`, `vi`, and `zh` (Hans/Hant), localizing the "Apply" / "Reset" / "Multiple" labels automatically.

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
