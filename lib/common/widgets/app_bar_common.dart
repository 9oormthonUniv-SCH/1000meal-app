import 'package:flutter/material.dart';

/// 앱 공통 AppBar. 모든 화면에서 이 컴포넌트만 사용해 헤더 통일.
/// - [showBack]: 좌측 뒤로가기 버튼 표시 여부
/// - [title]: 제목 텍스트 ([titleWidget]이 없을 때만 사용)
/// - [titleWidget]: 제목 영역 커스텀 위젯 (로고, 부제목 등). 있으면 [title] 무시
/// - [centerTitle]: 제목 중앙 정렬 (기본 true)
/// - [onBackPressed]: 뒤로가기 커스텀 동작. 없으면 기본 pop / 홈 이동
/// - [actions]: 우측 액션 버튼들
class AppBarCommon extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCommon({
    super.key,
    this.showBack = true,
    this.backEnabled = true,
    this.title = '',
    this.titleWidget,
    this.centerTitle = true,
    this.titleSpacing,
    this.onBackPressed,
    this.actions = const [],
    this.toolbarHeight = 56,
    this.backgroundColor,
    this.foregroundColor,
  });

  final bool showBack;
  /// 제목 좌측 여백 (null이면 AppBar 기본값). 로고와 본문 좌측 정렬 시 동일 값 사용
  final double? titleSpacing;
  /// 뒤로가기 버튼 활성화. false면 탭해도 동작 안 함
  final bool backEnabled;
  final String title;
  final Widget? titleWidget;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final List<Widget> actions;
  final double toolbarHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static const Color _defaultBg = Colors.white;
  static const Color _defaultFg = Color(0xFF111827);

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  void _handleBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? _defaultBg;
    final fg = foregroundColor ?? _defaultFg;

    final titleChild = titleWidget ??
        (title.isEmpty
            ? const SizedBox.shrink()
            : Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ));

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing ?? (showBack ? 0 : 16),
      leadingWidth: showBack ? null : 0,
      automaticallyImplyLeading: false,
      title: titleChild,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: fg),
              onPressed: backEnabled ? () => _handleBack(context) : null,
            )
          : null,
      actions: actions,
    );
  }
}
