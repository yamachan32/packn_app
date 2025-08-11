import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:packn_app/providers/accounts_provider.dart';
import 'admin_account_editor.dart';

class AdminAccountMenu extends StatefulWidget {
  const AdminAccountMenu({super.key});

  @override
  State<AdminAccountMenu> createState() => _AdminAccountMenuState();
}

class _AdminAccountMenuState extends State<AdminAccountMenu> {
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bound) {
      _bound = true;
      context.read<AccountsProvider>().bind();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountsProvider>();
    final items = provider.accounts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('アカウント一覧', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '新規作成',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAccountEditor()),
              );
            },
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('アカウント一覧'),
                const _Underline(),
                const SizedBox(height: 6),

                // 背景カードなし。薄い区切り線のみ。
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (_, i) {
                    final u = items[i];
                    final id = (u['id'] ?? '').toString();
                    final email = (u['email'] ?? '').toString();
                    final name = (u['name'] ?? '').toString();
                    final role = (u['role'] ?? '').toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      title: Text(name.isEmpty ? email : name),
                      subtitle: Text(email),
                      leading: Text(
                        role == 'admin' ? '管理者' : 'ユーザ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '編集',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminAccountEditor(initial: u),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: '削除',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('削除確認'),
                                  content: Text('「$email」を削除します。よろしいですか？'),
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
                              if (!mounted) return;
                              if (ok == true) {
                                await context.read<AccountsProvider>().delete(id);
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminAccountEditor(initial: u),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700));
  }
}

class _Underline extends StatelessWidget {
  const _Underline();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 60, height: 4, color: Colors.amber),
        Expanded(child: Container(height: 4, color: Colors.black54)),
      ],
    );
  }
}
