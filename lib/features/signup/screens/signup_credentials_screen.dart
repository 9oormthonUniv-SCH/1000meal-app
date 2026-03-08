import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/external_link.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_checkbox.dart';
import '../../auth/viewmodels/signup_view_model.dart';
import 'signup_complete_screen.dart';
import 'signup_terms_screen.dart';

class SignupCredentialsScreen extends StatefulWidget {
  static const routeName = '/signup/credentials';

  const SignupCredentialsScreen({super.key});

  @override
  State<SignupCredentialsScreen> createState() =>
      _SignupCredentialsScreenState();
}

class _SignupCredentialsScreenState extends State<SignupCredentialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<SignupViewModel>();
      vm.resetCredentialsState();
      await vm.loadDraft();
      if (!mounted) return;
      if (vm.id.trim().isEmpty) {
        Navigator.of(context).pushReplacementNamed('/signup/id');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppBarCommon(title: ''),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InputName(value: vm.name, onChanged: vm.setName),
                      const SizedBox(height: 18),
                      _InputPassword(
                        pw: vm.pw,
                        pw2: vm.pw2,
                        validPwd: vm.validPwd,
                        samePwd: vm.samePwd,
                        onChangedPw: vm.setPw,
                        onChangedPw2: vm.setPw2,
                      ),
                      const SizedBox(height: 18),
                      _InputEmail(
                        email: vm.email,
                        onChanged: vm.setEmail,
                        sending: vm.sendingEmail,
                        verifying: vm.verifyingEmail,
                        emailSent: vm.emailSent,
                        code: vm.emailCode,
                        verified: vm.verified,
                        error: vm.emailError,
                        onSend: vm.sendEmail,
                        onChangeCode: vm.setEmailCode,
                        onVerify: vm.verifyEmailCode,
                      ),
                      const SizedBox(height: 18),
                      _Agreements(
                        agreeTos: vm.agreeTos,
                        agreePrivacy: vm.agreePrivacy,
                        onToggleAll: vm.setAgreeAll,
                        onToggleTos: vm.setAgreeTos,
                        onTogglePrivacy: vm.setAgreePrivacy,
                      ),
                      if (vm.submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          vm.submitError!,
                          style: AppTypography.caption1.copyWith(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: AppButton(
                label: '가입하기',
                variant: AppButtonVariant.primary,
                large: true,
                onPressed: (!vm.submitting && vm.canSubmit)
                    ? () async {
                        await vm.saveDraft();
                        final ok = await vm.submit();
                        if (!context.mounted) return;
                        if (ok) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(SignupCompleteScreen.routeName);
                          }
                      }
                    : null,
                loading: vm.submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _InputName extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _InputName({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.subtitle1.copyWith(color: AppColors.gray7),
            children: [
              const TextSpan(text: '이름 '),
              TextSpan(text: '*', style: AppTypography.subtitle1.copyWith(color: AppColors.orange)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          cursorColor: AppColors.orange,
          style: AppTypography.body2.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            hintText: '이름을 입력해주세요',
            hintStyle: AppTypography.body2.copyWith(color: AppColors.gray5),
            border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray3)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange, width: 2)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InputPassword extends StatelessWidget {
  final String pw;
  final String pw2;
  final bool validPwd;
  final bool samePwd;
  final ValueChanged<String> onChangedPw;
  final ValueChanged<String> onChangedPw2;

  const _InputPassword({
    required this.pw,
    required this.pw2,
    required this.validPwd,
    required this.samePwd,
    required this.onChangedPw,
    required this.onChangedPw2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.subtitle1.copyWith(color: AppColors.gray7),
            children: [
              const TextSpan(text: '비밀번호 '),
              TextSpan(text: '*', style: AppTypography.subtitle1.copyWith(color: AppColors.orange)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          cursorColor: AppColors.orange,
          style: AppTypography.body2.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            hintText: '8자~16자의 영문과 숫자를 사용해주세요',
            hintStyle: AppTypography.body2.copyWith(color: AppColors.gray5),
            border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray3)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange, width: 2)),
          ),
          onChanged: onChangedPw,
        ),
        if (pw.isNotEmpty && !validPwd) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '비밀번호는 8~16자의 영문, 숫자, 특수문자를 모두 포함해야 합니다.',
                  style: AppTypography.caption1.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: AppTypography.subtitle1.copyWith(color: AppColors.gray7),
            children: [
              const TextSpan(text: '비밀번호 확인 '),
              TextSpan(text: '*', style: AppTypography.subtitle1.copyWith(color: AppColors.orange)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          cursorColor: AppColors.orange,
          style: AppTypography.body2.copyWith(color: AppColors.black),
          decoration: InputDecoration(
            border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray3)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange, width: 2)),
          ),
          onChanged: onChangedPw2,
        ),
        if (pw2.isNotEmpty && !samePwd) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                '비밀번호를 다시 확인해주세요',
                style: AppTypography.caption1.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InputEmail extends StatelessWidget {
  final String email;
  final ValueChanged<String> onChanged;
  final bool sending;
  final bool verifying;
  final bool emailSent;
  final String code;
  final bool verified;
  final String? error;
  final VoidCallback onSend;
  final ValueChanged<String> onChangeCode;
  final VoidCallback onVerify;

  const _InputEmail({
    required this.email,
    required this.onChanged,
    required this.sending,
    required this.verifying,
    required this.emailSent,
    required this.code,
    required this.verified,
    required this.error,
    required this.onSend,
    required this.onChangeCode,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final isSch = email.trim().endsWith('@sch.ac.kr');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.subtitle1.copyWith(color: AppColors.gray7),
            children: [
              const TextSpan(text: '이메일 주소 '),
              TextSpan(text: '*', style: AppTypography.subtitle1.copyWith(color: AppColors.orange)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                cursorColor: AppColors.orange,
                style: AppTypography.body2.copyWith(color: AppColors.black),
                decoration: InputDecoration(
                  hintText: '예) cheonbab@cheon.ac.kr',
                  hintStyle: AppTypography.body2.copyWith(color: AppColors.gray5),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray7)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray3)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange, width: 2)),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return AppColors.orange.withValues(alpha: 0.5);
                        }
                        return AppColors.orange;
                      }),
                    ),
                onPressed: (email.isNotEmpty && isSch && !sending)
                    ? onSend
                    : null,
                child: sending
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        '인증 요청',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (emailSent) ...[
          const SizedBox(height: 12),
          Text(
            '인증 코드',
            style: AppTypography.subtitle1.copyWith(color: AppColors.gray7),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  cursorColor: AppColors.orange,
                  style: AppTypography.body2.copyWith(color: AppColors.black),
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray7)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray3)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange, width: 2)),
                  ),
                  onChanged: onChangeCode,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return AppColors.success.withValues(alpha: 0.5);
                          }
                          return AppColors.success;
                        }),
                      ),
                  onPressed: (code.isNotEmpty && !verifying) ? onVerify : null,
                  child: verifying
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          '확인',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => openExternalUrl('https://mail.sch.ac.kr'),
            child: Text(
              '메일함 열기 (mail.sch.ac.kr)',
              style: AppTypography.caption1.copyWith(
                color: AppColors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          if (verified) ...[
            const SizedBox(height: 8),
            Text(
              '✅ 인증 완료',
              style: AppTypography.caption1.copyWith(color: AppColors.success),
            ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error!,
                  style: AppTypography.caption1.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Agreements extends StatelessWidget {
  final bool agreeTos;
  final bool agreePrivacy;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<bool> onToggleTos;
  final ValueChanged<bool> onTogglePrivacy;

  const _Agreements({
    required this.agreeTos,
    required this.agreePrivacy,
    required this.onToggleAll,
    required this.onToggleTos,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final agreeAll = agreeTos && agreePrivacy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => onToggleAll(!agreeAll),
          child: Row(
            children: [
              AppCheckbox(
                value: agreeAll,
                onChanged: (v) => onToggleAll(v ?? false),
              ),
              const SizedBox(width: 6),
              Text(
                '모두 동의합니다',
                style: AppTypography.body1.copyWith(color: AppColors.gray7),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              _AgreementRow(
                checked: agreeTos,
                label: '[필수] 이용약관 동의',
                onToggle: onToggleTos,
                onView: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignupTermsScreen(doc: 'tos'),
                  ),
                ),
              ),
              _AgreementRow(
                checked: agreePrivacy,
                label: '[필수] 개인 정보 수집 및 이용 동의',
                onToggle: onTogglePrivacy,
                onView: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignupTermsScreen(doc: 'privacy'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final bool checked;
  final String label;
  final ValueChanged<bool> onToggle;
  final VoidCallback onView;

  const _AgreementRow({
    required this.checked,
    required this.label,
    required this.onToggle,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppCheckbox(value: checked, onChanged: (v) => onToggle(v ?? false)),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption1.copyWith(color: AppColors.gray7),
          ),
        ),
        TextButton(
          onPressed: onView,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gray6,
            textStyle: AppTypography.caption1,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('내용 보기 >'),
        ),
      ],
    );
  }
}

/// 간단 라우터: 아직 main.dart 라우트 연결 전이라 credentials 화면 내부에서만 사용.
