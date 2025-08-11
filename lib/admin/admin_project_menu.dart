import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/projects_provider.dart';
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
      context.read<ProjectsProvider>().bind();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProjectsProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('プロジェクト管理', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: pp.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94, // 少し狭め
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // セクション見出し（＋）
                Row(
                  children: [
                    const _SectionTitle('プロジェクト一覧'),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminProjectEditor()),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'プロジェクトを追加',
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 背景パネル（高さは内容ぶんだけ）
                Container(
                  decoration: _panelDecoration(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pp.projects.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (_, i) {
                      final p = pp.projects[i];
                      final id = (p['id'] ?? '').toString();
                      final name = (p['name'] ?? '').toString();

                      return ListTile(
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
                                    builder: (_) =>
                                        AdminProjectEditor(projectId: id),
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
                                if (ok == true) {
                                  await context
                                      .read<ProjectsProvider>()
                                      .deleteProject(id);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminProjectEditor(projectId: id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static BoxDecoration _panelDecoration() => BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.grey.shade300),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(width: 80, height: 4, color: Colors.amber),
      ],
    );
  }
}
