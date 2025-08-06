import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_account_menu.dart';
import 'admin_project_menu.dart';
import 'admin_notice_menu.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Text('プロジェクト切り替え', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('projects').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final projects = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final name = projects[index]['name'] ?? '無名プロジェクト';
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            Navigator.pop(context); // ドロワーを閉じる
                            // 必要なら状態管理して選択プロジェクトを保持
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              // ヘッダー
              Container(
                color: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _openDrawer(context),
                      icon: const Icon(Icons.menu, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Packn Admin',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '管理者ホーム',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('管理者メニュー', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(height: 4, width: 40, color: Colors.amber),
                        const Expanded(child: Divider(color: Colors.grey, thickness: 2)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildMenuButton(
                      label: 'アカウント管理',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountMenu()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      label: 'プロジェクト管理',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProjectMenu()));
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      label: 'お知らせ管理',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNoticeMenu()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
