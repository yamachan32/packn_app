import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import '../providers/notice_provider.dart';
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
  List<String> _lastAssigned = const []; // 直近の一覧を保持して変化検知

  // ▼ 追加：削除/無効ユーザ検知用
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  bool _disabledDialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    final now = List<String>.from(userProvider.assignedProjects);
    // 初回 or 変化（件数 or 中身）があれば再フェッチ
    if (_selectedProjectId == null ||
        now.length != _lastAssigned.length ||
        now.toSet().difference(_lastAssigned.toSet()).isNotEmpty) {
      _refreshProjectNames(now);
    }

    // ▼ 追加：users/{uid} を購読して無効ユーザを検知（モーダルは一度だけ）
    _bindDisabledWatcher(userProvider.uid);
  }

  void _bindDisabledWatcher(String? uid) {
    if (uid == null) return;
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted || _disabledDialogShown) return;
      final data = snap.data();
      final exists = snap.exists;
      final isDisabled = !exists ||
          (data?['isActive'] == false) ||
          (data?['disabled'] == true) ||
          ((data?['status'] ?? '') == 'deleted') ||
          (data?['deletedAt'] != null);
      if (isDisabled) {
        _showDisabledDialogAndLogout(email: FirebaseAuth.instance.currentUser?.email);
      }
    });
  }

  Future<void> _showDisabledDialogAndLogout({String? email}) async {
    _disabledDialogShown = true;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('アカウントをご利用できません'),
        content: Text(
          (email == null || email.isEmpty)
              ? 'このアカウントは削除または無効化されています。管理者にお問い合わせください。'
              : '$email は削除または無効化されています。管理者にお問い合わせください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    try {
      await FirebaseAuth.instance.signOut(); // AuthGate が Login に切替
    } catch (_) {}
  }

  // whereIn 10件制限を回避しつつ名前を再取得
  Future<void> _refreshProjectNames(List<String> assigned) async {
    _lastAssigned = List<String>.from(assigned);
    if (!mounted) return;
    if (assigned.isEmpty) {
      if (!mounted) return;
      setState(() {
        _projectIdNameMap = {};
        _selectedProjectId = null;
        _selectedProjectName = null;
      });
      return;
    }

    final projectsCol = FirebaseFirestore.instance.collection('projects');
    final Map<String, String> idNameMap = {};

    const chunk = 10;
    for (var i = 0; i < assigned.length; i += chunk) {
      final end = (i + chunk < assigned.length) ? (i + chunk) : assigned.length;
      final slice = assigned.sublist(i, end);
      final snap =
      await projectsCol.where(FieldPath.documentId, whereIn: slice).get();
      if (!mounted) return;
      for (final doc in snap.docs) {
        idNameMap[doc.id] = (doc.data()['name'] ?? doc.id).toString();
      }
    }

    if (!mounted) return;
    setState(() {
      _projectIdNameMap = idNameMap;
      if (_selectedProjectId == null || !assigned.contains(_selectedProjectId)) {
        _selectedProjectId = assigned.first;
      }
      _selectedProjectName = idNameMap[_selectedProjectId] ?? _selectedProjectId;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.read<UserProvider>().logout();
    // ここでは画面遷移しない（AuthGate が自動で Login に切替）
  }

  /// URL補正
  Uri? _normalizeToUri(String raw) {
    String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final hasExplicitScheme =
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://').hasMatch(trimmed) ||
            trimmed.startsWith('mailto:') ||
            trimmed.startsWith('tel:') ||
            trimmed.startsWith('sms:');

    if (!hasExplicitScheme) {
      trimmed = 'https://$trimmed';
    }

    try {
      return Uri.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  /// URL起動
  Future<void> _launchURL(String raw) async {
    final uri = _normalizeToUri(raw);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('URL形式が不正です')));
      return;
    }

    bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && (uri.scheme == 'https' || uri.scheme == 'http')) {
      ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }

    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('URLを開けません: $uri')));
    }
  }

  @override
  void dispose() {
    _userDocSub?.cancel(); // 追加：購読解除
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final unread = context.watch<NoticeProvider>().unreadCount;

    if (userProvider.isLoading || _selectedProjectId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final assigned = userProvider.assignedProjects;

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlueAccent),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'プロジェクト選択',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            // 上部はスクロール領域
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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
                ],
              ),
            ),
            const Divider(height: 1),
            // ↓↓↓ フッタ固定エリア：管理者メニュー → ログアウト の順に配置 ↓↓↓
            if (userProvider.role == 'admin')
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () {
                Navigator.pop(context); // 先にドロワーを閉じると体験が良い
                _logout();
              },
            ),
            SafeArea(top: false, child: const SizedBox(height: 4)), // 端末下部と干渉しないよう少し余白
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('# ${_selectedProjectName ?? "未選択"}'),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: unread > 0 ? 'お知らせ（未読 $unread 件）' : 'お知らせ',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NoticeListScreen()),
                  );
                },
              ),
              if (unread > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    onTap: () => _launchURL((link['url'] ?? '').toString()),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/${link['icon']}',
                          width: 48,
                          height: 48,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.link, size: 48),
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
            key: ValueKey(_selectedProjectId),
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
