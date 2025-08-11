import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// アカウント（users コレクション）管理用 Provider
/// users/{id}:
///  - email: string
///  - name: string
///  - role: "admin" | "user"
///  - createdAt: Timestamp
///  - updatedAt: Timestamp
class AccountsProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get accounts => List.unmodifiable(_items);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _bound = false;

  Future<void> bind() async {
    if (_bound) return;
    _bound = true;
    _loading = true;
    _error = null;
    notifyListeners();

    final col = FirebaseFirestore.instance
        .collection('users')
        .orderBy('email'); // 文字列ソート

    _sub = col.snapshots().listen((qs) {
      _items
        ..clear()
        ..addAll(qs.docs.map((d) => {'id': d.id, ...d.data()}));
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<String?> create({
    required String email,
    required String name,
    required String role, // "admin" or "user"
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final doc = await FirebaseFirestore.instance.collection('users').add({
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'createdAt': now,
        'updatedAt': now,
      });
      return doc.id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> update({
    required String id,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
