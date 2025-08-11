import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Providers
import 'package:packn_app/providers/user_provider.dart';
import 'package:packn_app/providers/selected_project_provider.dart';
import 'package:packn_app/providers/notice_provider.dart';
import 'package:packn_app/providers/projects_provider.dart';
import 'package:packn_app/providers/admin_notices_provider.dart';
import 'package:packn_app/providers/accounts_provider.dart'; // ★ 追加

// Gates / Screens
import 'package:packn_app/gates/auth_gate.dart';
import 'package:packn_app/screens/login_screen.dart';
import 'package:packn_app/screens/home_screen.dart';
import 'package:packn_app/screens/add_userlink_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => AdminNoticesProvider()),
        ChangeNotifierProvider(create: (_) => AccountsProvider()), // ★ 追加
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
