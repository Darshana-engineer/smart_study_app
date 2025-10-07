import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../material/uploadmaterial_page.dart';

class TeacherPage extends StatefulWidget {
  final String prn;
  const TeacherPage({super.key, required this.prn});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  Map<String, dynamic>? profileData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.prn).get();
      if (doc.exists) {
        setState(() {
          profileData = doc.data();
          loading = false;
        });
      } else {
        setState(() {
          profileData = null;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        profileData = null;
        loading = false;
      });
    }
  }

  void _showProfileDialog() {
    if (profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No profile data found.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("👤 Teacher Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${profileData!['name'] ?? 'N/A'}"),
            Text("PRN: ${profileData!['prn'] ?? 'N/A'}"),
            Text("Password: ${profileData!['password'] ?? 'N/A'}"),
            Text("Year: ${profileData!['year'] ?? 'N/A'}"),
            Text("Branch: ${profileData!['branch'] ?? 'N/A'}"),
            Text("Semester: ${profileData!['semester'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("👨‍🏫 Teacher Dashboard"),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.purple),
            ),
            onPressed: _showProfileDialog,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${profileData?['name'] ?? 'Teacher'} 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "📚 Upload Study Materials",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UploadMaterialPage()),
                        );
                      },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text("Upload Now"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
