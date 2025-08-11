import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/notice_provider.dart';
import '../providers/user_provider.dart';
import 'notice_detail_screen.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  String _fmtYmdHm(dynamic ts) {
    DateTime? d;
    if (ts is Timestamp) d = ts.toDate();
    if (ts is DateTime) d = ts;
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y/$m/$da $hh:$mm';
  }

  String _prefixFor(Map<String, dynamic> n, UserProvider up) {
    final isGlobal =
        (n['isGlobal'] == true) || n['projectId'] == null || (n['projectId'] as String? ?? '').isEmpty;
    if (isGlobal) return '全体周知';
    final pid = (n['projectId'] ?? '').toString();
    return up.getProjectName(pid) ?? pid;
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NoticeProvider>();
    final up = context.watch<UserProvider>();

    // 表示対象を取得して、publishStart(なければcreatedAt)の降順にソート
    final items = [...np.visibleNotices]..sort((a, b) {
      DateTime _to(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
      final da = _to(a['publishStart'] ?? a['createdAt']);
      final db = _to(b['publishStart'] ?? b['createdAt']);
      return db.compareTo(da);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('お知らせ一覧'),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? const Center(child: Text('お知らせはありません'))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade300),
              itemBuilder: (_, i) {
                final n = items[i];
                final id = (n['id'] ?? '').toString();
                final title = (n['title'] ?? '').toString();
                final prefix = _prefixFor(n, up);
                final published = n['publishStart'] ?? n['createdAt'];
                final unread = !np.readIds.contains(id);

                final style = TextStyle(
                  fontSize: 16,
                  fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                  color: unread ? Colors.blue : Colors.black87,
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日付（左詰）
                      Text(_fmtYmdHm(published),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text('[$prefix] $title', style: style),
                    ],
                  ),
                  onTap: () async {
                    await context.read<NoticeProvider>().markAsRead(id);
                    if (!_.mounted) return;
                    Navigator.push(
                      _,
                      MaterialPageRoute(
                        builder: (_) => NoticeDetailScreen(notice: n),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
