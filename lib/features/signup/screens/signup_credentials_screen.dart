import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/external_link.dart';
import '../../auth/viewmodels/signup_view_model.dart';
import 'signup_terms_screen.dart';

class SignupCredentialsScreen extends StatefulWidget {
  static const routeName = '/signup/credentials';

  const SignupCredentialsScreen({super.key});

  @override
  State<SignupCredentialsScreen> createState() => _SignupCredentialsScreenState();
}

class _SignupCredentialsScreenState extends State<SignupCredentialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<SignupViewModel>();
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
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SignupHeader(),
                const SizedBox(height: 28),
                _InputName(
                  value: vm.name,
                  onChanged: vm.setName,
                ),
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
                  Text(vm.submitError!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return const Color(0xFFF97316).withValues(alpha: 0.4);
                        }
                        return const Color(0xFFF97316);
                      }),
                    ),
                    onPressed: (!vm.submitting && vm.canSubmit)
                        ? () async {
                            await vm.saveDraft();
                            final ok = await vm.submit();
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          }
                        : null,
                    child: vm.submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('본인 인증 후 가입하기', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '천밥에 오신 것을\n환영합니다!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            children: [
              TextSpan(text: '1분', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600)),
              TextSpan(text: '이면 회원가입 가능해요'),
            ],
          ),
        ),
      ],
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
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            children: [
              TextSpan(text: '이름 '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFFF97316))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: '이름을 입력해주세요',
            border: UnderlineInputBorder(),
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
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            children: [
              TextSpan(text: '비밀번호 '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFFF97316))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '8~16자 영문·숫자·특수문자 조합',
            border: UnderlineInputBorder(),
          ),
          onChanged: onChangedPw,
        ),
        if (pw.isNotEmpty && !validPwd) ...[
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '비밀번호는 8~16자의 영문, 숫자, 특수문자를 모두 포함해야 합니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            children: [
              TextSpan(text: '비밀번호 확인 '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFFF97316))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(border: UnderlineInputBorder()),
          onChanged: onChangedPw2,
        ),
        if (pw2.isNotEmpty && !samePwd) ...[
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text('비밀번호를 다시 확인해주세요', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
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
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            children: [
              TextSpan(text: '이메일 주소 '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFFF97316))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: '예) cheonbab@sch.ac.kr',
                  border: UnderlineInputBorder(),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return const Color(0xFFF97316).withValues(alpha: 0.5);
                    }
                    return const Color(0xFFF97316);
                  }),
                ),
                onPressed: (email.isNotEmpty && isSch && !sending) ? onSend : null,
                child: sending
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('인증 요청', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (emailSent) ...[
          const SizedBox(height: 12),
          const Text('인증 코드', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(border: UnderlineInputBorder()),
                  onChanged: onChangeCode,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return const Color(0xFF22C55E).withValues(alpha: 0.5);
                      }
                      return const Color(0xFF22C55E);
                    }),
                  ),
                  onPressed: (code.isNotEmpty && !verifying) ? onVerify : null,
                  child: verifying
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('확인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => openExternalUrl('https://mail.sch.ac.kr'),
            child: const Text(
              '메일함 열기 (mail.sch.ac.kr)',
              style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
            ),
          ),
          if (verified) ...[
            const SizedBox(height: 8),
            const Text('✅ 인증 완료', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 6),
              Expanded(child: Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
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
              Checkbox(
                value: agreeAll,
                onChanged: (v) => onToggleAll(v ?? false),
                activeColor: const Color(0xFFF97316),
              ),
              const SizedBox(width: 6),
              const Text('모두 동의합니다', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              _AgreementRow(
                checked: agreeTos,
                label: '[필수] 이용약관 동의',
                onToggle: onToggleTos,
                onView: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupTermsScreen(doc: 'tos')),
                ),
              ),
              const SizedBox(height: 8),
              _AgreementRow(
                checked: agreePrivacy,
                label: '[필수] 개인 정보 수집 및 이용 동의',
                onToggle: onTogglePrivacy,
                onView: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupTermsScreen(doc: 'privacy')),
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

  const _AgreementRow({required this.checked, required this.label, required this.onToggle, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: (v) => onToggle(v ?? false),
          activeColor: const Color(0xFFF97316),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ),
        TextButton(
          onPressed: onView,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
            textStyle: const TextStyle(fontSize: 12),
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

