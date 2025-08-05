import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddUserLinkScreen extends StatefulWidget {
  const AddUserLinkScreen({super.key});

  @override
  State<AddUserLinkScreen> createState() => _AddUserLinkScreenState();
}

class _AddUserLinkScreenState extends State<AddUserLinkScreen> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  Future<void> _saveLink() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('links')
        .add({
      'title': _titleController.text.trim(),
      'url': _urlController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ショートカット追加")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveLink,
              child: const Text("登録"),
            ),
          ],
        ),
      ),
    );
  }
}
