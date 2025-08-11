import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/selected_project_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// 認証状態に応じて Login / Home / Loading を出し分けるゲート。
/// アプリの home にこれを置くことで、ログイン時の読み込みと
/// プロジェクト初期選択を一元化します。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    // UserProvider が Firestore 読み込み中
    if (user.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 未ログイン
    if (user.uid == null) {
      return const LoginScreen();
    }

    // 初回の選択プロジェクト設定
    final selected = context.read<SelectedProjectProvider>();
    if (selected.id == null && user.assignedProjects.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selected.setId(user.assignedProjects.first);
      });
    }

    return const HomeScreen();
  }
}
