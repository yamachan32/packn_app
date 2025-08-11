import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:packn_app/providers/admin_notices_provider.dart' as np;
import 'package:packn_app/providers/projects_provider.dart' as pp;

class AdminNoticeEditor extends StatefulWidget {
  final Map<String, dynamic>? initial; // nullなら新規、非nullなら編集
  const AdminNoticeEditor({super.key, this.initial});

  @override
  State<AdminNoticeEditor> createState() => _AdminNoticeEditorState();
}

class _AdminNoticeEditorState extends State<AdminNoticeEditor> {
  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;
  late final TextEditingController urlCtrl;

  bool isGlobal = true;
  String? projectId;
  DateTime? startAt;
  DateTime? endAt;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.initial?['title'] ?? '');
    bodyCtrl  = TextEditingController(text: widget.initial?['body'] ?? '');
    urlCtrl   = TextEditingController(text: widget.initial?['url'] ?? '');

    final initIsGlobal =
        (widget.initial?['isGlobal'] == true) || (widget.initial?['projectId'] == null);
    isGlobal = initIsGlobal;
    projectId = initIsGlobal ? null : (widget.initial?['projectId'] as String?);

    final ps = widget.initial?['publishStart'];
    final pe = widget.initial?['publishEnd'];
    if (ps is DateTime) startAt = ps;
    if (ps is Timestamp) startAt = ps.toDate();
    if (pe is DateTime) endAt = pe;
    if (pe is Timestamp) endAt = pe.toDate();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    urlCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? base) async {
    final now = DateTime.now();
    final init = base ?? DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    final dt = DateTime(d.year, d.month, d.day, (t?.hour ?? 0), (t?.minute ?? 0));
    return dt;
  }

  String _fmtYmdHm(DateTime? d) {
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$y/$m/$da $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    // プロジェクト一覧（ドロップダウンに使用）
    context.read<pp.ProjectsProvider>().bind();
    final projects = context.watch<pp.ProjectsProvider>().projects;

    // ドロップダウンの items と value を整合させる（value が items に無ければ null にする）
    final List<DropdownMenuItem<String?>> items = [
      const DropdownMenuItem<String?>(value: null, child: Text('（全体周知）')),
      ...projects.map((p) {
        final id = (p['id'] ?? '').toString();
        final name = (p['name'] ?? '').toString();
        return DropdownMenuItem<String?>(value: id, child: Text(name));
      }),
    ];
    String? currentValue = isGlobal ? null : projectId;
    final values = items.map((e) => e.value).toSet();
    if (!values.contains(currentValue)) {
      currentValue = null;
      isGlobal = true;
      projectId = null;
    }

    final isEdit = widget.initial != null;
    final id = widget.initial?['id'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(isEdit ? 'お知らせ編集' : 'お知らせ編集',
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
                const _Label('プロジェクト'),
                const _Underline(),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  value: currentValue, // ← null を許容
                  items: items,
                  onChanged: (v) {
                    setState(() {
                      projectId = v;
                      isGlobal = v == null;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                const _Label('タイトル'),
                const _Underline(),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                const _Label('本文'),
                const _Underline(),
                const SizedBox(height: 6),
                TextField(
                  controller: bodyCtrl,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                const _Label('公開期間'),
                const _Underline(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final dt = await _pickDateTime(context, startAt);
                          if (dt != null) setState(() => startAt = dt);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child:
                          Text(_fmtYmdHm(startAt).isEmpty ? ' ' : _fmtYmdHm(startAt)),
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
                          final dt = await _pickDateTime(context, endAt);
                          if (dt != null) setState(() => endAt = dt);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: Text(_fmtYmdHm(endAt).isEmpty ? ' ' : _fmtYmdHm(endAt)),
                        ),
                      ),
                    ),
                  ],
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
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final body = bodyCtrl.text.trim();
                      final url = urlCtrl.text.trim(); // 値は保持（UI未表示）

                      if (title.isEmpty || body.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('タイトルと本文は必須です')),
                        );
                        return;
                      }

                      if (isEdit && id != null) {
                        await context.read<np.AdminNoticesProvider>().update(
                          id: id,
                          title: title,
                          body: body,
                          url: url.isEmpty ? null : url,
                          projectId: projectId,
                          isGlobal: isGlobal,
                          publishStart: startAt,
                          publishEnd: endAt,
                        );
                      } else {
                        await context.read<np.AdminNoticesProvider>().create(
                          title: title,
                          body: body,
                          url: url.isEmpty ? null : url,
                          projectId: projectId,
                          isGlobal: isGlobal,
                          publishStart: startAt,
                          publishEnd: endAt,
                        );
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
    return Text(
      text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    );
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
