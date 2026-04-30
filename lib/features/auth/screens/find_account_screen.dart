import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/utils/external_link.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_segment_tabs.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';
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
      backgroundColor: AppColors.white,
      appBar: const AppBarCommon(title: ''),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              AppSegmentTabs<FindAccountTab>(
                value: vm.tab,
                enabled: !vm.loading && !vm.verifying,
                onChanged: vm.setTab,
                tabs: const [
                  AppSegmentTab(label: '아이디 찾기', value: FindAccountTab.id),
                  AppSegmentTab(label: '비밀번호 찾기', value: FindAccountTab.pw),
                ],
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

class _FindIdForm extends StatelessWidget {
  const _FindIdForm();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FindAccountViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이름', style: AppTypography.body4.copyWith(color: AppColors.gray8)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(hintText: '이름 입력', border: UnderlineInputBorder()),
          onChanged: vm.setName,
        ),
        const SizedBox(height: 16),
        Text('이메일', style: AppTypography.body4.copyWith(color: AppColors.gray8)),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: '예) cheonbab@sch.ac.kr',
            border: UnderlineInputBorder(),
          ),
          onChanged: vm.setEmail,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: '확인',
          variant: AppButtonVariant.primary,
          onPressed: (vm.name.trim().isNotEmpty && vm.email.trim().isNotEmpty && !vm.loading) ? vm.findId : null,
          loading: vm.loading,
        ),
        if (vm.foundUserId != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.gray1,
              border: Border.all(color: AppColors.gray3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '입력하신 회원정보와 일치하는 아이디는 ${vm.foundUserId} 입니다.',
              style: AppTypography.body4.copyWith(color: AppColors.black),
            ),
          ),
        ],
        if (vm.error != null) ...[
          const SizedBox(height: 10),
          Text(vm.error!, style: AppTypography.caption2.copyWith(color: AppColors.error)),
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
        Text('이메일', style: AppTypography.body4.copyWith(color: AppColors.gray8)),
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
                onChanged: vm.setResetEmail,
              ),
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: AppButton(
                label: '인증 요청',
                variant: AppButtonVariant.primary,
                height: 45,
                minWidth: 0,
                onPressed: (vm.resetEmail.trim().isNotEmpty && !vm.loading) ? vm.requestResetEmail : null,
                loading: vm.loading,
              ),
            ),
          ],
        ),
        if (vm.error != null) ...[
          const SizedBox(height: 8),
          Text(vm.error!, style: AppTypography.caption2.copyWith(color: AppColors.error)),
        ],
        if (vm.success != null) ...[
          const SizedBox(height: 8),
          Text('✅ ${vm.success!}', style: AppTypography.caption2.copyWith(color: AppColors.success)),
        ],
        if (vm.emailSent) ...[
          const SizedBox(height: 16),
          Text('인증 코드', style: AppTypography.body4.copyWith(color: AppColors.gray8)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: '메일로 받은 인증 코드 입력',
              border: UnderlineInputBorder(),
            ),
            onChanged: vm.setToken,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => openExternalUrl(domain.isNotEmpty ? 'https://mail.$domain' : 'https://mail.sch.ac.kr'),
            child: Text(
              mailLinkText,
              style: AppTypography.caption2.copyWith(color: AppColors.blue, decoration: TextDecoration.underline),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text('새 비밀번호', style: AppTypography.body4.copyWith(color: AppColors.gray8)),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: '새 비밀번호', border: UnderlineInputBorder()),
          onChanged: vm.setNewPw,
        ),
        const SizedBox(height: 16),
        Text('비밀번호 확인', style: AppTypography.body4.copyWith(color: AppColors.gray8)),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: '새 비밀번호 확인', border: UnderlineInputBorder()),
          onChanged: vm.setNewPw2,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: '비밀번호 변경',
          variant: AppButtonVariant.primary,
          onPressed: (vm.token.trim().isNotEmpty && vm.newPw.isNotEmpty && vm.newPw2.isNotEmpty && !vm.verifying)
              ? () async {
                  await vm.confirmResetPassword();
                  if (!context.mounted) return;
                  if (vm.error == null && vm.success != null) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                }
              : null,
          loading: vm.verifying,
        ),
      ],
    );
  }
}


