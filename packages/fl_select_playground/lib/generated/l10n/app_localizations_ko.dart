// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Select 예제';

  @override
  String get themeMode => '테마';

  @override
  String get themeSystem => '시스템 따르기';

  @override
  String get themeLight => '밝게';

  @override
  String get themeDark => '어둡게';

  @override
  String get languageTooltip => '언어';

  @override
  String get entryPoint => '진입점';

  @override
  String get delegateLabel => '델리게이트';

  @override
  String get selectionMode => '선택 모드';

  @override
  String get tileVariant => '타일 스타일';

  @override
  String get seedColor => '시드 색상';

  @override
  String columns(int value) {
    return '열 수($value)';
  }

  @override
  String aspectRatio(String value) {
    return '가로세로 비율($value)';
  }

  @override
  String spacing(int value) {
    return '간격($value)';
  }

  @override
  String columnSpacing(int value) {
    return '열 간격($value)';
  }

  @override
  String rowSpacing(int value) {
    return '행 간격($value)';
  }

  @override
  String runSpacing(int value) {
    return '줄바꿈 간격($value)';
  }

  @override
  String get single => '단일';

  @override
  String get multiple => '다중';

  @override
  String get filled => '채우기';

  @override
  String get outlined => '외곽선';

  @override
  String get elevated => '입체';

  @override
  String get text => '텍스트';

  @override
  String get scrollable => '스크롤 가능';

  @override
  String get searchEnabled => '검색';

  @override
  String get direction => '방향';

  @override
  String get directionBelow => '아래';

  @override
  String get directionAbove => '위';

  @override
  String get directionAdaptive => '자동';

  @override
  String get buttonVariant => '버튼 스타일';

  @override
  String get brightness => '밝기';

  @override
  String get follow => '앱 따르기';

  @override
  String get light => '밝게';

  @override
  String get dark => '어둡게';

  @override
  String get layoutList => '목록';

  @override
  String get layoutGrid => '그리드';

  @override
  String get layoutWrap => '줄바꿈';

  @override
  String get layoutCascading => '계단식';

  @override
  String get layoutTabNav => '상단 탐색';

  @override
  String get layoutSideNav => '측면 탐색';

  @override
  String get layoutExpandable => '확장';

  @override
  String get headerOptions => '헤더 옵션';

  @override
  String get leadingOption => '앞쪽 위젯';

  @override
  String get trailingOption => '뒤쪽 위젯';

  @override
  String get centerTitleOption => '제목 가운데';

  @override
  String get phonePopupBarTitle => '팝업 바';

  @override
  String get phonePopupButtonTitle => '팝업 버튼';

  @override
  String get phoneDialogTitle => '대화상자';

  @override
  String get phoneBottomSheetTitle => '바텀 시트';

  @override
  String get tapBarHint => '막대를 탭하여 선택기를 엽니다';

  @override
  String get openSelect => '선택기 열기';

  @override
  String get listSelect => '목록 선택기';

  @override
  String get gridSelect => '그리드 선택기';

  @override
  String get wrapSelect => '줄바꿈 선택기';

  @override
  String get cascadingSelect => '계단식 선택기';

  @override
  String get tabNavSelect => '상단 탐색 선택기';

  @override
  String get sideNavSelect => '측면 탐색 선택기';

  @override
  String get expandableSelect => '확장 선택기';

  @override
  String get resultPanelExpand => '펼치기';

  @override
  String get resultPanelCollapse => '접기';

  @override
  String get resultPanelTitle => '콜백 결과';

  @override
  String get shareTooltip => '링크 복사';

  @override
  String get linkCopied => '링크가 클립보드에 복사되었습니다';
}
