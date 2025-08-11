import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ← 相対パスではなく package: で統一し、両方にプレフィックスを付与
import 'package:packn_app/providers/projects_provider.dart' as pp;
import 'package:packn_app/providers/project_form_provider.dart' as pf;

import 'admin_member_add.dart';
import 'admin_link_add.dart';

/// プロジェクトの新規/編集を1画面で扱う共通エディタ。
class AdminProjectEditor extends StatefulWidget {
  final String? projectId;
  const AdminProjectEditor({super.key, this.projectId});

  @override
  State<AdminProjectEditor> createState() => _AdminProjectEditorState();
}

class _AdminProjectEditorState extends State<AdminProjectEditor> {
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
    final projects = context.watch<pp.ProjectsProvider>();
    final isEdit = widget.projectId != null;

    if (isEdit) {
      final p = projects.getById(widget.projectId!);
      if (p == null) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.amber,
            title: const Text('プロジェクト編集', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return ChangeNotifierProvider<pf.ProjectFormProvider>(
        create: (_) => pf.ProjectFormProvider.edit(projects, p),
        child: _EditorBody(isEdit: true, projectId: widget.projectId!),
      );
    }

    return ChangeNotifierProvider<pf.ProjectFormProvider>(
      create: (_) => pf.ProjectFormProvider.newProject(projects),
      child: const _EditorBody(isEdit: false),
    );
  }
}

class _EditorBody extends StatelessWidget {
  final bool isEdit;
  final String? projectId;
  const _EditorBody({required this.isEdit, this.projectId});

  @override
  Widget build(BuildContext context) {
    final form = context.watch<pf.ProjectFormProvider>();
    final projects = context.read<pp.ProjectsProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(isEdit ? 'プロジェクト編集' : 'プロジェクト新規',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (isEdit && projectId != null)
            IconButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('削除確認'),
                    content: const Text('このプロジェクトを削除しますか？\n※元に戻せません'),
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
                if (ok == true) {
                  await projects.deleteProject(projectId!);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: '削除',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ===== プロジェクト名 =====
          const _SectionTitle('プロジェクト名'),
          const SizedBox(height: 6),
          Container(
            decoration: _panelDecoration(),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: form.nameCtrl,
              decoration: const InputDecoration(
                hintText: '例: FD課アプリ開発',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== 期間 =====
          const _SectionTitle('期間'),
          const SizedBox(height: 6),
          Container(
            decoration: _panelDecoration(),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: '開始',
                    date: form.startAt,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: form.startAt ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) form.setStart(picked);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('~'),
                ),
                Expanded(
                  child: _DateBox(
                    label: '終了',
                    date: form.endAt,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: form.endAt ?? (form.startAt ?? DateTime.now()),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) form.setEnd(picked);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== リンク =====
          Row(
            children: [
              const _SectionTitle('リンク'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'リンクを追加',
                onPressed: () async {
                  final result = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (_) => const AdminLinkAdd(),
                  );
                  if (result != null) form.addLink(result);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: _panelDecoration(),
            child: Column(
              children: [
                for (int i = 0; i < form.links.length; i++) ...[
                  _LinkRow(
                    iconName: form.links[i]['icon'] ?? '',
                    label: form.links[i]['label'] ?? '',
                    url: form.links[i]['url'] ?? '',
                    onEdit: () async {
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (_) => AdminLinkAdd(initial: {
                          'icon': form.links[i]['icon'] ?? '',
                          'label': form.links[i]['label'] ?? '',
                          'url': form.links[i]['url'] ?? '',
                        }),
                      );
                      if (result != null) form.replaceLink(i, result);
                    },
                    onDelete: () => form.removeLinkRow(i),
                  ),
                  if (i != form.links.length - 1)
                    Divider(height: 1, color: Colors.grey.shade300),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== メンバー =====
          Row(
            children: [
              const _SectionTitle('メンバ'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'メンバーを追加',
                onPressed: () async {
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (_) => AdminMemberAdd(initialSelected: form.members),
                  );
                  if (result != null) form.setMembers(result);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: _panelDecoration(),
            child: Column(
              children: [
                if (form.members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('メンバーが登録されていません'),
                  ),
                for (int i = 0; i < form.members.length; i++) ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(form.members[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '削除',
                      onPressed: () => form.removeMemberAt(i),
                    ),
                  ),
                  if (i != form.members.length - 1)
                    Divider(height: 1, color: Colors.grey.shade300),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===== 保存 =====
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: form.saving
                  ? null
                  : () async {
                final ok = await form.save();
                if (!context.mounted) return;
                if (ok) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('保存に失敗しました')),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ),
          if (form.saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
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

// ====== parts ======

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

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateBox({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? ''
        : '${date!.year.toString().padLeft(4, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(text.isEmpty ? '—' : text),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String iconName;
  final String label;
  final String url;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LinkRow({
    required this.iconName,
    required this.label,
    required this.url,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: iconName.isNotEmpty
          ? Image.asset('assets/icons/$iconName', width: 32, height: 32)
          : const Icon(Icons.link),
      title: Text(label.isEmpty ? '(no label)' : label),
      subtitle: Text(url),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}
