import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNoticeAdd extends StatefulWidget {
  final DocumentSnapshot? existingNotice;

  const AdminNoticeAdd({super.key, this.existingNotice});

  @override
  State<AdminNoticeAdd> createState() => _AdminNoticeAddState();
}

class _AdminNoticeAddState extends State<AdminNoticeAdd> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _selectedProjectId;

  List<Map<String, String>> _projectOptions = [];

  @override
  void initState() {
    super.initState();
    _loadProjectOptions();
    _initFieldsIfEditing();
  }

  void _initFieldsIfEditing() {
    final notice = widget.existingNotice;
    if (notice != null) {
      final data = notice.data() as Map<String, dynamic>;
      _titleController.text = data['title'] ?? '';
      _bodyController.text = data['body'] ?? '';
      _selectedProjectId = data['projectId'] ?? 'all';
    }
  }

  Future<void> _loadProjectOptions() async {
    List<Map<String, String>> options = [
      {'id': 'all', 'name': '全体周知'}
    ];

    final projectSnapshot = await FirebaseFirestore.instance.collection('projects').get();
    for (var doc in projectSnapshot.docs) {
      final data = doc.data();
      options.add({
        'id': doc.id,
        'name': data['name']?.toString() ?? '未設定',
      });
    }

    setState(() {
      _projectOptions = options;

      // 編集時に projectId が設定されていれば使用
      if (_selectedProjectId == null) {
        _selectedProjectId = 'all';
      }
    });
  }

  Future<void> _saveNotice() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty || _selectedProjectId == null) return;

    final data = {
      'title': title,
      'body': body,
      'projectId': _selectedProjectId,
      'createdAt': Timestamp.now(),
    };

    if (widget.existingNotice != null) {
      // 編集処理
      await FirebaseFirestore.instance
          .collection('notices')
          .doc(widget.existingNotice!.id)
          .update(data);
    } else {
      // 新規追加
      await FirebaseFirestore.instance.collection('notices').add(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingNotice != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'お知らせ編集' : 'お知らせ作成',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('プロジェクト', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              items: _projectOptions
                  .map((project) => DropdownMenuItem(
                value: project['id'],
                child: Text(project['name']!),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('タイトル', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('本文', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _bodyController,
                maxLines: 15,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: '本文',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _saveNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                ),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
