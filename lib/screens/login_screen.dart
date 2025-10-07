import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role/student_page.dart';
import '../role/teacher_page.dart';

class LoginScreen extends StatefulWidget {
  final String? selectedRole;
  
  const LoginScreen({super.key, this.selectedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _prn = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final String prn = _prn.text.trim(); // ensure it's a string!
    final String pass = _pass.text.trim();

    if (prn.isEmpty || pass.isEmpty) {
      _showMsg("Please fill in both fields!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("🔍 Attempting login for PRN: $prn");
      final doc = await FirebaseFirestore.instance.collection('users').doc(prn).get();

      print("📄 Document exists: ${doc.exists}");
      if (doc.exists) {
        print("📋 Document data: ${doc.data()}");
        print("🔑 Stored password: ${doc['password']}");
        print("🔑 Entered password: $pass");
      }

      if (!doc.exists) {
        if (!mounted) return;
        _showMsg("User with PRN $prn not found. Please sign up first!");
        return;
      }

      if (doc['password'] != pass) {
        if (!mounted) return;
        _showMsg("Wrong password! Please try again.");
        return;
      }

      _showMsg("Welcome back, ${doc['name']}!");

      if (!mounted) return;
      
      // Navigate directly to the role's home
      final userRole = (doc.data() as Map<String, dynamic>)['role'] ?? 'student';
      if (userRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin', arguments: prn);
      } else if (userRole == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherPage(prn: prn)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentPage(prn: prn)),
        );
      }
    } catch (e) {
      print("❌ Login error: $e");
      if (!mounted) return;
      _showMsg("Login failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = widget.selectedRole ?? 'User';
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Login as $selectedRole"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _prn,
              keyboardType: TextInputType.number, // optional for number input
              decoration: const InputDecoration(labelText: "PRN"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text("Logging in...", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  )
                : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text("No account? Sign Up here"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _prn.dispose();
    _pass.dispose();
    super.dispose();
  }
}
