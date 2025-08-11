import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import '../providers/selected_project_provider.dart';
import '../admin/admin_home.dart';
import '../screens/notice_list_screen.dart';
import '../screens/add_userlink_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// URLの正規化：スキームが無ければ https:// を付ける
  Uri _normalizeUrl(String raw) {
    var t = raw.trim();
    if (t.isEmpty) t = 'about:blank';
    // スキームが無ければ https を補完
    if (!t.contains('://')) t = 'https://$t';
    // 空白等が混ざっても飛べるように、encode は launchUrl 内部に任せる
    return Uri.parse(t);
  }

  Future<void> _launchURL(BuildContext context, String raw) async {
    final uri = _normalizeUrl(raw);
    try {
      // 直接 launchUrl。戻り値が false の場合のみエラーメッセージ
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('URLを開けません')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('URLを開けません: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final selectedProjectId = context.watch<SelectedProjectProvider>().id;

    if (user.isLoading || selectedProjectId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlueAccent),
              child: Text(
                'プロジェクト選択',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            ...user.assignedProjects.map(
                  (id) => ListTile(
                title: Text(user.getProjectName(id) ?? id),
                onTap: () {
                  Navigator.pop(context);
                  context.read<SelectedProjectProvider>().setId(id);
                },
              ),
            ),
            const Divider(),
            if (user.role == 'admin')
              ListTile(
                title: const Text('管理者メニュー'),
                leading: const Icon(Icons.admin_panel_settings),
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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('# ${user.getProjectName(selectedProjectId) ?? "未選択"}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UserProvider>().signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeListScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              Text(
                'プロジェクトショートカット集',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          // 現在選択中プロジェクトの共通リンク
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(selectedProjectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final data = snapshot.data!.data()!;
              final links =
              List<Map<String, dynamic>>.from(data['links'] ?? []);

              if (links.isEmpty) {
                return const Text('登録されたリンクがありません');
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: links.map((link) {
                  return GestureDetector(
                    onTap: () => _launchURL(context, (link['url'] ?? '').toString()),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/${link['icon']}',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(height: 4),
                        Text((link['label'] ?? '').toString()),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                '個人設定ショートカット集',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ヘルプ'),
                      content: const Text(
                        '+ AddApps から自分専用のショートカットを追加できます。長押しで削除ができます。',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.help_outline, size: 18),
              ),
            ],
          ),
          const Divider(),
          // 個人リンク
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('links')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ...docs.map((doc) {
                    final data = doc.data();
                    final iconName = (data['icon'] ?? '').toString();
                    final title = (data['title'] ?? '').toString();
                    final url = (data['url'] ?? '').toString();

                    return GestureDetector(
                      onTap: () => _launchURL(context, url),
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('削除確認'),
                            content: const Text('このリンクを削除しますか？'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('削除'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await doc.reference.delete();
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconName.isNotEmpty
                              ? Image.asset(
                            'assets/icons/$iconName',
                            width: 48,
                            height: 48,
                          )
                              : const Icon(Icons.folder,
                              size: 48, color: Colors.blue),
                          const SizedBox(height: 4),
                          Text(title),
                        ],
                      ),
                    );
                  }),
                  // AddApps：projectId は SelectedProjectProvider から取得して遷移
                  GestureDetector(
                    onTap: () {
                      final pid =
                          context.read<SelectedProjectProvider>().id;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddUserLinkScreen(projectId: pid),
                        ),
                      );
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_box, size: 48, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('AddApps'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
