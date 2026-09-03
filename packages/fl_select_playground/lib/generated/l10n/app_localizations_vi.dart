// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Ví dụ Select';

  @override
  String get themeMode => 'Chủ đề';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get languageTooltip => 'Ngôn ngữ';

  @override
  String get entryPoint => 'Điểm vào';

  @override
  String get delegateLabel => 'Đại diện';

  @override
  String get selectionMode => 'Chế độ chọn';

  @override
  String get tileVariant => 'Biến thể ô';

  @override
  String get seedColor => 'Màu cơ sở';

  @override
  String columns(int value) {
    return 'Số cột ($value)';
  }

  @override
  String aspectRatio(String value) {
    return 'Tỷ lệ khung hình ($value)';
  }

  @override
  String spacing(int value) {
    return 'Khoảng cách ($value)';
  }

  @override
  String columnSpacing(int value) {
    return 'Khoảng cách cột ($value)';
  }

  @override
  String rowSpacing(int value) {
    return 'Khoảng cách hàng ($value)';
  }

  @override
  String runSpacing(int value) {
    return 'Khoảng cách ngắt dòng ($value)';
  }

  @override
  String get single => 'Một';

  @override
  String get multiple => 'Nhiều';

  @override
  String get filled => 'Tô đầy';

  @override
  String get outlined => 'Viền ngoài';

  @override
  String get elevated => 'Nổi';

  @override
  String get text => 'Văn bản';

  @override
  String get scrollable => 'Cuộn được';

  @override
  String get searchEnabled => 'Tìm kiếm';

  @override
  String get direction => 'Hướng';

  @override
  String get directionBelow => 'Xuống dưới';

  @override
  String get directionAbove => 'Lên trên';

  @override
  String get directionAdaptive => 'Tự động';

  @override
  String get buttonVariant => 'Biến thể nút';

  @override
  String get brightness => 'Độ sáng';

  @override
  String get follow => 'Theo ứng dụng';

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get layoutList => 'Danh sách';

  @override
  String get layoutGrid => 'Lưới';

  @override
  String get layoutWrap => 'Ngắt dòng';

  @override
  String get layoutCascading => 'Liên hoàn';

  @override
  String get layoutTabNav => 'Điều hướng tab';

  @override
  String get layoutSideNav => 'Điều hướng bên';

  @override
  String get layoutExpandable => 'Mở rộng';

  @override
  String get headerOptions => 'Tùy chọn tiêu đề';

  @override
  String get leadingOption => 'Thành phần trước';

  @override
  String get trailingOption => 'Thành phần sau';

  @override
  String get centerTitleOption => 'Tiêu đề giữa';

  @override
  String get phonePopupBarTitle => 'Thanh popup';

  @override
  String get phonePopupButtonTitle => 'Nút popup';

  @override
  String get phoneDialogTitle => 'Hộp thoại';

  @override
  String get phoneBottomSheetTitle => 'Bảng dưới';

  @override
  String get tapBarHint => 'Nhấn vào thanh để mở trình chọn';

  @override
  String get openSelect => 'Mở trình chọn';

  @override
  String get listSelect => 'Trình chọn danh sách';

  @override
  String get gridSelect => 'Trình chọn lưới';

  @override
  String get wrapSelect => 'Trình chọn ngắt dòng';

  @override
  String get cascadingSelect => 'Trình chọn liên hoàn';

  @override
  String get tabNavSelect => 'Trình chọn điều hướng tab';

  @override
  String get sideNavSelect => 'Trình chọn điều hướng bên';

  @override
  String get expandableSelect => 'Trình chọn mở rộng';

  @override
  String get resultPanelExpand => 'Mở rộng';

  @override
  String get resultPanelCollapse => 'Thu gọn';

  @override
  String get resultPanelTitle => 'Kết quả callback';

  @override
  String get shareTooltip => 'Sao chép liên kết';

  @override
  String get linkCopied => 'Đã sao chép liên kết vào bảng tạm';
}
