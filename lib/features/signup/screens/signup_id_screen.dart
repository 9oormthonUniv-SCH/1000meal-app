import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/viewmodels/signup_view_model.dart';

class SignupIdScreen extends StatefulWidget {
  static const routeName = '/signup/id';

  const SignupIdScreen({super.key});

  @override
  State<SignupIdScreen> createState() => _SignupIdScreenState();
}

class _SignupIdScreenState extends State<SignupIdScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignupViewModel>().loadDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const _SignupHeader(),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                          children: [
                            TextSpan(text: '아이디'),
                            TextSpan(text: '*', style: TextStyle(color: Color(0xFFF97316))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: '학번 8자리를 입력해주세요',
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: vm.onChangeId,
                      ),
                      const SizedBox(height: 8),
                      if (vm.checkingId)
                        const Text('중복 확인 중…', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      if (vm.idOk == false && vm.idErrorMessage != null)
                        Text(vm.idErrorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                      if (vm.idOk == true)
                        const Text('사용가능한 아이디입니다', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        disabledBackgroundColor: const Color(0xFFF97316),
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
                      onPressed: vm.canNextFromId
                          ? () async {
                              await vm.saveDraft();
                              if (!context.mounted) return;
                              Navigator.of(context).pushNamed('/signup/credentials');
                            }
                          : null,
                      child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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


