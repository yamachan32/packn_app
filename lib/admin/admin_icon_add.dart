import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminIconAdd extends StatefulWidget {
  const AdminIconAdd({super.key});

  @override
  State<AdminIconAdd> createState() => _AdminIconAddState();
}

class _AdminIconAddState extends State<AdminIconAdd> {
  File? _selectedImage;
  bool _isDeleting = false;
  String? _uploadedFileName;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _uploadedFileName = picked.name;
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (_selectedImage == null || _uploadedFileName == null) return;

    final storageRef = FirebaseStorage.instance.ref().child('icons/$_uploadedFileName');
    await storageRef.putFile(_selectedImage!);

    await FirebaseFirestore.instance.collection('icons').add({
      'label': _uploadedFileName!.split('.').first,
      'icon': _uploadedFileName,
    });

    setState(() {
      _selectedImage = null;
      _uploadedFileName = null;
    });
  }

  Future<void> _deleteIcon(String docId, String filename) async {
    await FirebaseFirestore.instance.collection('icons').doc(docId).delete();
    await FirebaseStorage.instance.ref().child('icons/$filename').delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('アイコン画像管理', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('アイコン一覧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('icons').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final icons = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (context, index) {
                      final icon = icons[index];
                      final iconUrl = FirebaseStorage.instance.ref().child('icons/${icon['icon']}').getDownloadURL();

                      return FutureBuilder<String>(
                        future: iconUrl,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          return GestureDetector(
                            onLongPress: () {
                              setState(() => _isDeleting = !_isDeleting);
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(snapshot.data!, fit: BoxFit.cover),
                                ),
                                if (_isDeleting)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _deleteIcon(icon.id, icon['icon']),
                                      child: Container(
                                        color: Colors.black54,
                                        child: const Icon(Icons.close, color: Colors.white),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _pickImage,
              child: const Text('画像をアップロード'),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              Column(
                children: [
                  Image.file(_selectedImage!, height: 100),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _uploadAndSave,
                    child: const Text('保存'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
