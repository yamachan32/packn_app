import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'gates/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_userlink_screen.dart';
import 'screens/notice_list_screen.dart';
import 'screens/password_forget_screen.dart';

// Providers
import 'providers/user_provider.dart';
import 'providers/notice_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/accounts_provider.dart';
import 'providers/admin_notices_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // google-services.json / Info.plist に依存

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => AccountsProvider()),
        ChangeNotifierProvider(create: (_) => AdminNoticesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'packn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/notice_list': (_) => const NoticeListScreen(),
        '/password_forget': (_) => const PasswordForgetScreen(),
      },
      // /add_userlink は projectId を引数で受け取る
      onGenerateRoute: (settings) {
        if (settings.name == '/add_userlink') {
          final args = settings.arguments;
          String? projectId;
          String? projectName;
          if (args is Map) {
            if (args['projectId'] is String) projectId = args['projectId'] as String;
            if (args['projectName'] is String) projectName = args['projectName'] as String;
          }
          return MaterialPageRoute(
            builder: (_) => AddUserLinkScreen(projectId: projectId, projectName: projectName),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
