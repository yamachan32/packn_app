import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice; // 一覧から渡されるドキュメントデータ
  const NoticeDetailScreen({super.key, required this.notice});

  String _fmtYmd(dynamic ts) {
    DateTime? d;
    if (ts is Timestamp) d = ts.toDate();
    if (ts is DateTime) d = ts;
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '$y/$m/$da';
  }

  @override
  Widget build(BuildContext context) {
    final title = (notice['title'] ?? '').toString();
    final body  = (notice['body']  ?? '').toString();

    // 表示用タグ（[全体周知] or [PJ名]）
    final bool isGlobal =
        (notice['isGlobal'] == true) || notice['projectId'] == null;
    String tagLabel = '全体周知';
    if (!isGlobal) {
      final pid = (notice['projectId'] ?? '').toString();
      final name = context.read<UserProvider>().getProjectName(pid);
      tagLabel = name == null || name.isEmpty ? pid : name;
    }

    // 公開日付（publishStart があればそれ、無ければ createdAt）
    final published = notice['publishStart'] ?? notice['createdAt'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('お知らせ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.94,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル行（[全体周知 or PJ名] タグ + タイトル大）
                Text(
                  '[${isGlobal ? '全体周知' : tagLabel}] $title',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                // 公開日付
                Text(
                  _fmtYmd(published),
                  style: const TextStyle(color: Colors.black87),
                ),

                const SizedBox(height: 12),

                // 本文（URLを自動リンク化）
                LinkifiedText(
                  body,
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 本文内の URL（https://... / http://... / www.～）を自動でリンク化するウィジェット
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const LinkifiedText(
      this.text, {
        super.key,
        this.style,
        this.linkStyle,
      });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  // URLマッチ（全角記号や空白で止めやすく）
  static final _urlReg = RegExp(
    r'((?:https?:\/\/|www\.)[^\s<>\u3000-\u303F\uFF00-\uFF65]+)',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  String _cleanUrl(String raw) {
    var u = raw.trim();

    // 末尾の括弧/句読点などを削る
    const tails = [
      ')','（','）','(', '。','、','，','.',',',';','；',':','：',']','】','＞','>','»','」','』'
    ];
    while (u.isNotEmpty && tails.contains(u.characters.last)) {
      u = u.substring(0, u.length - 1);
    }

    // www. 始まりなら https 付与
    if (u.toLowerCase().startsWith('www.')) {
      u = 'https://$u';
    }
    return u;
  }

  Future<void> _open(String url) async {
    final cleaned = _cleanUrl(url);
    try {
      // canLaunchUrl は端末によって false を返すケースがあるため直接 launchUrl を試す
      final ok = await launchUrl(
        Uri.parse(cleaned),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URLを開けません')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けません')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ??
        DefaultTextStyle.of(context).style.copyWith(color: Colors.black87);
    final lstyle = widget.linkStyle ??
        base.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        );

    final spans = <InlineSpan>[];
    _recognizers.clear();

    int start = 0;
    final matches = _urlReg.allMatches(widget.text);

    for (final m in matches) {
      if (m.start > start) {
        spans.add(TextSpan(text: widget.text.substring(start, m.start), style: base));
      }

      final url = widget.text.substring(m.start, m.end);
      final rec = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(rec);

      spans.add(TextSpan(text: url, style: lstyle, recognizer: rec));
      start = m.end;
    }

    if (start < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(start), style: base));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.left,
      softWrap: true,
    );
  }
}
