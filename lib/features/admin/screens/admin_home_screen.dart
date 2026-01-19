import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../../auth/repositories/auth_repository.dart';
import '../viewmodels/admin_home_view_model.dart';

class AdminHomeScreen extends StatefulWidget {
  static const routeName = '/admin';

  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminHomeViewModel>().load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminHomeViewModel>();

    final storeName = vm.store?.name.isNotEmpty == true
        ? vm.store!.name
        : (vm.me?.storeName?.isNotEmpty == true ? vm.me!.storeName! : '가게명 불러오는 중...');

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
        ),
        actions: [
          IconButton(
            onPressed: () => _showToast(context, '준비중입니다'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF3F4F6),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(999)),
                    child: const Text('관리자', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OpenStatusCard(
                    isOpen: vm.isOpen,
                    loading: vm.loading || vm.toggling,
                    onToggle: vm.toggling ? null : () => vm.toggleOpen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SquareCard(
                    title: '재고 관리',
                    subtitle: '',
                    onTap: () {
                      Navigator.of(context).pushNamed('/admin/inventory').then((_) {
                        if (!context.mounted) return;
                        context.read<AdminHomeViewModel>().load();
                      });
                    },
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WideCard(
              title: '메뉴 관리',
              onTap: () => _showToast(context, '다음 이슈에서 구현 예정'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                  // best-effort logout (do not block UI / navigation)
                  unawaited(context.read<AuthRepository>().logout());
                },
                child: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            if (vm.loading) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            if (vm.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(vm.errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  static void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)));
  }
}

class _OpenStatusCard extends StatelessWidget {
  final bool isOpen;
  final bool loading;
  final VoidCallback? onToggle;

  const _OpenStatusCard({
    required this.isOpen,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isOpen ? const Color(0xFF93C5FD) : Colors.white;
    final fg = isOpen ? Colors.white : const Color(0xFF9CA3AF);
    final toggleTrack = isOpen ? Colors.white : const Color(0xFFD1D5DB);
    final toggleThumb = isOpen ? const Color(0xFF93C5FD) : Colors.white;

    return InkWell(
      onTap: loading ? null : onToggle,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? '영업 중' : '영업 종료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isOpen ? Colors.white : const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                if (loading)
                  Text('처리 중...', style: TextStyle(fontSize: 12, color: fg))
                
              ],
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 64,
                  height: 36,
                  decoration: BoxDecoration(color: toggleTrack, borderRadius: BorderRadius.circular(999)),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: isOpen ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: toggleThumb, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SquareCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final fg = const Color(0xFF111827);
    final subFg = const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subFg)),
                ],
              ],
            ),
            Positioned(bottom: 6, right: 6, child: trailing ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _WideCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 28),
          ],
        ),
      ),
    );
  }
}


