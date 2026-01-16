import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/find_account_view_model.dart';

class FindAccountScreen extends StatefulWidget {
  static const routeName = '/find-account';

  const FindAccountScreen({super.key});

  @override
  State<FindAccountScreen> createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountScreen> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    context.read<FindAccountViewModel>().initTabFromArgs(ModalRoute.of(context)?.settings.arguments);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FindAccountViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _FindAccountTabs(
                tab: vm.tab,
                onChanged: (vm.loading || vm.verifying) ? null : vm.setTab,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: vm.tab == FindAccountTab.id ? const _FindIdForm() : const _ResetPasswordForm(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindAccountTabs extends StatelessWidget {
  final FindAccountTab tab;
  final ValueChanged<FindAccountTab>? onChanged;

  const _FindAccountTabs({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tabButton({required String label, required FindAccountTab value}) {
      final active = tab == value;
      return Expanded(
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
                  width: active ? 2 : 1,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? const Color(0xFFF97316) : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tabButton(label: '아이디 찾기', value: FindAccountTab.id),
        tabButton(label: '비밀번호 찾기', value: FindAccountTab.pw),
      ],
    );
  }
}

class _FindIdForm extends StatelessWidget {
  const _FindIdForm();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FindAccountViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(hintText: '이름', border: UnderlineInputBorder()),
          onChanged: vm.setName,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(hintText: '이메일', border: UnderlineInputBorder()),
          onChanged: vm.setEmail,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return const Color(0xFFF97316).withValues(alpha: 0.4);
                return const Color(0xFFF97316);
              }),
            ),
            onPressed: (vm.name.trim().isNotEmpty && vm.email.trim().isNotEmpty && !vm.loading) ? vm.findId : null,
            child: vm.loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('확인', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        if (vm.foundUserId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('입력하신 회원정보와 일치하는 아이디는 ${vm.foundUserId} 입니다.'),
          ),
        ],
        if (vm.error != null) ...[
          const SizedBox(height: 10),
          Text(vm.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
        ],
      ],
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FindAccountViewModel>();

    final domain = vm.resetEmail.contains('@') ? vm.resetEmail.split('@').last : '';
    final mailLinkText = domain.isNotEmpty ? '메일함 열기 (mail.$domain)' : '메일함 열기 (mail.sch.ac.kr)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('이메일', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: '예) cheonbab@cheon.ac.kr',
                  border: UnderlineInputBorder(),
                ),
                onChanged: vm.setResetEmail,
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
                    if (states.contains(WidgetState.disabled)) return const Color(0xFFF97316).withValues(alpha: 0.5);
                    return const Color(0xFFF97316);
                  }),
                ),
                onPressed: (vm.resetEmail.trim().isNotEmpty && !vm.loading) ? vm.requestResetEmail : null,
                child: vm.loading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('인증 요청', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (vm.error != null) ...[
          const SizedBox(height: 8),
          Text(vm.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
        ],
        if (vm.success != null) ...[
          const SizedBox(height: 8),
          Text('✅ ${vm.success!}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
        ],
        if (vm.emailSent) ...[
          const SizedBox(height: 16),
          const Text('인증 코드', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: '메일로 받은 인증 코드 입력',
              border: UnderlineInputBorder(),
            ),
            onChanged: vm.setToken,
          ),
          const SizedBox(height: 8),
          Text(
            mailLinkText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
          ),
        ],
        const SizedBox(height: 18),
        const Text('새 비밀번호', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: '새 비밀번호', border: UnderlineInputBorder()),
          onChanged: vm.setNewPw,
        ),
        const SizedBox(height: 16),
        const Text('비밀번호 확인', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: '새 비밀번호 확인', border: UnderlineInputBorder()),
          onChanged: vm.setNewPw2,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) return const Color(0xFFF97316).withValues(alpha: 0.5);
                return const Color(0xFFF97316);
              }),
            ),
            onPressed: (vm.token.trim().isNotEmpty && vm.newPw.isNotEmpty && vm.newPw2.isNotEmpty && !vm.verifying)
                ? () async {
                    await vm.confirmResetPassword();
                    if (!context.mounted) return;
                    if (vm.error == null && vm.success != null) {
                      Navigator.of(context).pushReplacementNamed('/');
                    }
                  }
                : null,
            child: vm.verifying
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}


