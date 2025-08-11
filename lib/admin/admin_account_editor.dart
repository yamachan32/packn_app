import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/accounts_provider.dart';

class AdminAccountEditor extends StatefulWidget {
  /// uid が null のときは新規作成モード
  final String? uid;

  const AdminAccountEditor({super.key, this.uid});

  @override
  State<AdminAccountEditor> createState() => _AdminAccountEditorState();
}

class _AdminAccountEditorState extends State<AdminAccountEditor> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _initialPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String _role = 'user'; // 'user' | 'admin'

  bool get isEdit => widget.uid != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _load();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _initialPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final data = await context.read<AccountsProvider>().fetchByUid(widget.uid!);
      if (data != null) {
        _email.text = (data['email'] ?? '').toString();
        _name.text = (data['name'] ?? '').toString();
        _role = (data['role'] ?? 'user').toString();
      }
    } catch (e) {
      _toast('読み込みに失敗しました：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final ap = context.read<AccountsProvider>();

      if (isEdit) {
        await ap.updateAccount(
          uid: widget.uid!,
          displayName: _name.text.trim(),
          role: _role,
        );
        _toast('更新しました');
      } else {
        final uid = await ap.createAccount(
          email: _email.text.trim(),
          displayName: _name.text.trim(),
          initialPassword: _initialPassword.text,
          role: _role,
        );
        _toast('作成しました（uid: $uid）');
      }

      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _toast('保存に失敗しました：${e.message}');
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

  // 無効（非活性）時に薄いグレーで塗るデコレーション
  InputDecoration _decoration({bool disabled = false}) {
    final grey = Colors.grey.shade200;
    final borderColor = Colors.grey.shade400;
    return InputDecoration(
      isDense: false,
      filled: disabled,
      fillColor: disabled ? grey : null,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Colors.amber;
    const labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定'),
        backgroundColor: yellow,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- ユーザID（メール）
                  _label('ユーザID（メールアドレス）', yellow, labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _email,
                    enabled: !isEdit, // ★ 編集時は無効化（グレー表示）
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(disabled: isEdit),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'メールアドレスを入力してください';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s)) {
                        return 'メールアドレスの形式が正しくありません';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- 氏名
                  _label('氏名', yellow, labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _name,
                    decoration: _decoration(),
                    validator: (v) =>
                    (v ?? '').trim().isEmpty ? '氏名を入力してください' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- 初期パスワード（新規のみ） / 編集時は表示のみ
                  if (!isEdit) ...[
                    _label('初期パスワード', yellow, labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _initialPassword,
                      obscureText: true,
                      decoration: _decoration(),
                      validator: (v) {
                        final s = v ?? '';
                        if (s.isEmpty) return '初期パスワードを入力してください';
                        if (s.length < 8) return '8文字以上で入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    _label('パスワード', yellow, labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      enabled: false, // ★ 編集時は非活性（グレー表示）
                      obscureText: true,
                      initialValue: '********',
                      decoration: _decoration(disabled: true),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- 権限（ドロップダウン）
                  _label('権限', yellow, labelStyle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _role,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('ユーザ')),
                      DropdownMenuItem(value: 'admin', child: Text('管理者')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'user'),
                    decoration: _decoration(),
                  ),

                  const SizedBox(height: 28),

                  // --- 保存ボタン
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),

            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color accent, TextStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: style),
        const SizedBox(height: 4),
        Container(height: 3, width: 60, color: accent),
      ],
    );
  }
}
