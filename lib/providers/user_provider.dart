import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 認証ユーザーと、そのユーザーに関連する基本データを保持。
/// アプリ起動時に authStateChanges を購読し、ログイン／ログアウトを一元管理。
class UserProvider extends ChangeNotifier {
  String? uid;
  String? email;
  String? role;
  List<String> assignedProjects = [];
  Map<String, String> projectNames = {};
  bool isLoading = true;

  StreamSubscription<User?>? _authSub;

  UserProvider() {
    // 起動時にAuthを購読：ログイン/ログアウト時の再読込を一本化
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (u == null) {
        _clear();
        notifyListeners();
        return;
      }
      await loadUserData(); // ログイン直後に1回だけ
    });
  }

  Future<void> loadUserData() async {
    isLoading = true;
    notifyListeners();
    try {
      final fb = FirebaseAuth.instance.currentUser;
      if (fb == null) {
        _clear();
        return;
      }

      uid = fb.uid;
      email = fb.email;

      // users/{uid}
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      role = userDoc.data()?['role'] ?? 'user';

      // 将来的には membersUid(arrayContains: uid) に移行推奨。
      final q = await FirebaseFirestore.instance
          .collection('projects')
          .where('members', arrayContains: email)
          .get();

      assignedProjects = q.docs.map((d) => d.id).toList();
      projectNames = {
        for (final d in q.docs) d.id: (d.data()['name'] ?? d.id).toString()
      };
    } catch (_) {
      _clear();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? getProjectName(String id) => projectNames[id];

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _clear();
    notifyListeners();
  }

  void _clear() {
    uid = null;
    email = null;
    role = null;
    assignedProjects = [];
    projectNames = {};
    isLoading = false;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
