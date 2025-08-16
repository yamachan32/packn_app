import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:packn_app/providers/projects_provider.dart' as pp;
import '../providers/user_provider.dart';

import 'admin_notice_menu.dart';
import 'admin_project_menu.dart';
import 'admin_account_menu.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bound) {
      _bound = true;
      context.read<pp.ProjectsProvider>().bind();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<pp.ProjectsProvider>().projects;
    final assignedProjectIds = context.watch<UserProvider>().assignedProjects;

    // アサインされたプロジェクトだけに絞り込み
    final filteredProjects = projects
        .where((p) => assignedProjectIds.contains(p['id']))
        .toList();

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // ヘッダー：薄い黄色
            Container(
              color: Colors.amber.shade100,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: kToolbarHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    '管理者メニュー',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // メニューリストはスクロール可能に
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // プロジェクトへ移動（ユーザホーム）
                  const ListTile(
                    title: Text('プロジェクトに移動',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...filteredProjects.map((p) {
                    final id = (p['id'] ?? '').toString();
                    final name = (p['name'] ?? '').toString();
                    return ListTile(
                      leading: const Icon(Icons.folder_open),
                      title: Text(name.isEmpty ? id : name),
                      onTap: () {
                        Navigator.pop(context); // Drawer を閉じる
                        Navigator.pushNamed(context, '/home',
                            arguments: {'projectId': id});
                      },
                    );
                  }),

                  const Divider(),
                ],
              ),
            ),

            // フッタ固定のログアウト
            SafeArea(
              top: false,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('管理者ホーム',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // ログアウトアイコンはヘッダに表示しない
      ),
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.94,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('管理メニュー',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Container(width: 60, height: 4, color: Colors.amber),
                  Expanded(child: Container(height: 4, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 16),

              _menuButton(
                context,
                label: 'アカウント管理',
                icon: Icons.manage_accounts_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAccountMenu()),
                ),
              ),

              const SizedBox(height: 12),
              _menuButton(
                context,
                label: 'プロジェクト管理',
                icon: Icons.work_outline,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProjectMenu()),
                ),
              ),
              const SizedBox(height: 12),
              _menuButton(
                context,
                label: 'お知らせ管理',
                icon: Icons.campaign_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminNoticeMenu()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          textStyle:
          const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
