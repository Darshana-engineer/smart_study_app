// PAGE 2: ViewMaterialPage

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewMaterialPage extends StatelessWidget {
  final String subject;

  const ViewMaterialPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$subject - Materials 💾'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('materials')
            .doc(subject)
            .collection('chapters')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No materials found for this subject 💔'));
          }

          return ListView(
            children: snapshot.data!.docs.map((chapterDoc) {
              final chapterName = chapterDoc.id;
              final data = chapterDoc.data() as Map<String, dynamic>;

              return ExpansionTile(
                title: Text('📘 Chapter: $chapterName'),
                children: [
                  if (data['syllabusUrl'] != null)
                    ListTile(
                      title: const Text("📄 Syllabus"),
                      onTap: () => _launchURL(data['syllabusUrl']),
                    ),
                  if (data['notesUrl'] != null)
                    ListTile(
                      title: const Text("📝 Notes"),
                      onTap: () => _launchURL(data['notesUrl']),
                    ),
                  if (data['questionBankUrl'] != null)
                    ListTile(
                      title: const Text("📚 Question Bank"),
                      onTap: () => _launchURL(data['questionBankUrl']),
                    ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}