import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/notice_provider.dart';
import '../providers/user_provider.dart';
import 'notice_detail_screen.dart';

class NoticeListScreen extends StatelessWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NoticeProvider>();
    final uid = context.watch<UserProvider>().uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('お知らせ一覧'),
        centerTitle: true,
      ),
      body: np.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          // 画面幅より少し小さく（94%）
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: _NoticePanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < np.notices.length; i++) ...[
                    _NoticeRow(
                      notice: np.notices[i],
                      unread: () {
                        final reads = (np.notices[i]['readUsers'] as List?)
                            ?.cast<String>() ??
                            const <String>[];
                        return !(uid != null && reads.contains(uid));
                      }(),
                      prefix: np.prefixFor(np.notices[i]),
                      onTap: () async {
                        final id = (np.notices[i]['id'] ?? '').toString();
                        await context.read<NoticeProvider>().markAsRead(id);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NoticeDetailScreen(notice: np.notices[i]),
                          ),
                        );
                      },
                    ),
                    if (i != np.notices.length - 1)
                      Divider(height: 1, color: Colors.grey.shade300),
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

/// パネル共通スタイル（背景付き・角丸・わずかな影）
class _NoticePanel extends StatelessWidget {
  final Widget child;
  const _NoticePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    );
  }
}

/// 一覧の1行（左端に日付、続いて [prefix] タイトル）
/// ・未読は太字＋青＋下線／既読は通常色＋下線
class _NoticeRow extends StatelessWidget {
  final Map<String, dynamic> notice;
  final bool unread;
  final String prefix;
  final VoidCallback onTap;

  const _NoticeRow({
    required this.notice,
    required this.unread,
    required this.prefix,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final title = (notice['title'] ?? '').toString();
    final createdAt = notice['createdAt'];
    final dateText = _dateLabel(createdAt);

    final titleStyle = TextStyle(
      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
      color: unread ? Colors.blue : Colors.black87,
      decoration: TextDecoration.underline,
      decorationColor: unread ? Colors.blue : Colors.black54,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
            children: [
              // 日付（左詰め・薄めの色・下線なし）
              if (dateText.isNotEmpty)
                TextSpan(
                  text: '$dateText ',
                  style: const TextStyle(
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              // [prefix] タイトル
              TextSpan(
                text: '[$prefix] $title',
                style: titleStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
