import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// お知らせ一覧と未読管理：
/// - ユーザーの assignedProjects 全件 + 'all' を購読（複数クエリをマージ）
/// - 既読更新 markAsRead を提供
class NoticeProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  String? _uid;
  final Set<String> _projectIds = {};
  Map<String, String> _projectNames = {};

  final Map<String, Map<String, dynamic>> _noticeMap = {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs = [];

  List<Map<String, dynamic>> get notices {
    final list = _noticeMap.values.toList();
    list.sort((a, b) {
      DateTime? da, db;
      final ta = a['createdAt'], tb = b['createdAt'];
      if (ta is Timestamp) {
        da = ta.toDate();
      } else if (ta is DateTime) {
        da = ta;
      }
      if (tb is Timestamp) {
        db = tb.toDate();
      } else if (tb is DateTime) {
        db = tb;
      }
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  int get unreadCount {
    final uid = _uid;
    if (uid == null) return 0;
    return _noticeMap.values.where((n) {
      final reads = (n['readUsers'] as List?)?.cast<String>() ?? const <String>[];
      return !reads.contains(uid);
    }).length;
  }

  /// タイトル接頭辞（[全体周知] or [PJ名]）
  String prefixFor(Map<String, dynamic> n) {
    final dynamic pidDyn = n['projectId'] ?? n['project'];
    if (pidDyn == null) return '';
    final pid = pidDyn.toString();
    if (pid == 'all') return '全体周知';
    return _projectNames[pid] ?? pid;
  }

  Future<void> bindForUser({
    required String uid,
    required List<String> projectIds,
    required Map<String, String> projectNames,
  }) async {
    final projects = List<String>.from(projectIds)..sort();
    final unchanged = _uid == uid &&
        _projectIds.length == projects.length &&
        _projectIds.containsAll(projects) &&
        _mapEquals(_projectNames, projectNames);

    if (unchanged && _subs.isNotEmpty) {
      return;
    }

    // 既存の購読を解除
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _noticeMap.clear();

    _uid = uid;
    _projectIds
      ..clear()
      ..addAll(projects);
    _projectNames = Map<String, String>.from(projectNames);

    _loading = true;
    notifyListeners();

    // 全体周知
    final allQuery = FirebaseFirestore.instance
        .collection('notices')
        .where('projectId', isEqualTo: 'all');
    _subs.add(allQuery.snapshots().listen(_applySnapshot, onError: (_) {
      _loading = false;
      notifyListeners();
    }));

    // 各プロジェクト（projectId / 互換: project）
    for (final pid in _projectIds) {
      final q1 = FirebaseFirestore.instance
          .collection('notices')
          .where('projectId', isEqualTo: pid);
      final qAlt = FirebaseFirestore.instance
          .collection('notices')
          .where('project', isEqualTo: pid);

      _subs.add(q1.snapshots().listen(_applySnapshot, onError: (_) {}));
      _subs.add(qAlt.snapshots().listen(_applySnapshot, onError: (_) {}));
    }
  }

  void _applySnapshot(QuerySnapshot<Map<String, dynamic>> qs) {
    for (final d in qs.docs) {
      final m = d.data();
      m['id'] = d.id;
      _noticeMap[d.id] = m;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String noticeId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('notices')
          .doc(noticeId)
          .update({'readUsers': FieldValue.arrayUnion([uid])});
      final m = _noticeMap[noticeId];
      if (m != null) {
        final list = (m['readUsers'] as List?)?.cast<String>().toList() ?? <String>[];
        if (!list.contains(uid)) list.add(uid);
        m['readUsers'] = list;
        notifyListeners();
      }
    } catch (_) {/* noop */}
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || b[k] != a[k]) return false;
    }
    return true;
  }
}
