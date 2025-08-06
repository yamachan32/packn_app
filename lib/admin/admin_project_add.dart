import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_member_add.dart';
import 'admin_link_add.dart';

class AdminProjectAdd extends StatefulWidget {
  const AdminProjectAdd({super.key});

  @override
  State<AdminProjectAdd> createState() => _AdminProjectAddState();
}

class _AdminProjectAddState extends State<AdminProjectAdd> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  List<Map<String, dynamic>> _links = [];
  List<String> _members = [];

  Future<void> _openLinkModal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AdminLinkAdd(),
    );

    if (result != null) {
      setState(() {
        _links.add(result);
      });
    }
  }

  Future<void> _openMemberModal() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AdminMemberAdd(initialSelected: _members),
    );

    if (result != null) {
      setState(() {
        _members = result;
      });
    }
  }

  Future<void> _saveProject() async {
    final name = _nameController.text.trim();
    final start = _startDateController.text.trim();
    final end = _endDateController.text.trim();

    if (name.isEmpty || start.isEmpty || end.isEmpty) return;

    await FirebaseFirestore.instance.collection('projects').add({
      'name': name,
      'startDate': start,
      'endDate': end,
      'links': _links,
      'members': _members,
      'createdAt': Timestamp.now(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('プロジェクト追加', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('プロジェクト名'),
            TextField(controller: _nameController),
            const SizedBox(height: 16),
            const Text('期間'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: const InputDecoration(hintText: '開始日'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('~'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    decoration: const InputDecoration(hintText: '終了日'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('リンク', _openLinkModal),
            ..._links.map((link) => ListTile(
              leading: Image.asset('assets/icons/${link['icon']}', width: 32),
              title: Text(link['label'] ?? ''),
              subtitle: Text(link['url'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => _links.remove(link)),
              ),
            )),
            const SizedBox(height: 24),
            _sectionTitle('メンバー', _openMemberModal),
            ..._members.map((email) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(email),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() => _members.remove(email)),
              ),
            )),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                ),
                onPressed: _saveProject,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, VoidCallback onAdd) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey)),
        IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}
