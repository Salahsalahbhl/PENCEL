import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key});

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  List<String> selectedFiles = [];

  Future<void> pickFiles() async {
    final List<XFile> pickedFiles = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(label: 'Text or PDF', extensions: ['txt', 'pdf']),
      ],
    );

    if (pickedFiles.isEmpty) return;

    List<String> accepted = [];
    List<String> rejected = [];

    for (final file in pickedFiles) {
      final name = file.name;
      final nameWithoutExt = name.split('.').first;

      if (RegExp(r'^\d+$').hasMatch(nameWithoutExt)) {
        accepted.add(name);
      } else {
        rejected.add(name);
      }
    }

    setState(() {
      selectedFiles.addAll(accepted);
    });

    if (rejected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تجاهل الملفات التالية (ليست بأسماء رقمية): ${rejected.join(", ")}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (accepted.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تحميل ${accepted.length} ملف'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void deleteFile(String fileName) {
    setState(() {
      selectedFiles.remove(fileName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ تم حذف $fileName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        title: const Text('إدارة الملفات الرقمية'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: pickFiles,
          ),
        ],
      ),
      body: selectedFiles.isEmpty
          ? const Center(
              child: Text(
                'لم يتم تحميل أي ملف بعد',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final fileName = selectedFiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(fileName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteFile(fileName),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
