import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/role.dart';
import '../repositories/auth_repository.dart';

/// Route-level guard that prevents flashing the target screen before auth/role validation.
///
/// Policy:
/// - No token -> /login
/// - Token exists but role mismatch -> redirect to role-appropriate home:
///   - STUDENT -> /mypage
///   - ADMIN   -> /admin
class RoleGuard extends StatefulWidget {
  final Role targetRole;
  final Widget child;

  const RoleGuard({super.key, required this.targetRole, required this.child});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final repo = context.read<AuthRepository>();
    final token = await repo.getAccessToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      return;
    }

    try {
      final me = await repo.getMe();
      if (!mounted) return;

      if (me.role != widget.targetRole) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          me.role == Role.admin ? '/admin' : '/mypage',
          (r) => false,
        );
        return;
      }
    } catch (_) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      // best-effort logout (do not block UI / navigation)
      unawaited(repo.logout());
      return;
    }

    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    return widget.child;
  }
}
