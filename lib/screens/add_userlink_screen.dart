import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/selected_project_provider.dart';

class AddUserLinkScreen extends StatefulWidget {
  final String? projectId;           // 明示指定されれば優先
  final String? docId;               // 編集時のドキュメントID
  final Map<String, dynamic>? initial;

  const AddUserLinkScreen({
    super.key,
    this.projectId,
    this.docId,
    this.initial,
  });

  @override
  State<AddUserLinkScreen> createState() => _AddUserLinkScreenState();
}

class _AddUserLinkScreenState extends State<AddUserLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _title = TextEditingController();
  String? _icon; // 'Icon_xxx.png'
  bool _saving = false;

  bool get isEdit => widget.docId != null;

  static const _icons = <String>[
    'Icon_Backlog.png',
    'Icon_E.png',
    'Icon_Figma.png',
    'Icon_Folder.png',
    'Icon_GoogleCalendar.png',
    'Icon_GoogleChrome.png',
    'Icon_Link.png',
    'Icon_P.png',
    'Icon_PDF.png',
    'Icon_Slack.png',
    'Icon_txt.png',
    'Icon_Wicon.png',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final m = widget.initial!;
      _url.text = (m['url'] ?? '').toString();
      _title.text = (m['title'] ?? '').toString();
      final ic = (m['icon'] ?? '').toString();
      _icon = ic.isEmpty ? null : ic;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  void _showHelp(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ヘルプ'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = context.read<UserProvider>().uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン情報がありません')),
      );
      return;
    }

    // projectId は任意。指定順：引数 > initial > Provider。無ければ null のまま保存
    final pid = widget.projectId ??
        widget.initial?['projectId']?.toString() ??
        context.read<SelectedProjectProvider>().id;

    if (_icon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイコンを選択してください')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'url': _url.text.trim(),
      'icon': _icon,
      if (pid != null) 'projectId': pid,  // 任意
      'updatedAt': FieldValue.serverTimestamp(),
    };

    setState(() => _saving = true);
    try {
      final linksCol =
      FirebaseFirestore.instance.collection('users').doc(uid).collection('links');

      if (isEdit) {
        await linksCol.doc(widget.docId).update(payload);
      } else {
        await linksCol.add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      // 失敗理由をそのまま表示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- View components ----
  Widget _requiredChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.orange.shade200,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text('必須', style: TextStyle(fontSize: 12)),
  );

  Widget _labelRow(String label, {VoidCallback? onHelp}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        _requiredChip(),
        if (onHelp != null) ...[
          const SizedBox(width: 6),
          GestureDetector(onTap: onHelp, child: const Icon(Icons.help_outline, size: 18)),
        ],
      ],
    );
  }

  Widget _iconButton(String fileName) {
    final selected = _icon == fileName;
    return GestureDetector(
      onTap: () => setState(() => _icon = fileName),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Image.asset('assets/icons/$fileName', width: 28, height: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = isEdit ? 'ショートカット編集' : 'ショートカット設定';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(appBarTitle),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // URL
              _labelRow('URL', onHelp: () => _showHelp('ショートカット先のURLを入力してください。')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                // ★ hasScheme & hasAuthority の緩め判定
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'URLは必須です';
                  final u = Uri.tryParse(t);
                  if (u == null || (!u.hasScheme || !u.hasAuthority)) {
                    return 'URLの形式が不正です（https://～ など）';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ショートカット名
              _labelRow('ショートカット名', onHelp: () => _showHelp('表示される名前を入力してください。')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  hintText: '例: Notion',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'ショートカット名は必須です' : null,
              ),

              const SizedBox(height: 16),

              // アイコン選択
              _labelRow('アイコン選択', onHelp: () => _showHelp('使用するアイコンを選んでください。')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map(_iconButton).toList(),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _saving ? null : _submit,
                  child: Text(isEdit ? '更新' : '設定',
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
