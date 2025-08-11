import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/user_provider.dart';
import 'providers/selected_project_provider.dart';
import 'providers/notice_provider.dart';
import 'providers/projects_provider.dart';          // ★ 追加
import 'gates/auth_gate.dart';

// 画面
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_userlink_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()), // ★
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'packn',
        home: const AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/add_userlink': (_) => const AddUserLinkScreen(),
        },
      ),
    );
  }
}
