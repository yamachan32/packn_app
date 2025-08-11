import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:packn_app/providers/projects_provider.dart' as pp;
import 'admin_project_editor.dart';

class AdminProjectMenu extends StatefulWidget {
  const AdminProjectMenu({super.key});

  @override
  State<AdminProjectMenu> createState() => _AdminProjectMenuState();
}

class _AdminProjectMenuState extends State<AdminProjectMenu> {
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bound) {
      _bound = true;
      context.read<pp.ProjectsProvider>().bind();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<pp.ProjectsProvider>();
    final projects = provider.projects;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('プロジェクト管理', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '新規作成',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProjectEditor()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('プロジェクト一覧'),
                const _Underline(),
                const SizedBox(height: 6),

                // ★ 背景カードなし。区切り線のみ。
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (_, i) {
                    final p = projects[i];
                    final id = (p['id'] ?? '').toString();
                    final name = (p['name'] ?? '').toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      title: Text(name),
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
                                  builder: (_) => AdminProjectEditor(initial: p),
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
                                  content: Text('「$name」を削除します。よろしいですか？'),
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
                                await context.read<pp.ProjectsProvider>().deleteProject(id);
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminProjectEditor(initial: p),
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
