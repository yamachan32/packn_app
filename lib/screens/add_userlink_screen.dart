import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUserLinkScreen extends StatefulWidget {
  final String projectId;

  const AddUserLinkScreen({super.key, required this.projectId});

  @override
  State<AddUserLinkScreen> createState() => _AddUserLinkScreenState();
}

class _AddUserLinkScreenState extends State<AddUserLinkScreen> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final title = _titleController.text.trim();
    final url = _urlController.text.trim();

    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルとURLを入力してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('links')
          .add({
        'title': title,
        'url': url,
        'projectId': widget.projectId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登録に失敗しました')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ショートカット追加のヘルプ'),
        content: const Text(
          'この画面では、タイトルとURLを入力して\n'
              'プロジェクトごとのショートカットを登録できます。\n\n'
              '登録後はホーム画面に追加されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ショートカット追加'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveLink,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
