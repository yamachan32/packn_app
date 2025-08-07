import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String body;
  final String? projectId;
  final Timestamp createdAt;
  final String? url;
  final List<String> readUsers;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    this.projectId,
    required this.createdAt,
    this.url,
    required this.readUsers,
  });

  factory Notice.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Notice(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      projectId: data['projectId'] == 'all' ? null : data['projectId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      url: data['url'],
      readUsers: List<String>.from(data['readUsers'] ?? []),
    );
  }
}
