import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import '../admin/admin_home.dart';
import '../screens/notice_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedProjectId;
  String? _selectedProjectName;
  Map<String, String> _projectIdNameMap = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.assignedProjects.isNotEmpty && _selectedProjectId == null) {
      _fetchProjectNames(userProvider);
    }
  }

  Future<void> _fetchProjectNames(UserProvider userProvider) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where(FieldPath.documentId, whereIn: userProvider.assignedProjects)
        .get();

    final Map<String, String> idNameMap = {
      for (var doc in snapshot.docs)
        doc.id: (doc.data()['name'] ?? doc.id).toString()
    };

    setState(() {
      _projectIdNameMap = idNameMap;
      _selectedProjectId = userProvider.assignedProjects.first;
      _selectedProjectName = idNameMap[_selectedProjectId];
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.read<UserProvider>().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ---- ここから：URL起動（iOS対応強化版） ----------------------------------------

  /// スキームが無ければ https を補完して Uri を返す（mailto/tel/sms はそのまま）
  Uri? _normalizeToUri(String raw) {
    String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final hasExplicitScheme =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://').hasMatch(trimmed) ||
            trimmed.startsWith('mailto:') ||
            trimmed.startsWith('tel:') ||
            trimmed.startsWith('sms:');

    if (!hasExplicitScheme) {
      // 例: "www.example.com" → "https://www.example.com"
      trimmed = 'https://$trimmed';
    }

    try {
      return Uri.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// まず外部アプリで開き、失敗したら http/https に限りアプリ内ブラウザで再トライ
  Future<void> _launchURL(String raw) async {
    final uri = _normalizeToUri(raw);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('URL形式が不正です')));
      return;
    }

    // iOS: canLaunchUrl 依存は避け、直接トライが安定
    bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    // 外部起動に失敗した場合、http/httpsのみ in-app でフォールバック
    if (!ok && (uri.scheme == 'https' || uri.scheme == 'http')) {
      ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }

    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('URLを開けません: $uri')));
    }
  }

  // ---- ここまで：URL起動（iOS対応強化版） ----------------------------------------

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading || _selectedProjectId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final assigned = userProvider.assignedProjects;

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
            ...assigned.map((id) => ListTile(
              title: Text(_projectIdNameMap[id] ?? id),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedProjectId = id;
                  _selectedProjectName = _projectIdNameMap[id];
                });
              },
            )),
            const Divider(),
            if (userProvider.role == 'admin')
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
        title: Text('# ${_selectedProjectName ?? "未選択"}'),
        centerTitle: true,
        actions: [

          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeListScreen()),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== プロジェクトショートカット（共通）
          Row(
            children: const [
              Text('プロジェクトショートカット集',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(_selectedProjectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return const SizedBox(
                    height: 100, child: Center(child: CircularProgressIndicator()));
              }

              final data = snapshot.data!.data()!;
              final links = List<Map<String, dynamic>>.from(data['links'] ?? []);

              if (links.isEmpty) {
                return const Text('登録されたリンクがありません');
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: links.map((link) {
                  return GestureDetector(
                    onTap: () => _launchURL((link['url'] ?? '').toString()),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/${link['icon']}',
                          width: 48,
                          height: 48,
                          errorBuilder: (_, __, ___) => const Icon(Icons.link, size: 48),
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

          // ===== 個人ショートカット（プロジェクト紐づけのみ）
          Row(
            children: [
              const Text('個人設定ショートカット集',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ヘルプ'),
                      content: const Text(
                          '+ AddApps から「このプロジェクト専用の」ショートカットを追加できます。長押しで削除できます。'),
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
          _UserProjectLinksList(
            key: ValueKey(_selectedProjectId), // プロジェクト切替時に確実にStreamを張り替える
            uid: userProvider.uid!,
            projectId: _selectedProjectId!,
            onOpenUrl: _launchURL,
            onTapAdd: () {
              Navigator.pushNamed(
                context,
                '/add_userlink',
                arguments: {
                  'projectId': _selectedProjectId,
                  'projectName': _selectedProjectName,
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 個人ショートカット（プロジェクト配下のみを表示）
class _UserProjectLinksList extends StatelessWidget {
  final String uid;
  final String projectId;
  final Future<void> Function(String url) onOpenUrl;
  final VoidCallback onTapAdd;

  const _UserProjectLinksList({
    super.key,
    required this.uid,
    required this.projectId,
    required this.onOpenUrl,
    required this.onTapAdd,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(projectId)
        .collection('links')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ...docs.map((doc) {
              final data = doc.data();
              final iconFile = (data['icon'] ?? '').toString();
              final title = (data['title'] ?? '').toString();
              final url = (data['url'] ?? '').toString();

              return GestureDetector(
                onTap: () => onOpenUrl(url),
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('削除確認'),
                      content: Text('このリンクを削除しますか？\n$title'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('キャンセル')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('削除')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await doc.reference.delete();
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iconFile.isNotEmpty)
                      Image.asset(
                        'assets/icons/$iconFile',
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.link, size: 48, color: Colors.blue),
                      )
                    else
                      const Icon(Icons.link, size: 48, color: Colors.blue),
                    const SizedBox(height: 4),
                    Text(title),
                  ],
                ),
              );
            }),
            // AddApps
            GestureDetector(
              onTap: onTapAdd,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_box, size: 48, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('AddApps'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
