import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// プロジェクト一覧を購読・キャッシュし、CRUDをまとめるProvider。
/// Firestore: projects/{id} {
///   name: string,
///   links: [ {icon,label,url} ],
///   members: [email,...],
///   startDate?: "yyyy/MM/dd",  // 文字列
///   endDate?:   "yyyy/MM/dd",  // 文字列
///   createdAt: Timestamp,
///   updatedAt: Timestamp
/// }
class ProjectsProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  final Map<String, Map<String, dynamic>> _items = {}; // id -> data
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _bound = false;

  /// 一覧（name昇順）
  List<Map<String, dynamic>> get projects {
    final list = _items.entries
        .map((e) => {'id': e.key, ...e.value})
        .toList(growable: false);
    list.sort((a, b) => (a['name'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['name'] ?? '').toString().toLowerCase()));
    return list;
  }

  /// 単体取得（null許容）
  Map<String, dynamic>? getById(String id) {
    final d = _items[id];
    if (d == null) return null;
    return {'id': id, ...d};
  }

  /// リアルタイム購読開始（多重呼び出しOK）
  Future<void> bind() async {
    if (_bound) return;
    _bound = true;
    _loading = true;
    notifyListeners();

    final query = FirebaseFirestore.instance.collection('projects');
    _sub = query.snapshots().listen((qs) {
      _items.clear();
      for (final d in qs.docs) {
        _items[d.id] = d.data();
      }
      _loading = false;
      notifyListeners();
    }, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  /// 作成
  Future<String> createProject({
    required String name,
    required List<Map<String, dynamic>> links,
    required List<String> members,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'name': name.trim(),
      'links': links,
      'members': members,
      'createdAt': now,
      'updatedAt': now,
    };
    if (startAt != null) data['startDate'] = _fmtDate(startAt);
    if (endAt != null) data['endDate'] = _fmtDate(endAt);

    final doc = await FirebaseFirestore.instance.collection('projects').add(data);
    return doc.id;
  }

  /// 更新
  Future<void> updateProject({
    required String id,
    required String name,
    required List<Map<String, dynamic>> links,
    required List<String> members,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'links': links,
      'members': members,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (startAt != null) {
      data['startDate'] = _fmtDate(startAt);
    }
    if (endAt != null) {
      data['endDate'] = _fmtDate(endAt);
    }

    await FirebaseFirestore.instance.collection('projects').doc(id).update(data);
  }

  /// 削除
  Future<void> deleteProject(String id) async {
    await FirebaseFirestore.instance.collection('projects').doc(id).delete();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
