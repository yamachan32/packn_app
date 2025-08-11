import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 管理者用：お知らせ一覧の購読とCRUD。
/// notices/{id}:
///  - title: string
///  - body: string
///  - url: string?
///  - projectId: string?   // null/空なら全体周知
///  - isGlobal: bool       // trueなら全体周知
///  - publishStart: Timestamp?  // 公開開始
///  - publishEnd: Timestamp?    // 公開終了
///  - createdAt: Timestamp
///  - updatedAt: Timestamp
class AdminNoticesProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get notices => List.unmodifiable(_items);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _bound = false;

  Future<void> bind() async {
    if (_bound) return;
    _bound = true;
    _loading = true;
    _error = null;
    notifyListeners();

    // インデックス不要にするため createdAt のみで購読
    final col = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('createdAt', descending: true);

    _sub = col.snapshots().listen((qs) {
      final list = qs.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      // クライアント側で publishStart 優先の降順に並べ替え
      int _cmp(Map<String, dynamic> a, Map<String, dynamic> b) {
        DateTime _toDate(dynamic v) {
          if (v is Timestamp) return v.toDate();
          if (v is DateTime) return v;
          return DateTime.fromMillisecondsSinceEpoch(0);
        }

        final da = _toDate(a['publishStart'] ?? a['createdAt']);
        final db = _toDate(b['publishStart'] ?? b['createdAt']);
        return db.compareTo(da); // desc
      }

      list.sort(_cmp);

      _items
        ..clear()
        ..addAll(list);
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<String> create({
    required String title,
    required String body,
    String? url,
    String? projectId,     // null/空で全体周知
    bool isGlobal = false, // trueで全体周知
    DateTime? publishStart,
    DateTime? publishEnd,
  }) async {
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      'url': (url ?? '').trim(),
      'projectId': (isGlobal || (projectId ?? '').isEmpty) ? null : projectId,
      'isGlobal': isGlobal || (projectId ?? '').isEmpty,
      'publishStart': publishStart == null ? null : Timestamp.fromDate(publishStart),
      'publishEnd': publishEnd == null ? null : Timestamp.fromDate(publishEnd),
      'createdAt': now,
      'updatedAt': now,
    };
    final doc = await FirebaseFirestore.instance.collection('notices').add(data);
    return doc.id;
  }

  Future<void> update({
    required String id,
    required String title,
    required String body,
    String? url,
    String? projectId,
    bool isGlobal = false,
    DateTime? publishStart,
    DateTime? publishEnd,
  }) async {
    final data = <String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      'url': (url ?? '').trim(),
      'projectId': (isGlobal || (projectId ?? '').isEmpty) ? null : projectId,
      'isGlobal': isGlobal || (projectId ?? '').isEmpty,
      'publishStart': publishStart == null ? null : Timestamp.fromDate(publishStart),
      'publishEnd': publishEnd == null ? null : Timestamp.fromDate(publishEnd),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance.collection('notices').doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('notices').doc(id).delete();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
