import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/admin_open_status_card.dart';
import '../../../common/widgets/admin_square_card.dart';
import '../../../common/widgets/admin_wide_card.dart';
import '../../../common/widgets/app_bar_common.dart';
import '../../../common/widgets/profile_card.dart';
import 'admin_settings_screen.dart';
import '../viewmodels/admin_home_view_model.dart';
import '../../../util/colors.dart';
import '../../../util/typography.dart';

/// MainScreen 탭 0에서 사용: 마이페이지와 동일한 헤더 + 관리자 대시보드 본문 + (바텀바는 MainScreen에서 제공)
class AdminTabContent extends StatefulWidget {
  const AdminTabContent({super.key});

  @override
  State<AdminTabContent> createState() => _AdminTabContentState();
}

class _AdminTabContentState extends State<AdminTabContent> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminHomeViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBarCommon(
        showBack: false,
        title: '',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.gray5, size: 22),
            onPressed: () =>
                Navigator.of(context).pushNamed(AdminSettingsScreen.routeName),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const _AdminDashboardBody(),
    );
  }
}

/// 관리자 대시보드 본문 (영업상태, 재고, 메뉴, 로그아웃 등)
class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminHomeViewModel>();

    final storeName = vm.store?.name.isNotEmpty == true
        ? vm.store!.name
        : (vm.me?.storeName?.isNotEmpty == true
              ? vm.me!.storeName!
              : '가게명 불러오는 중...');

    return Container(
      color: const Color(0xFFF3F4F6),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 상단 흰색 바: 마이페이지처럼 프로필 카드 아래까지 내려오게 처리
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: AdminProfileCard(storeName: storeName),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: AdminOpenStatusCard(
                    isOpen: vm.isOpen,
                    loading: vm.loading || vm.toggling,
                    onToggle: vm.toggling ? null : () => vm.toggleOpen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminSquareCard(
                    title: '재고 관리',
                    onTap: () {
                      Navigator.of(context).pushNamed('/admin/inventory').then((
                        _,
                      ) {
                        if (!context.mounted) return;
                        context.read<AdminHomeViewModel>().load();
                      });
                    },
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.gray6,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdminWideCard(
              title: '메뉴 관리',
              onTap: () => Navigator.of(context).pushNamed('/admin/menu'),
            ),
          ),

          if (vm.loading) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                vm.errorMessage!,
                style: AppTypography.caption2.copyWith(
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// /admin 라우트: MainScreen으로 리다이렉트 (탭 3 선택)하여 바텀바와 동일 레이아웃 유지.
/// StatefulWidget 유지 시 Hot Reload 시 기존 트리의 State 타입과 충돌하지 않음.
class AdminHomeScreen extends StatefulWidget {
  static const routeName = '/admin';

  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeRedirectState();
}

class _AdminHomeRedirectState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/', (r) => false, arguments: 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
