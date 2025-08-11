import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/user_provider.dart';
import 'providers/selected_project_provider.dart';
import 'gates/auth_gate.dart';

// 既存の画面
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_userlink_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // firebase_options.dart が無くても動く最小初期化
  // （android: google-services.json / ios: GoogleService-Info.plist を配置済みであること）
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SelectedProjectProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'packn',
        home: const AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          // ルート経由の遷移時にも projectId を安全に注入
          '/add_userlink': (context) {
            final pid = context.read<SelectedProjectProvider>().id;
            if (pid == null || pid.isEmpty) {
              // 非選択時は簡易ガード（必要に応じて Home に戻す等でもOK）
              return const Scaffold(
                body: Center(child: Text('プロジェクトが未選択です。')),
              );
            }
            return AddUserLinkScreen(projectId: pid);
          },
        },
      ),
    );
  }
}
