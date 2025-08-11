import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String? uid;
  String? email;
  String? role; // 'admin' | 'user' | null
  List<String> assignedProjects = [];
  Map<String, String> projectNames = {}; // projectId -> projectName
  bool isLoading = true;

  /// サインイン済みユーザーの基本情報 + 参加プロジェクトを読み込み
  Future<void> loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // 未ログインでもハングしないように初期化
      uid = null;
      email = null;
      role = null;
      assignedProjects = [];
      projectNames = {};
      isLoading = false;
      notifyListeners();
      return;
    }

    uid = currentUser.uid;
    email = currentUser.email;

    try {
      // users/{uid}
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        role = null;
        assignedProjects = [];
        projectNames = {};
      } else {
        final data = userDoc.data();
        role = (data?['role'] ?? 'user').toString();

        // メンバーとして含まれるprojectsを取得（members に email が含まれる）
        final q = await FirebaseFirestore.instance
            .collection('projects')
            .where('members', arrayContains: email)
            .get();

        assignedProjects = q.docs.map((d) => d.id).toList();

        // projectId -> name のマップ
        projectNames = {
          for (final d in q.docs) d.id: (d.data()['name'] ?? d.id).toString(),
        };
      }
    } catch (e) {
      // 失敗時は空で返す
      role = null;
      assignedProjects = [];
      projectNames = {};
    }

    isLoading = false;
    notifyListeners();
  }

  /// プロジェクトIDからプロジェクト名
  String? getProjectName(String projectId) => projectNames[projectId];

  /// プロバイダの状態を破棄（ログアウト時に呼ぶ）
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
