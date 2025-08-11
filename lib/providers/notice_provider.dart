import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザ向けお知らせ Provider
/// - notices（全件を購読してクライアント側で絞り込み）
/// - users/{uid}/noticeReads を購読して既読管理
/// - unreadCount を公開
///
/// notices/{id}
///  - title, body, url?
///  - projectId: string?  // null/空 => 全体周知
///  - isGlobal: bool      // true => 全体周知
///  - publishStart: Timestamp?
///  - publishEnd: Timestamp?
///  - createdAt: Timestamp
class NoticeProvider extends ChangeNotifier {
  String? _uid;
  List<String> _assigned = [];

  bool _binding = false;
  bool get isBinding => _binding;

  final List<Map<String, dynamic>> _all = [];
  final Set<String> _readIds = {};

  List<Map<String, dynamic>> get allNotices => List.unmodifiable(_all);
  Set<String> get readIds => Set.unmodifiable(_readIds);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subNotices;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subReads;

  /// Auth 後に呼び出す。複数回呼ばれても同一条件なら再購読しない。
  Future<void> bind({
    required String uid,
    required List<String> assignedProjectIds,
  }) async {
    // 変更なしなら何もしない
    if (_uid == uid &&
        _assigned.length == assignedProjectIds.length &&
        _assigned.toSet().containsAll(assignedProjectIds)) {
      return;
    }

    // 既存サブスクリプションを止める
    await _subNotices?.cancel();
    await _subReads?.cancel();

    _uid = uid;
    _assigned = List<String>.from(assignedProjectIds);
    _binding = true;
    notifyListeners();

    // notices は createdAt 降順のみで購読（複合インデックス回避）
    _subNotices = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((qs) {
      _all
        ..clear()
        ..addAll(qs.docs.map((d) => {'id': d.id, ...d.data()}));
      _binding = false;
      notifyListeners();
    }, onError: (_) {
      _binding = false;
      notifyListeners();
    });

    // 既読
    _subReads = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('noticeReads')
        .snapshots()
        .listen((qs) {
      _readIds
        ..clear()
        ..addAll(qs.docs.map((d) => d.id));
      notifyListeners();
    });
  }

  /// 表示対象（全体周知 + 自分がアサインされているPJ、公開期間内）
  List<Map<String, dynamic>> get visibleNotices {
    final now = DateTime.now();

    bool _within(dynamic start, dynamic end) {
      DateTime? s;
      DateTime? e;
      if (start is Timestamp) s = start.toDate();
      if (start is DateTime) s = start;
      if (end is Timestamp) e = end.toDate();
      if (end is DateTime) e = end;
      if (s != null && now.isBefore(s)) return false;
      if (e != null && now.isAfter(e)) return false;
      return true;
    }

    return _all.where((n) {
      final isGlobal = (n['isGlobal'] == true) ||
          n['projectId'] == null ||
          (n['projectId'] as String? ?? '').isEmpty;
      final pid = (n['projectId'] ?? '').toString();
      if (!_within(n['publishStart'], n['publishEnd'])) return false;
      if (isGlobal) return true;
      return _assigned.contains(pid);
    }).toList();
  }

  /// 未読件数
  int get unreadCount =>
      visibleNotices.where((n) => !_readIds.contains(n['id'])).length;

  /// 既読化（一覧/詳細で呼ぶ）
  Future<void> markAsRead(String noticeId) async {
    final uid = _uid;
    if (uid == null || noticeId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('noticeReads')
        .doc(noticeId)
        .set({'readAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _subNotices?.cancel();
    _subReads?.cancel();
    super.dispose();
  }
}
