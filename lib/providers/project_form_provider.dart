import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packn_app/providers/projects_provider.dart'; // ← package: で統一

/// プロジェクトの新規/編集フォームを共通化するProvider。
class ProjectFormProvider extends ChangeNotifier {
  final ProjectsProvider projects;
  final String? projectId; // nullなら新規

  final nameCtrl = TextEditingController();

  /// 期間（任意）
  DateTime? startAt;
  DateTime? endAt;

  /// メンバー（メール）
  final List<String> members = [];

  /// リンク行: {icon,label,url}
  final List<Map<String, String>> links = [];

  bool saving = false;

  ProjectFormProvider.newProject(this.projects) : projectId = null;

  ProjectFormProvider.edit(this.projects, Map<String, dynamic> initial)
      : projectId = initial['id']?.toString() {
    nameCtrl.text = (initial['name'] ?? '').toString();

    // members
    final m = (initial['members'] as List?)?.cast<String>() ?? const <String>[];
    members.addAll(m);

    // links
    final l = (initial['links'] as List?)?.cast<Map>() ?? const <Map>[];
    for (final e in l) {
      links.add({
        'icon': (e['icon'] ?? '').toString(),
        'label': (e['label'] ?? '').toString(),
        'url': (e['url'] ?? '').toString(),
      });
    }

    // 期間：startDate / endDate（文字列 or Timestamp or DateTime）を許容
    startAt = _parseFlexibleDate(initial['startDate']);
    endAt   = _parseFlexibleDate(initial['endDate']);
  }

  // 文字列 "yyyy/mm/dd" / "yyyy-m-d" / "yyyy-mm-dd" 等も許容して DateTime に変換
  DateTime? _parseFlexibleDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      final m = RegExp(r'^\s*(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\s*$').firstMatch(v);
      if (m != null) {
        final y = int.tryParse(m.group(1)!);
        final mo = int.tryParse(m.group(2)!);
        final d = int.tryParse(m.group(3)!);
        if (y != null && mo != null && d != null) {
          return DateTime(y, mo, d);
        }
      }
    }
    return null;
  }

  // ====== Public setters（画面側から notifyListeners を直接触らない） ======
  void setStart(DateTime? dt) { startAt = dt; notifyListeners(); }
  void setEnd(DateTime? dt)   { endAt   = dt; notifyListeners(); }

  void addMember(String email) {
    final e = email.trim();
    if (e.isEmpty) return;
    if (!members.contains(e)) {
      members.add(e);
      notifyListeners();
    }
  }

  void removeMemberAt(int index) {
    members.removeAt(index);
    notifyListeners();
  }

  void setMembers(List<String> emails) {
    members
      ..clear()
      ..addAll(emails.map((e) => e.trim()).where((e) => e.isNotEmpty));
    notifyListeners();
  }

  void addLink(Map<String, String> row) {
    links.add({
      'icon': row['icon'] ?? '',
      'label': row['label'] ?? '',
      'url': row['url'] ?? '',
    });
    notifyListeners();
  }

  void replaceLink(int index, Map<String, String> row) {
    links[index] = {
      'icon': row['icon'] ?? '',
      'label': row['label'] ?? '',
      'url': row['url'] ?? '',
    };
    notifyListeners();
  }

  void addLinkRow() {
    links.add({'icon': '', 'label': '', 'url': ''});
    notifyListeners();
  }

  void removeLinkRow(int index) {
    links.removeAt(index);
    notifyListeners();
  }

  void updateLink(int index, {String? icon, String? label, String? url}) {
    final row = links[index];
    if (icon != null) row['icon'] = icon;
    if (label != null) row['label'] = label;
    if (url != null) row['url'] = url;
    notifyListeners();
  }

  // ====== Save ======

  List<Map<String, dynamic>> _normalizedLinks() {
    return links
        .where((r) =>
    (r['label'] ?? '').trim().isNotEmpty &&
        (r['url'] ?? '').trim().isNotEmpty)
        .map((r) => {
      'icon': (r['icon'] ?? '').trim(),
      'label': (r['label'] ?? '').trim(),
      'url': (r['url'] ?? '').trim(),
    })
        .toList();
  }

  Future<bool> save() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return false;

    saving = true;
    notifyListeners();

    try {
      if (projectId == null) {
        await projects.createProject(
          name: name,
          links: _normalizedLinks(),
          members: members.toList(),
          startAt: startAt,
          endAt: endAt,
        );
      } else {
        await projects.updateProject(
          id: projectId!,
          name: name,
          links: _normalizedLinks(),
          members: members.toList(),
          startAt: startAt,
          endAt: endAt,
        );
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
