import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordForgetScreen extends StatefulWidget {
  const PasswordForgetScreen({super.key});

  @override
  State<PasswordForgetScreen> createState() => _PasswordForgetScreenState();
}

class _PasswordForgetScreenState extends State<PasswordForgetScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _toast('メールアドレスを入力してください');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('再設定メールを送信しました。メールをご確認ください。');
    } on FirebaseAuthException catch (e) {
      _toast(_toMessage(e));
    } catch (_) {
      _toast('送信に失敗しました。しばらくしてからお試しください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _toMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'user-not-found':
        return '該当するユーザが見つかりません。';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました。接続をご確認ください。';
      default:
        return '送信に失敗しました（${e.code}）。';
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey.shade300;
    final labelBar = Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワード再設定'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.92,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepText(1, 'メールアドレスを入力してください。'),
                const SizedBox(height: 6),
                _stepText(2, 'メールを受信後に開き、メール内のリンクからパスワード再設定の案内に従います。'),
                const SizedBox(height: 6),
                _stepText(3, '再設定が完了したら新しいパスワードでログインしてください。'),
                const SizedBox(height: 16),

                // 入力ブロック（外枠 + ラベル帯 + テキストフィールド）
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      // ラベル帯
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: labelBar,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          border: Border(bottom: BorderSide(color: grey)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'メールアドレス',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                '必須',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 入力欄
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 送信ボタン（中央寄せ・青）
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _busy
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('メールを送信'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepText(int n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$n．', style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
