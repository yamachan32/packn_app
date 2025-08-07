import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String? uid;
  String? email;
  String? role;
  List<String> assignedProjects = [];
  bool isLoading = true;

  /// ✅ userId getter を追加
  String? get userId => uid;

  /// ✅ role getter（null安全対策済み）
  String get safeRole => role ?? 'user';

  Future<void> loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    uid = currentUser.uid;
    email = currentUser.email;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        role = null;
        assignedProjects = [];
      } else {
        final data = userDoc.data();
        role = data?['role'] ?? 'user';

        // メンバーに含まれるプロジェクトID取得
        final query = await FirebaseFirestore.instance
            .collection('projects')
            .where('members', arrayContains: email)
            .get();

        assignedProjects = query.docs.map((doc) => doc.id).toList();
      }
    } catch (e) {
      role = null;
      assignedProjects = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void logout() {
    uid = null;
    email = null;
    role = null;
    assignedProjects = [];
    isLoading = false;
    notifyListeners();
  }
}
