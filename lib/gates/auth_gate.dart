import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/notice_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// ログイン状態に応じて Login / Home を出し分け。
/// ログイン後は UserProvider.loadUserData() を呼び、
/// UserProvider が準備できたら NoticeProvider.bind(...) を実行。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // 未ログイン
        if (!snap.hasData) {
          // ログアウト時に念のため NoticeProvider の購読も止めたい場合は
          // Provider 側で dispose 済み。ここでは画面だけ切替。
          return const LoginScreen();
        }

        // ログイン済み：UserProvider のロードをキック（冪等）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<UserProvider>().loadUserData();
        });

        // UserProvider の状態に応じて NoticeProvider をバインド
        final up = context.watch<UserProvider>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!up.isLoading && up.uid != null) {
            context.read<NoticeProvider>().bind(
              uid: up.uid!,
              assignedProjectIds: up.assignedProjects,
            );
          }
        });

        // UserProvider がまだロード中なら待機画面
        if (up.isLoading || up.uid == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 準備OK → Home へ
        return const HomeScreen();
      },
    );
  }
}
