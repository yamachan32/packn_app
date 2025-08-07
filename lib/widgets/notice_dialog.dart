import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../screens/notice_detail_screen.dart';

Future<void> showNoticeDialog(BuildContext context, String? projectId) async {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('お知らせ'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notices')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final notices = snapshot.data!.docs.map((doc) => Notice.fromDoc(doc)).where((notice) {
                return notice.projectId == null || notice.projectId == projectId;
              }).toList();

              return ListView.builder(
                shrinkWrap: true,
                itemCount: notices.length,
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  return ListTile(
                    title: Text(notice.title),
                    subtitle: Text(notice.createdAt.toDate().toLocal().toString().split(' ')[0]),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoticeDetailScreen(notice: notice),
                        ),
                      );
                    },
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
          ),
        ],
      );
    },
  );
}
