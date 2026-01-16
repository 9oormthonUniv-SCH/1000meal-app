import 'package:flutter/material.dart';

import '../../auth/repositories/auth_repository.dart';
import '../../auth/models/role.dart';
import 'package:provider/provider.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$title (임시 화면)', style: const TextStyle(fontSize: 16)),
            if (title == '/ (메인)') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final repo = context.read<AuthRepository>();
                  final token = await repo.getAccessToken();
                  if (!context.mounted) return;
                  if (token == null || token.isEmpty) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                    return;
                  }
                  // UX: 토큰 "존재"만으로 마이페이지로 보내면
                  // 만료/무효 토큰일 때 `/mypage` -> `/login`으로 튕기며 깜빡임이 생김.
                  // 사전 검증(getMe)로 성공일 때만 마이페이지로 이동.
                  try {
                    final me = await repo.getMe();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamed(me.role == Role.admin ? '/admin' : '/mypage');
                  } catch (_) {
                    await repo.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                  }
                },
                child: const Text('마이페이지로 이동(임시)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


