import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccountEdit extends StatefulWidget {
  final String uid;
  final String currentName;
  final String currentRole;

  const AdminAccountEdit({
    super.key,
    required this.uid,
    required this.currentName,
    required this.currentRole,
  });

  @override
  State<AdminAccountEdit> createState() => _AdminAccountEditState();
}

class _AdminAccountEditState extends State<AdminAccountEdit> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: '●●●●●●');
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _emailController.text = data['email'] ?? '';
        _nameController.text = data['name'] ?? '';
        _selectedRole = data['role'] ?? 'user';
      });
    }
  }

  Future<void> _updateUser() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'role': _selectedRole,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    }
  }

  Widget _buildLabeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(width: 40, height: 2, color: Colors.amber),
          ],
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント編集'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildLabeledField(
              'ユーザID（メールアドレス）',
              _buildTextField(
                controller: _emailController,
                hint: 'example@example.com',
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
            ),
            _buildLabeledField(
              '氏名',
              _buildTextField(controller: _nameController, hint: '氏名を入力'),
            ),
            _buildLabeledField(
              'パスワード',
              _buildTextField(
                controller: _passwordController,
                hint: '●●●●●●',
                obscure: true,
                enabled: false,
              ),
            ),
            _buildLabeledField(
              '権限',
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('管理者')),
                  DropdownMenuItem(value: 'user', child: Text('ユーザ')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _updateUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
                child: const Text('更新', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
