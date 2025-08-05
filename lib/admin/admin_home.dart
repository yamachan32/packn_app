import 'package:flutter/material.dart';
import 'admin_account_menu.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー部分
            Container(
              color: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '<他の参加プロジェクトを選択',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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

            // タイトル
            const Text(
              '管理者ホーム',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // メニューラベル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '管理者メニュー',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // 下線＋黄色ライン
                  Row(
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        color: Colors.amber,
                      ),
                      const Expanded(
                        child: Divider(
                          color: Colors.grey,
                          thickness: 2,
                          height: 2,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // メニューボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuButton(
                    label: 'アカウント管理',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAccountMenu(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    label: 'プロジェクト管理',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('プロジェクト管理は未実装')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    label: 'お知らせ管理',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('お知らせ管理は未実装')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    label: 'アイコン画像管理',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('アイコン画像管理は未実装')),
                      );
                    },
                  ),
                ],
              ),
            )
          ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
