import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/change_email_view_model.dart';

class ChangeEmailScreen extends StatefulWidget {
  static const routeName = '/change-email';

  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChangeEmailViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChangeEmailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원정보 변경'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  '안전하게 이메일을 변경하기 위해서\n비밀번호를 한 번 더 입력해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.35),
                ),
                const SizedBox(height: 22),
                const Text('현재 이메일', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 6),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: vm.currentEmail)
                    ..selection = TextSelection.collapsed(offset: vm.currentEmail.length),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: !vm.step1Done && !vm.loading,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: '비밀번호',
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: vm.setPassword,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: (!vm.step1Done && vm.password.isNotEmpty && !vm.loading) ? vm.verifyPassword : null,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) return const Color(0xFFD1D5DB);
                            return const Color(0xFFF97316);
                          }),
                        ),
                        child: vm.step1Done
                            ? const Text('완료', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                            : (vm.loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('확인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ],
                ),
                if (vm.step1Done) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: !vm.step2Done && !vm.loading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: '새 이메일 (@sch.ac.kr)',
                            border: UnderlineInputBorder(),
                          ),
                          onChanged: vm.setNewEmail,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: (!vm.step2Done && vm.isValidNewEmail && !vm.loading) ? vm.sendCode : null,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) return const Color(0xFFD1D5DB);
                              return const Color(0xFFF97316);
                            }),
                          ),
                          child: vm.step2Done
                              ? const Text('완료', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                              : (vm.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('인증 요청', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                        ),
                      ),
                    ],
                  ),
                ],
                if (vm.step2Done) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '메일함 열기 (mail.sch.ac.kr)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: !vm.verified && !vm.loading,
                          decoration: const InputDecoration(
                            hintText: '인증 코드',
                            border: UnderlineInputBorder(),
                          ),
                          onChanged: vm.setCode,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: (!vm.verified && vm.code.isNotEmpty && !vm.loading) ? vm.verifyCode : null,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) return const Color(0xFFD1D5DB);
                              return const Color(0xFF22C55E);
                            }),
                          ),
                          child: vm.verified
                              ? const Text('완료', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                              : (vm.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('확인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                        ),
                      ),
                    ],
                  ),
                ],
                if (vm.verified) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final ok = await vm.finalizeAndRefreshMe();
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/mypage', (r) => false);
                        } else {
                          await showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              content: const Text(
                                '이메일 변경은 성공했지만 정보 갱신에 실패했습니다.\n다시 로그인해주세요.',
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                        }
                      },
                      child: const Text('이메일 변경하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
                if (vm.errMsg != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    vm.errMsg!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


