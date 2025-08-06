import 'package:flutter/material.dart';

class AdminLinkAdd extends StatefulWidget {
  const AdminLinkAdd({super.key});

  @override
  State<AdminLinkAdd> createState() => _AdminLinkAddState();
}

class _AdminLinkAddState extends State<AdminLinkAdd> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  String? _selectedIcon;

  final List<String> iconList = [
    'Icon_GoogleChrome.png',
    'Icon_GoogleCalendar.png',
    'Icon_Backlog.png',
    'Icon_Slack.png',
    'Icon_Figma.png',
    'Icon_Wicon.png',
    'Icon_E.png',
    'Icon_P.png',
    'Icon_PDF.png',
    'Icon_txt.png',
    'Icon_Folder.png',
    'Icon_Link.png',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('リンク追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'リンク名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'アイコン選択',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: iconList.map((fileName) {
                final isSelected = _selectedIcon == fileName;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = fileName;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Colors.amber : Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/icons/$fileName',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 48);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _labelController.text.trim();
            final url = _urlController.text.trim();
            if (label.isEmpty || url.isEmpty || _selectedIcon == null) return;

            Navigator.pop(context, {
              'label': label,
              'url': url,
              'icon': _selectedIcon,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: const Text('追加', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
