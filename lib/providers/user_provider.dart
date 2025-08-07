import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String? uid;
  String? email;
  String? role;
  List<String> assignedProjects = [];
  Map<String, String> projectNames = {};
  bool isLoading = true;

  Future<void> loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    uid = currentUser.uid;
    email = currentUser.email;

    try {
      // ユーザー情報を取得
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

        // メンバーとして含まれるプロジェクトを取得
        final query = await FirebaseFirestore.instance
            .collection('projects')
            .where('members', arrayContains: email)
            .get();

        assignedProjects = query.docs.map((doc) => doc.id).toList();

        // プロジェクトIDからプロジェクト名のマップを作成
        projectNames = {
          for (var doc in query.docs)
            doc.id: doc.data()['name'] ?? doc.id,
        };
      }
    } catch (e) {
      role = null;
      assignedProjects = [];
      projectNames = {};
    }

    isLoading = false;
    notifyListeners();
  }

  /// プロジェクトIDからプロジェクト名を取得
  String? getProjectName(String projectId) {
    return projectNames[projectId];
  }

  void logout() {
    uid = null;
    email = null;
    role = null;
    assignedProjects = [];
    projectNames = {};
    isLoading = false;
    notifyListeners();
  }
}
