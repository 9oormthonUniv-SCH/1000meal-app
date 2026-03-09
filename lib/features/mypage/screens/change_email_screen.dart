import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../common/utils/external_link.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';
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
      appBar: const AppBarCommon(
        title: '이메일 변경',
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  '안전하게 이메일을 변경하기 위해서\n비밀번호를 한 번 더 입력해주세요',
                  textAlign: TextAlign.center,
                  style: AppTypography.body4.copyWith(color: AppColors.gray7, height: 1.35),
                ),
                const SizedBox(height: 22),
                Text('현재 이메일', style: AppTypography.caption2.copyWith(color: AppColors.gray6)),
                const SizedBox(height: 6),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: vm.currentEmail)
                    ..selection = TextSelection.collapsed(offset: vm.currentEmail.length),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  style: TextStyle(color: AppColors.gray6),
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
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ).copyWith(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.disabled)) return AppColors.gray3;
                            return AppColors.orange;
                          }),
                        ),
                        child: vm.step1Done
                            ? Text('완료', style: AppTypography.caption1.copyWith(color: AppColors.white))
                            : (vm.loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                  )
                                : Text('확인', style: AppTypography.caption1.copyWith(color: AppColors.white))),
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
                            backgroundColor: AppColors.orange,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) return AppColors.gray3;
                              return AppColors.orange;
                            }),
                          ),
                          child: vm.step2Done
                              ? Text('완료', style: AppTypography.caption1.copyWith(color: AppColors.white))
                              : (vm.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                    )
                                  : Text('인증 요청', style: AppTypography.caption1.copyWith(color: AppColors.white))),
                        ),
                      ),
                    ],
                  ),
                ],
                if (vm.step2Done) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => openExternalUrl('https://mail.sch.ac.kr'),
                    child: Text(
                      '메일함 열기 (mail.sch.ac.kr)',
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.blue,
                        decoration: TextDecoration.underline,
                      ),
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
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) return AppColors.gray3;
                              return AppColors.success;
                            }),
                          ),
                          child: vm.verified
                              ? Text('완료', style: AppTypography.caption1.copyWith(color: AppColors.white))
                              : (vm.loading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                    )
                                  : Text('확인', style: AppTypography.caption1.copyWith(color: AppColors.white))),
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
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.white,
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
                      child: Text('이메일 변경하기', style: AppTypography.subtitle1.copyWith(color: AppColors.white)),
                    ),
                  ),
                ],
                if (vm.errMsg != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    vm.errMsg!,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption2.copyWith(color: AppColors.error),
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


