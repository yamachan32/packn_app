import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// ログイン状態に応じて Login / Home を出し分け。
/// ログイン後は UserProvider.loadUserData() を呼んでユーザ情報をロード。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // 未ログイン
        if (!snap.hasData) {
          return const LoginScreen();
        }

        // ユーザ情報ロード（何度呼ばれても問題なし）
        context.read<UserProvider>().loadUserData();

        // Home 側で UserProvider.isLoading を見て待機描画
        return const HomeScreen();
      },
    );
  }
}
