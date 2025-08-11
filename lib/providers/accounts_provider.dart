import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// アカウント管理用 Provider
class AccountsProvider extends ChangeNotifier {
  final _fs = FirebaseFirestore.instance;

  /// 一覧（メニュー側で使う場合はそのまま StreamBuilder に食わせてOK）
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAccounts() {
    return _fs.collection('users').orderBy('email').snapshots();
  }

  /// 単体読み込み（編集フォーム初期値など）
  Future<Map<String, dynamic>?> fetchByUid(String uid) async {
    final doc = await _fs.collection('users').doc(uid).get();
    return doc.data();
  }

  /// 新規作成：Auth（REST: signUp）→ users コレクション作成
  Future<String> createAccount({
    required String email,
    required String displayName,
    required String initialPassword,
    required String role, // 'admin' | 'user'
  }) async {
    // ★ APIキーをコードに直書きせず、現在のアプリ設定から取得
    final apiKey = Firebase.app().options.apiKey;
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    // --- Authユーザー作成（RESTなので現在の管理者セッションは維持される）
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': initialPassword,
        'returnSecureToken': true,
      }),
    );

    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      final code = (body['error']?['message'] ?? 'UNKNOWN').toString();
      throw Exception('Auth作成に失敗しました：$code');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final uid = data['localId'] as String;

    // --- Firestore にユーザ情報を作成
    await _fs.collection('users').doc(uid).set({
      'email': email,
      'name': displayName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
    return uid;
  }

  /// 更新：Firestore のみ（メール/パスワードは編集不可）
  Future<void> updateAccount({
    required String uid,
    required String displayName,
    required String role,
  }) async {
    await _fs.collection('users').doc(uid).update({
      'name': displayName,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  /// 削除（必要なら）
  Future<void> deleteAccount(String uid) async {
    await _fs.collection('users').doc(uid).delete();
    notifyListeners();
  }
}
