class Notice {
  final String id;
  final String title;
  final String body;
  final String? projectId;
  final DateTime? createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    this.projectId,
    this.createdAt,
  });

  factory Notice.fromDoc(String id, Map<String, dynamic> data) {
    return Notice(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      projectId: data['projectId'],
      createdAt: data['createdAt']?.toDate(),
    );
  }
}
