import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      _toast('メールアドレスとパスワードを入力してください');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      if (cred.user != null && mounted) {
        await context.read<UserProvider>().loadUserData();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(_toMessage(e));
    } catch (_) {
      if (!mounted) return;
      _toast('ログインに失敗しました。しばらくしてからお試しください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _toMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'user-disabled':
        return 'このアカウントは無効化されています。';
      case 'user-not-found':
        return '該当するユーザが見つかりません。';
      case 'wrong-password':
        return 'パスワードが違います。';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらくしてからお試しください。';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました。接続をご確認ください。';
      default:
        return 'ログインに失敗しました（${e.code}）。';
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ヘルプ'),
        content: const Text(
          'パスワードをお忘れの場合は、登録しているメールアドレスに再設定リンクを送信できます。\n'
              'ログインできない場合は管理者にお問い合わせください。',
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ★ ロゴ：assets/images/logo.jpg に変更
                Image.asset(
                  'assets/images/logo.jpg',
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      tooltip: _obscure ? '表示' : '非表示',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('ログイン'),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed:
                      _isLoading ? null : () => Navigator.pushNamed(context, '/password_forget'),
                      child: const Text('パスワードを忘れた方はこちら'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _isLoading ? null : _showHelp,
                      icon: const Icon(Icons.help_outline),
                      tooltip: 'ヘルプ',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
