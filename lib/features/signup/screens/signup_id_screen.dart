import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/app_bar_common.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';
import '../../../common/widgets/app_button.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<SignupViewModel>();
      // 로그인에서 회원가입으로 진입한 경우에만 초기화(학번→이름 화면에서 뒤로 온 경우는 유지)
      if (!vm.fromCredentials) {
        vm.reset();
        await vm.clearDraft();
      }
      await vm.loadDraft();
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
                            text: TextSpan(
                              style: AppTypography.subtitle1.copyWith(color: AppColors.gray7),
                              children: [
                                const TextSpan(text: '아이디'),
                                TextSpan(text: '*', style: AppTypography.subtitle1.copyWith(color: AppColors.orange)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            cursorColor: AppColors.orange,
                            style: AppTypography.body2.copyWith(color: AppColors.black),
                            decoration: InputDecoration(
                              hintText: '학번 8자리를 입력해주세요',
                              hintStyle: AppTypography.body2.copyWith(color: AppColors.gray5),
                              border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray7)),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gray3)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.orange, width: 2)),
                            ),
                            onChanged: vm.onChangeId,
                          ),
                          const SizedBox(height: 8),
                          if (vm.checkingId)
                            Text('중복 확인 중…', style: AppTypography.caption2.copyWith(color: AppColors.gray7)),
                          if (vm.idOk == false && vm.idErrorMessage != null)
                            Text(vm.idErrorMessage!, style: AppTypography.caption1.copyWith(color: AppColors.error)),
                          if (vm.idOk == true)
                            Text('사용가능한 아이디입니다', style: AppTypography.caption1.copyWith(color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: AppButton(
                label: '확인',
                variant: AppButtonVariant.primary,
                large: true,
                onPressed: vm.canNextFromId
                    ? () async {
                        vm.markFromCredentials();
                        await vm.saveDraft();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamed('/signup/credentials');
                      }
                    : null,
              ),
            ),
          ],
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
        Text(
          '오늘순밥에 오신 것을\n환영합니다!',
          style: AppTypography.headline1.copyWith(fontSize: 24, height: 32 / 24),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppTypography.caption2.copyWith(color: AppColors.gray7),
            children: [
              TextSpan(text: '1분', style: AppTypography.caption1.copyWith(color: AppColors.orange)),
              const TextSpan(text: '이면 회원가입 가능해요'),
            ],
          ),
        ),
      ],
    );
  }
}


