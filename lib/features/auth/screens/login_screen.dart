import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../viewmodels/login_view_model.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final isStudent = vm.role == Role.student;
    final primary = isStudent ? const Color(0xFFF97316) : const Color(0xFF60A5FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoleTabs(
                role: vm.role,
                onChanged: vm.loading ? null : vm.setRole,
              ),
              const SizedBox(height: 18),
              _HeroCopy(role: vm.role),
              const SizedBox(height: 18),
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LabeledTextField(
                      label: '아이디',
                      hint: '학번 8자리를 입력해주세요',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      enabled: !vm.loading,
                      onChanged: vm.setPassword,
                      errorText: vm.errorMessage,
                    ),
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: vm.canSubmit ? primary : primary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: vm.canSubmit
                              ? () async {
                                  final role = await vm.submit();
                                  if (!context.mounted || role == null) return;
                                  Navigator.of(context).pushReplacementNamed(
                                    role == Role.admin ? '/admin' : '/',
                                  );
                                }
                              : null,
                          child: vm.loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  '로그인',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BottomLinks(enabled: !vm.loading),
                  ],
                ),
              ),
            ],
          ),
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
        final underlineColor = isStudent ? const Color(0xFFF97316) : const Color(0xFF60A5FA);

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Row(
              children: [
                Expanded(
                  child: _RoleTabButton(
                    label: '일반',
                    active: isStudent,
                    onTap: onChanged == null ? null : () => onChanged!(Role.student),
                  ),
                ),
                Expanded(
                  child: _RoleTabButton(
                    label: '관리자',
                    active: !isStudent,
                    onTap: onChanged == null ? null : () => onChanged!(Role.admin),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE5E7EB)))),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: isStudent ? Alignment.bottomLeft : Alignment.bottomRight,
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
  final VoidCallback? onTap;

  const _RoleTabButton({
    required this.label,
    required this.active,
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
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
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: Align(
          key: ValueKey<Role>(role),
          alignment: isAdmin ? Alignment.topRight : Alignment.topLeft,
          child: Column(
            crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                isAdmin ? '당신의 준비가\n늘 편리하도록,' : '당신의 걸음이\n헛되지 않도록,',
                textAlign: isAdmin ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/icon/Textlogo.png',
                width: 120,
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
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  const _LabeledTextField({required this.label, required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<LoginViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
        const SizedBox(height: 8),
        TextField(
          enabled: !vm.loading,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: vm.role == Role.student ? hint : '아이디를 입력해주세요',
            border: const UnderlineInputBorder(),
          ),
          onChanged: vm.setUserId,
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _PasswordField({required this.enabled, required this.onChanged, required this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('비밀번호', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563))),
        const SizedBox(height: 8),
        TextField(
          enabled: enabled,
          obscureText: true,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
          onChanged: onChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
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
      foregroundColor: const Color(0xFF6B7280),
      textStyle: const TextStyle(fontSize: 12),
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          onPressed: enabled ? () => Navigator.of(context).pushNamed('/find-account', arguments: 'id') : null,
          style: style,
          child: const Text('아이디 찾기'),
        ),
        const Text('|', style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
        TextButton(
          onPressed: enabled ? () => Navigator.of(context).pushNamed('/find-account', arguments: 'pw') : null,
          style: style,
          child: const Text('비밀번호 찾기'),
        ),
        const Text('|', style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
        TextButton(
          onPressed: enabled ? () => Navigator.of(context).pushNamed('/signup') : null,
          style: style,
          child: const Text('회원가입'),
        ),
      ],
    );
  }
}
