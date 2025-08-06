import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMemberAdd extends StatefulWidget {
  final List<String> initialSelected;

  const AdminMemberAdd({super.key, this.initialSelected = const []});

  @override
  State<AdminMemberAdd> createState() => _AdminMemberAddState();
}

class _AdminMemberAddState extends State<AdminMemberAdd> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
  }

  void _toggle(String email) {
    setState(() {
      if (_selected.contains(email)) {
        _selected.remove(email);
      } else {
        _selected.add(email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'メンバーを選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final email = data['email'] ?? '';

                      return ListTile(
                        leading: Icon(
                          _selected.contains(email)
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: Colors.black,
                        ),
                        title: Text(email),
                        onTap: () => _toggle(email),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selected.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 40),
                ),
                child: const Text('追加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
