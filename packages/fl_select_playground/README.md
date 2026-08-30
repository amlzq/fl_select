# fl_select Playground

fl_select 的交互式调试台（Playground），从 `example/lib/playground` 迁移而来，现位于仓库级 pub workspace。

在手机框架中实时预览 `SelectView` / `PopupSelectBar` / `PopupSelectButton` 等组件，
并通过控制面板动态调整行为型与外观型参数，内置一套语言无关的示例筛选数据
（见 `lib/entry_repository.dart`）用于测试。

## 运行

```sh
cd packages/fl_select_playground
flutter pub get
flutter run
```
