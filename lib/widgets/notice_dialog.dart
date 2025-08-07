import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/notice_model.dart';
import '../providers/user_provider.dart';

Future<void> showNoticeDialog(BuildContext context, String? selectedProjectId) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  final query = FirebaseFirestore.instance
      .collection('notices')
      .orderBy('createdAt', descending: true);

  final snapshot = await query.get();

  final allNotices = snapshot.docs
      .map((doc) => Notice.fromDoc(doc.id, doc.data()))
      .where((notice) =>
  notice.projectId == null ||
      notice.projectId == 'all' ||
      userProvider.assignedProjects.contains(notice.projectId))
      .toList();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('お知らせ一覧'),
      content: SizedBox(
        width: double.maxFinite,
        child: allNotices.isEmpty
            ? const Text('お知らせはありません')
            : ListView.builder(
          shrinkWrap: true,
          itemCount: allNotices.length,
          itemBuilder: (_, index) {
            final notice = allNotices[index];
            return ListTile(
              title: Text(notice.title),
              subtitle: notice.createdAt != null
                  ? Text(
                '${notice.createdAt!.toLocal()}'.split('.')[0],
                style: const TextStyle(fontSize: 12),
              )
                  : null,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(notice.title),
                    content: Text(notice.body),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        )
      ],
    ),
  );
}
