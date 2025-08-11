import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/notice_provider.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;
  const NoticeDetailScreen({super.key, required this.notice});

  String _dateLabel(dynamic ts) {
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    }
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  Uri _normalizeUrl(String raw) {
    var t = raw.trim();
    if (t.isEmpty) t = 'about:blank';
    if (!t.contains('://')) t = 'https://$t';
    return Uri.parse(t);
  }

  Future<void> _openUrl(BuildContext context, String? raw) async {
    if (raw == null || raw.trim().isEmpty) return;
    final uri = _normalizeUrl(raw);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('URLを開けません')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('URLを開けません: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefix = context.read<NoticeProvider>().prefixFor(notice); // [全体周知] or [PJ名]
    final title = (notice['title'] ?? '').toString();
    final body = (notice['body'] ?? '').toString();
    final url = (notice['url'] ?? '').toString();
    final createdAt = notice['createdAt'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('お知らせ詳細'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94, // 画面幅より少し小さく
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [プレフィックス] タイトル（少し大きめ）
                  Text(
                    '[$prefix] $title',
                    style: const TextStyle(
                      fontSize: 20, // ← 大きめ
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 公開日
                  Text(
                    '公開日：${_dateLabel(createdAt)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  // 本文
                  Text(body, style: const TextStyle(fontSize: 16)),
                  // URL があればリンク
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _openUrl(context, url),
                      child: Text(
                        url,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
