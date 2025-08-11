import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/notice_provider.dart';
import '../providers/selected_project_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// 認証状態ゲート + お知らせ自動購読開始（全体＋参加PJすべて）
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUid;
  String _lastProjectsKey = '';

  void _maybeBindNotices(BuildContext context) {
    final user = context.read<UserProvider>();
    final uid = user.uid;
    if (uid == null) {
      return;
    }

    final projects = List<String>.from(user.assignedProjects);
    projects.sort();
    final key = projects.join(',');

    if (_lastUid != uid || _lastProjectsKey != key) {
      _lastUid = uid;
      _lastProjectsKey = key;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NoticeProvider>().bindForUser(
          uid: uid,
          projectIds: projects,
          projectNames: Map<String, String>.from(user.projectNames),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    if (user.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.uid == null) {
      _lastUid = null;
      _lastProjectsKey = '';
      return const LoginScreen();
    }

    // Home の表示用に初回の選択PJを入れておく
    final selected = context.read<SelectedProjectProvider>();
    if (selected.id == null && user.assignedProjects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        selected.setId(user.assignedProjects.first);
      });
    }

    // 全体＋参加PJのお知らせを常時購読
    _maybeBindNotices(context);

    return const HomeScreen();
  }
}
