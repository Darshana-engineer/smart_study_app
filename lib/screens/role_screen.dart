import 'package:flutter/material.dart';
import 'package:smart_study_app/role/admin_page.dart';
import 'package:smart_study_app/role/student_page.dart';
import 'package:smart_study_app/role/teacher_page.dart';

class RoleScreen extends StatelessWidget {
  final String prn;

  const RoleScreen({super.key, required this.prn});

  void _navigateToRole(BuildContext context, String role) {
    late Widget page;

    if (role == 'student') {
      page = StudentPage(prn: prn); // ✅ Passing real PRN here
    } else if (role == 'teacher') {
      page = TeacherPage(prn: prn); // ✅ Same here
    } else if (role == 'admin') {
      page = AdminPage(prn: prn);   // ✅ And here
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unknown role selected!")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Role")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Logged in as PRN: $prn",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _navigateToRole(context, 'student'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Student"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _navigateToRole(context, 'teacher'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Teacher"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _navigateToRole(context, 'admin'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("Admin"),
            ),
          ],
        ),
      ),
    );
  }
}
