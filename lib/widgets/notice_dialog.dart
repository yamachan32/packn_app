import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/notice_provider.dart';
import '../screens/notice_detail_screen.dart';

/// Provider ベースのお知らせダイアログ。
/// Firestore の Notice モデル型に依存せず、Map で扱います。
class NoticeDialog extends StatelessWidget {
  const NoticeDialog({super.key});

  String _formatDate(dynamic ts) {
    DateTime? dt;
    if (ts == null) {
      return '';
    } else if (ts is DateTime) {
      dt = ts;
    } else if (ts is Timestamp) {
      dt = ts.toDate();
    } else {
      return ts.toString();
    }
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NoticeProvider>();

    return AlertDialog(
      title: const Text('お知らせ'),
      content: SizedBox(
        width: double.maxFinite,
        child: np.loading
            ? const Center(child: CircularProgressIndicator())
            : (np.notices.isEmpty
            ? const Text('お知らせはありません')
            : ListView.separated(
          shrinkWrap: true,
          itemCount: np.notices.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final n = np.notices[i];
            final title = (n['title'] ?? '').toString();
            final createdAt = n['createdAt'];
            return ListTile(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_formatDate(createdAt)),
              onTap: () {
                Navigator.pop(context); // ダイアログを閉じる
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoticeDetailScreen(notice: n),
                  ),
                );
              },
            );
          },
        )),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        )
      ],
    );
  }
}
