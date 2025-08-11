import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/accounts_provider.dart';
import 'admin_account_editor.dart';

class AdminAccountMenu extends StatefulWidget {
  const AdminAccountMenu({super.key});

  @override
  State<AdminAccountMenu> createState() => _AdminAccountMenuState();
}

class _AdminAccountMenuState extends State<AdminAccountMenu> {
  Future<void> _goAdd() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminAccountEditor()),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('アカウントを作成しました')));
    }
  }

  Future<void> _goEdit(String uid) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminAccountEditor(uid: uid)),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('アカウントを更新しました')));
    }
  }

  Future<void> _confirmDelete(String uid, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('このアカウントを削除しますか？\n$email'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await context.read<AccountsProvider>().deleteAccount(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('削除に失敗しました：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: yellow,
        foregroundColor: Colors.black87,
        title: const Text('アカウント一覧'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '追加',
            onPressed: _goAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: context.read<AccountsProvider>().streamAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('読み込みに失敗しました：${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('アカウントがありません'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();
              final uid = d.id;
              final name = (data['name'] ?? '').toString();
              final email = (data['email'] ?? '').toString();
              final role = (data['role'] ?? 'user').toString();

              return ListTile(
                title: Text(name.isNotEmpty ? name : email,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(email),
                leading: Icon(
                  role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                  color: role == 'admin' ? Colors.orange : Colors.grey.shade700,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '編集',
                      onPressed: () => _goEdit(uid),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: '削除',
                      onPressed: () => _confirmDelete(uid, email),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                onTap: () => _goEdit(uid),
              );
            },
          );
        },
      ),
    );
  }
}
