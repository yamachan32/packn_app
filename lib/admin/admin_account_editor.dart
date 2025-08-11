import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:packn_app/providers/accounts_provider.dart';

class AdminAccountEditor extends StatefulWidget {
  final Map<String, dynamic>? initial; // null: 新規 / 非null: 編集
  const AdminAccountEditor({super.key, this.initial});

  @override
  State<AdminAccountEditor> createState() => _AdminAccountEditorState();
}

class _AdminAccountEditorState extends State<AdminAccountEditor> {
  late final TextEditingController emailCtrl;
  late final TextEditingController nameCtrl;
  String role = 'user';

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: widget.initial?['email'] ?? '');
    nameCtrl  = TextEditingController(text: widget.initial?['name'] ?? '');
    role      = (widget.initial?['role'] ?? 'user').toString();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final id = widget.initial?['id'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(isEdit ? 'アカウント編集' : 'アカウント設定',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('ユーザID（メールアドレス）'),
                const _Underline(),
                const SizedBox(height: 6),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                const _Label('氏名'),
                const _Underline(),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                const _Label('権限'),
                const _Underline(),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('管理者')),
                    DropdownMenuItem(value: 'user',  child: Text('ユーザ')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? 'user'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      textStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      final email = emailCtrl.text.trim();
                      final name  = nameCtrl.text.trim();
                      if (email.isEmpty || name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('メールアドレスと氏名は必須です')),
                        );
                        return;
                      }

                      if (isEdit && id != null) {
                        final ok = await context
                            .read<AccountsProvider>()
                            .update(id: id, email: email, name: name, role: role);
                        if (!mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('更新に失敗しました')),
                          );
                          return;
                        }
                      } else {
                        final newId = await context
                            .read<AccountsProvider>()
                            .create(email: email, name: name, role: role);
                        if (!mounted) return;
                        if (newId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('作成に失敗しました')),
                          );
                          return;
                        }
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),

                const SizedBox(height: 12),
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
