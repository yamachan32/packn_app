import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUserLinkScreen extends StatefulWidget {
  final String? projectId;      // ← 受け取り（必須想定）
  final String? projectName;    // 表示用（任意）

  const AddUserLinkScreen({super.key, this.projectId, this.projectName});

  @override
  State<AddUserLinkScreen> createState() => _AddUserLinkScreenState();
}

class _AddUserLinkScreenState extends State<AddUserLinkScreen> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  String? _selectedIcon;
  bool _busy = false;

  // assets/icons のアイコン候補（必要に応じて拡張）
  final List<String> _iconList = const [
    'Icon_GoogleChrome.png',
    'Icon_GoogleCalendar.png',
    'Icon_Backlog.png',
    'Icon_Slack.png',
    'Icon_Figma.png',
    'Icon_Wicon.png',
    'Icon_E.png',
    'Icon_P.png',
    'Icon_PDF.png',
    'Icon_txt.png',
    'Icon_Folder.png',
    'Icon_Link.png',
  ];

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final pid = widget.projectId;

    if (uid == null) {
      _toast('ログインが必要です');
      return;
    }
    if (pid == null || pid.isEmpty) {
      _toast('プロジェクトが特定できませんでした');
      return;
    }
    if (_title.text.trim().isEmpty || _url.text.trim().isEmpty || _selectedIcon == null) {
      _toast('タイトル、URL、アイコンを入力してください');
      return;
    }

    setState(() => _busy = true);
    try {
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('projects')
          .doc(pid)
          .collection('links');

      await col.add({
        'title': _title.text.trim(),
        'url': _url.text.trim(),
        'icon': _selectedIcon,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _toast('保存に失敗しました：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.projectId;
    final pName = widget.projectName ?? widget.projectId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('+ AddApps（$pName）'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pid == null || pid.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('プロジェクトIDがありません。ホームから開き直してください。',
                        style: TextStyle(color: Colors.red)),
                  ),

                const Text('リンク名', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                const Text('URL', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                const Text('アイコン選択', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconList.map((fileName) {
                    final isSelected = _selectedIcon == fileName;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = fileName),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: isSelected ? Colors.amber : Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/icons/$fileName',
                          width: 48,
                          height: 48,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _busy
                        ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('登録する'),
                  ),
                ),
              ],
            ),

            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x22FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
