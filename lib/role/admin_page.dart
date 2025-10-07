import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  final String prn;
  const AdminPage({super.key, required this.prn});

  @override
  State<AdminPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<AdminPage> {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No profile data found, baby.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Your Profile"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text("Name: ${profileData!['name'] ?? 'N/A'}"),
              Text("PRN: ${profileData!['prn'] ?? 'N/A'}"),
              Text("Password: ${profileData!['password'] ?? 'N/A'}"),
              Text("Year: ${profileData!['year'] ?? 'N/A'}"),
              Text("Branch: ${profileData!['branch'] ?? 'N/A'}"),
              Text("Semester: ${profileData!['semester'] ?? 'N/A'}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          )
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
        title: const Text("admin Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showProfileDialog,
              child: CircleAvatar(
                radius: 16,
                backgroundImage: const AssetImage('assets/images/student_avatar.png'), // your constant image
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text("Welcome to the Admin Dashboard!"),
      ),
    );
  }
}
