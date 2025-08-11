import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:packn_app/providers/admin_notices_provider.dart' as np;
import 'package:packn_app/providers/projects_provider.dart' as pp;

import 'admin_notice_editor.dart';

class AdminNoticeMenu extends StatefulWidget {
  const AdminNoticeMenu({super.key});

  @override
  State<AdminNoticeMenu> createState() => _AdminNoticeMenuState();
}

class _AdminNoticeMenuState extends State<AdminNoticeMenu> {
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bound) {
      _bound = true;
      context.read<np.AdminNoticesProvider>().bind();
      context.read<pp.ProjectsProvider>().bind();
    }
  }

  String _ymdhm(dynamic ts) {
    DateTime? d;
    if (ts is Timestamp) d = ts.toDate();
    if (ts is DateTime) d = ts;
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$y/$m/$da $h:$mi'; // ← [] を削除
  }

  @override
  Widget build(BuildContext context) {
    final notices = context.watch<np.AdminNoticesProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('お知らせ一覧', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '新規作成',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminNoticeEditor()),
              );
            },
          ),
        ],
      ),
      body: notices.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('お知らせ一覧'),
                const _Underline(),
                const SizedBox(height: 6),

                // 背景カードなし。区切り線のみ。
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notices.notices.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (_, i) {
                    final n = notices.notices[i];
                    final id = (n['id'] ?? '').toString();
                    final title = (n['title'] ?? '').toString();
                    final dateText = _ymdhm(n['publishStart'] ?? n['createdAt']);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateText, style: const TextStyle(color: Colors.black87)),
                          Text('「$title」'),
                        ],
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
                                  builder: (_) => AdminNoticeEditor(initial: n),
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
                                  content: Text('「$title」を削除します。よろしいですか？'),
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
                                await context.read<np.AdminNoticesProvider>().delete(id);
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminNoticeEditor(initial: n),
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
