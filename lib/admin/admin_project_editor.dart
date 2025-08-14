import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:packn_app/providers/projects_provider.dart' as pp;
import 'package:packn_app/providers/project_form_provider.dart' as pf;

import 'admin_link_add.dart';
import 'admin_member_add.dart';

class AdminProjectEditor extends StatelessWidget {
  final Map<String, dynamic>? initial; // nullなら新規
  const AdminProjectEditor({super.key, this.initial});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<pf.ProjectFormProvider>(
      create: (_) => initial == null
          ? pf.ProjectFormProvider.newProject(context.read<pp.ProjectsProvider>())
          : pf.ProjectFormProvider.edit(context.read<pp.ProjectsProvider>(), initial!),
      child: const _EditorBody(),
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody();

  Future<DateTime?> _pickDate(BuildContext context, DateTime? base) async {
    final now = DateTime.now();
    final init = base ?? DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<pf.ProjectFormProvider>();
    final isEdit = form.projectId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(
          form.nameCtrl.text.isEmpty
              ? (isEdit ? 'プロジェクト編集' : 'プロジェクト新規')
              : form.nameCtrl.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                // プロジェクト名
                const _Label('プロジェクト名'),
                const _Underline(),
                const SizedBox(height: 6),
                TextField(
                  controller: form.nameCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),

                const SizedBox(height: 18),

                // 期間
                const _Label('期間'),
                const _Underline(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final dt = await _pickDate(context, form.startAt);
                          if (dt != null) form.setStart(dt);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: Text(_fmtYmd(form.startAt)),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('~'),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final dt = await _pickDate(context, form.endAt);
                          if (dt != null) form.setEnd(dt);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: Text(_fmtYmd(form.endAt)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // リンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Label('リンク'),
                    IconButton(
                      tooltip: 'リンクを追加',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        final result = await showDialog<Map<String, String>>(
                          context: context,
                          builder: (_) => const AdminLinkAdd(),
                        );
                        if (result != null) {
                          form.addLink(result);
                        }
                      },
                    ),
                  ],
                ),
                const _Underline(),
                const SizedBox(height: 6),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: form.links.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (_, i) {
                    final row = form.links[i];
                    final icon = (row['icon'] ?? '').toString();
                    final label = (row['label'] ?? '').toString();
                    final url = (row['url'] ?? '').toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: icon.isNotEmpty
                          ? Image.asset(
                        'assets/icons/$icon',
                        width: 36,
                        height: 36,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.link, size: 36),
                      )
                          : const Icon(Icons.link, size: 36),
                      title: Text(label),
                      subtitle: Text(url),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ←← 修正ポイント：initial を渡して編集モードで開く
                          IconButton(
                            tooltip: '編集',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              final result = await showDialog<Map<String, String>>(
                                context: context,
                                builder: (_) => AdminLinkAdd(
                                  initial: {
                                    'label': label,
                                    'url': url,
                                    'icon': icon,
                                  },
                                ),
                              );
                              if (!context.mounted) return;
                              if (result != null) form.replaceLink(i, result);
                            },
                          ),
                          IconButton(
                            tooltip: '削除',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => form.removeLinkRow(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // メンバー
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Label('メンバー'),
                    IconButton(
                      tooltip: 'メンバーを追加',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        final selected = await showDialog<List<String>>(
                          context: context,
                          builder: (_) =>
                              AdminMemberAdd(initialSelected: form.members),
                        );
                        if (!context.mounted) return;
                        if (selected != null) form.setMembers(selected);
                      },
                    ),
                  ],
                ),
                const _Underline(),
                const SizedBox(height: 6),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: form.members.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade300),
                  itemBuilder: (_, i) {
                    final email = form.members[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: const Icon(Icons.person_outline),
                      title: Text(email),
                      trailing: IconButton(
                        tooltip: '削除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => form.removeMemberAt(i),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 保存
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
                    onPressed: form.saving
                        ? null
                        : () async {
                      final ok = await form.save();
                      if (!context.mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存に失敗しました')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                    },
                    child: Text(form.saving ? '保存中...' : '保存'),
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

  String _fmtYmd(DateTime? d) {
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y/$m/$da';
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
