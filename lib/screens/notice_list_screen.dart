import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice_model.dart';
import 'notice_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.uid;
    final assignedProjects = userProvider.assignedProjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ一覧'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notices = snapshot.data!.docs.map((doc) => Notice.fromDoc(doc)).where((notice) {
            return notice.projectId == null || assignedProjects.contains(notice.projectId);
          }).toList();

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final isRead = notice.readUsers.contains(userId);
              final displayTitle =
                  '${notice.projectId == null ? '全体周知' : userProvider.getProjectName(notice.projectId!)} ${notice.title}';

              return ListTile(
                title: Text(
                  displayTitle,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.grey[600] : Colors.blue,
                  ),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoticeDetailScreen(notice: notice),
                    ),
                  );

                  await FirebaseFirestore.instance
                      .collection('notices')
                      .doc(notice.id)
                      .update({
                    'readUsers': FieldValue.arrayUnion([userId])
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
