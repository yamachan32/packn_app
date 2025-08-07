import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../admin/admin_home.dart';
import '../widgets/notice_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
      for (var doc in snapshot.docs) doc.id: (doc.data()['name'] ?? doc.id).toString()
    };

    setState(() {
      _projectIdNameMap = idNameMap;
      _selectedProjectId = userProvider.assignedProjects.first;
      _selectedProjectName = idNameMap[_selectedProjectId];
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Provider.of<UserProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けません')),
      );
    }
  }

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
              child: Text('プロジェクト選択', style: TextStyle(fontSize: 18, color: Colors.white)),
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
            ))
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('# ${_selectedProjectName ?? "未選択"}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => showNoticeDialog(context, _selectedProjectId),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('プロジェクトショートカット集',
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
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
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
                    onTap: () => _launchURL(link['url']),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/${link['icon']}',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(height: 4),
                        Text(link['label'] ?? ''),
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
              const Text('個人設定ショートカット集',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ヘルプ'),
                      content: const Text('+ AddApps から自分専用のショートカットを追加できます。長押しで削除ができます。'),
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
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userProvider.uid)
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
                    return GestureDetector(
                      onTap: () => _launchURL(data['url']),
                      onLongPress: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('削除確認'),
                            content: const Text('このリンクを削除しますか？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('キャンセル'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
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
                          const Icon(Icons.folder, size: 48, color: Colors.blue),
                          const SizedBox(height: 4),
                          Text(data['title'] ?? ''),
                        ],
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/add_userlink'),
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
          ),
        ],
      ),
    );
  }
}
