import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/admin_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userRole;
  bool _checkingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        // Firestore にユーザが存在しない → ログアウト + 警告表示
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('アカウント無効'),
            content: const Text('このアカウントは削除されています。\n管理者にお問い合わせください。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                    ..pop()
                    ..pushReplacementNamed('/login');
                },
                child: const Text('ログイン画面に戻る'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _userRole = doc.data()?['role'];
          _checkingUser = false;
        });
      }
    } else {
      setState(() {
        _checkingUser = false;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'メニュー',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('プロジェクトを切り替え'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('プロジェクト切り替えは未実装です')),
                );
              },
            ),
            if (_userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('管理者メニュー'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminHome()),
                  );
                },
              ),
          ],
        ),
      ),
      body: const Center(
        child: Text('ようこそ、Packnへ！'),
      ),
    );
  }
}
