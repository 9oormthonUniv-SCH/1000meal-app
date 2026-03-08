import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../signup/screens/signup_complete_screen.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';
import '../../../common/widgets/app_button.dart';
import '../models/role.dart';
import '../viewmodels/login_view_model.dart';
import '../viewmodels/signup_view_model.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final isStudent = vm.role == Role.student;
    final primary = isStudent ? AppColors.orange : AppColors.blue;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppBarCommon(title: ''),
      body: SafeArea(child: _LoginBody(primary: primary)),
    );
  }
}

class _LoginBody extends StatefulWidget {
  final Color primary;

  const _LoginBody({required this.primary});

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  late final TextEditingController _userIdController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController();
    _passwordController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<LoginViewModel>();
      await vm.loadSavedPreferences();
      if (!mounted) return;
      _userIdController.text = vm.userId;
      _passwordController.text = vm.password;
      // 로그아웃 후 진입한 경우 자동 로그인 하지 않음(다른 계정 로그인 가능). 앱 재실행 시에만 자동 로그인.
      final skipAutoLogin = await vm.shouldSkipAutoLoginThisTime();
      if (!mounted) return;
      if (!skipAutoLogin &&
          vm.autoLoginOption &&
          vm.userId.trim().isNotEmpty &&
          vm.password.isNotEmpty &&
          vm.canSubmit) {
        final role = await vm.submit();
        if (!mounted) return;
        if (role != null) {
          // pushNamedAndRemoveUntil로 로그인 화면 스택에서 제거 후 이동
          Navigator.of(context).pushNamedAndRemoveUntil(
            role == Role.admin ? '/admin' : '/',
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoleTabs(role: vm.role, onChanged: vm.loading ? null : vm.setRole),
          const SizedBox(height: 18),
          _HeroCopy(role: vm.role),
          const SizedBox(height: 40),
          Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LabeledTextField(
                  controller: _userIdController,
                  label: '아이디',
                  primary: widget.primary,
                  studentHint: '학번 8자리를 입력해주세요',
                  adminHint: '아이디를 입력해주세요',
                  studentKeyboardType: TextInputType.number,
                  adminKeyboardType: TextInputType.text,
                  onChanged: vm.setUserId,
                ),
                const SizedBox(height: 30),
                _PasswordField(
                  controller: _passwordController,
                  enabled: !vm.loading,
                  primary: widget.primary,
                  onChanged: vm.setPassword,
                  errorText: vm.errorMessage,
                ),
                const SizedBox(height: 16),
                _LoginOptions(
                  primary: widget.primary,
                  saveUserId: vm.saveUserIdOption,
                  autoLogin: vm.autoLoginOption,
                  onSaveUserIdChanged: vm.setSaveUserIdOption,
                  onAutoLoginChanged: vm.setAutoLoginOption,
                  loading: vm.loading,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: '로그인',
                  variant: AppButtonVariant.primary,
                  large: true,
                  backgroundColor: widget.primary,
                  onPressed: vm.canSubmit
                      ? () async {
                          final role = await vm.submit();
                          if (!context.mounted || role == null) return;
                          // 기존 스택을 모두 제거하고, role에 따라 홈(/) 또는 관리자(/admin) 화면으로 이동
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            role == Role.admin ? '/admin' : '/',
                            (route) => false,
                          );
                        }
                      : null,
                  loading: vm.loading,
                ),
                const SizedBox(height: 12),
                _BottomLinks(enabled: !vm.loading),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(SignupCompleteScreen.routeName),
                    child: Text(
                      '[디버그] 회원가입 완료 페이지',
                      style: AppTypography.caption1.copyWith(color: AppColors.gray6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginOptions extends StatelessWidget {
  final Color primary;
  final bool saveUserId;
  final bool autoLogin;
  final ValueChanged<bool> onSaveUserIdChanged;
  final ValueChanged<bool> onAutoLoginChanged;
  final bool loading;

  const _LoginOptions({
    required this.primary,
    required this.saveUserId,
    required this.autoLogin,
    required this.onSaveUserIdChanged,
    required this.onAutoLoginChanged,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OptionChip(
          label: '아이디 저장',
          value: saveUserId,
          primary: primary,
          onChanged: loading ? null : onSaveUserIdChanged,
        ),
        const SizedBox(width: 16),
        _OptionChip(
          label: '자동 로그인',
          value: autoLogin,
          primary: primary,
          onChanged: loading ? null : onAutoLoginChanged,
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool value;
  final Color primary;
  final ValueChanged<bool>? onChanged;

  const _OptionChip({
    required this.label,
    required this.value,
    required this.primary,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged!(v ?? false),
                activeColor: primary,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return primary;
                  return null;
                }),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.body3.copyWith(color: AppColors.gray7),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTabs extends StatelessWidget {
  final Role role;
  final ValueChanged<Role>? onChanged;

  const _RoleTabs({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Next.js(framaer-motion)의 layoutId="underline" 느낌을 Flutter에서 구현:
    //  - 탭 전체 폭 밑줄이 left<->right로 이동(AnimatedAlign)
    //  - 색상도 role에 맞춰 전환(AnimatedContainer)
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / 2;
        final isStudent = role == Role.student;
        final underlineColor = isStudent ? AppColors.orange : AppColors.blue;

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Row(
              children: [
                Expanded(
                  child: _RoleTabButton(
                    label: '일반',
                    active: isStudent,
                    activeColor: AppColors.orange,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(Role.student),
                  ),
                ),
                Expanded(
                  child: _RoleTabButton(
                    label: '관리자',
                    active: !isStudent,
                    activeColor: AppColors.blue,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(Role.admin),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.gray3),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: isStudent
                    ? Alignment.bottomLeft
                    : Alignment.bottomRight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: tabWidth,
                  height: 2,
                  decoration: BoxDecoration(color: underlineColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  const _RoleTabButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: AppTypography.caption1.copyWith(
              color: active ? activeColor : AppColors.gray6,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final Role role;
  const _HeroCopy({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == Role.admin;
    // Next.js의 AnimatePresence + opacity 전환을 Flutter AnimatedSwitcher로 구현
    return SizedBox(
      height: 112,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Align(
          key: ValueKey<Role>(role),
          alignment: isAdmin ? Alignment.topRight : Alignment.topLeft,
          child: Column(
            crossAxisAlignment: isAdmin
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? '당신의 준비가\n늘 편리하도록,' : '당신의 걸음이\n헛되지 않도록,',
                textAlign: isAdmin ? TextAlign.right : TextAlign.left,
                style: AppTypography.headline1.copyWith(
                  fontSize: 24,
                  height: 32 / 24,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/icon/Textlogo.png',
                width: 100,
                fit: BoxFit.contain, // 그림 비율 유지하며 잘리기 방지
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color primary;
  final String studentHint;
  final String adminHint;
  final TextInputType studentKeyboardType;
  final TextInputType adminKeyboardType;
  final ValueChanged<String> onChanged;

  const _LabeledTextField({
    required this.controller,
    required this.label,
    required this.primary,
    required this.studentHint,
    required this.adminHint,
    required this.studentKeyboardType,
    required this.adminKeyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<LoginViewModel>();
    final isStudent = vm.role == Role.student;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.headline4.copyWith(color: AppColors.gray7),
        ),
        TextField(
          controller: controller,
          enabled: !vm.loading,
          keyboardType: isStudent ? studentKeyboardType : adminKeyboardType,
          cursorColor: primary,
          style: AppTypography.headline5.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            hintText: isStudent ? studentHint : adminHint,
            hintStyle: AppTypography.headline5.copyWith(color: AppColors.gray5),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gray7),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gray3),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final Color primary;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _PasswordField({
    required this.controller,
    required this.enabled,
    required this.primary,
    required this.onChanged,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '비밀번호',
          style: AppTypography.headline4.copyWith(color: AppColors.gray7),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: true,
          cursorColor: primary,
          style: AppTypography.headline5.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gray7),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gray3),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTypography.caption1.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _BottomLinks extends StatelessWidget {
  final bool enabled;
  const _BottomLinks({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: AppColors.gray7,
      textStyle: AppTypography.caption2,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: enabled
              ? () => Navigator.of(
                  context,
                ).pushNamed('/find-account', arguments: 'id')
              : null,
          style: style,
          child: const Text('아이디 찾기'),
        ),
        const SizedBox(width: 40),
        Text(
          '|',
          style: AppTypography.caption2.copyWith(color: AppColors.gray4),
        ),
        const SizedBox(width: 40),
        TextButton(
          onPressed: enabled
              ? () => Navigator.of(
                  context,
                ).pushNamed('/find-account', arguments: 'pw')
              : null,
          style: style,
          child: const Text('비밀번호 찾기'),
        ),
        const SizedBox(width: 40),
        Text(
          '|',
          style: AppTypography.caption2.copyWith(color: AppColors.gray4),
        ),
        const SizedBox(width: 40),
        TextButton(
          onPressed: enabled
              ? () {
                  Navigator.of(context).pushNamed('/signup').then((_) {
                    if (context.mounted) {
                      context
                          .read<SignupViewModel>()
                          .clearFromCredentialsFlag();
                    }
                  });
                }
              : null,
          style: style,
          child: const Text('회원가입'),
        ),
      ],
    );
  }
}
