import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _prn = TextEditingController();
  final TextEditingController _branch = TextEditingController();
  final List<String> yearOptions = ['1','2','3','4'];
  final List<String> semesterOptions = ['1','2','3','4','5','6','7','8'];
  String selectedYear = '3';
  String selectedSemester = '6';
  final TextEditingController _password = TextEditingController();

  final List<String> roles = ['student', 'teacher', 'admin'];
  String selectedRole = 'student';
  bool _isLoading = false;

  Future<void> _register() async {
    if (_name.text.isEmpty ||
        _prn.text.isEmpty ||
        selectedYear.isEmpty ||
        _branch.text.isEmpty ||
        selectedSemester.isEmpty ||
        _password.text.isEmpty) {
      _showMsg("Don’t leave shit empty, babe!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_prn.text.trim());
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        _showMsg("That PRN’s already taken, pick another one!");
        setState(() => _isLoading = false);
        return;
      }

      await docRef.set({
        'name': _name.text.trim(),
        'prn': _prn.text.trim(),
        'year': selectedYear,
        'branch': _branch.text.trim(),
        'semester': selectedSemester,
        'password': _password.text.trim(),
        'role': selectedRole,
      });

      _showMsg("Account created, now go login, ");
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      _showMsg("Shit hit the fan: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _screenUI() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
          const SizedBox(height: 10),
          TextField(controller: _prn, decoration: const InputDecoration(labelText: "PRN")),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: "Role"),
            items: roles.map((role) => DropdownMenuItem(
              value: role,
              child: Text(role.toUpperCase()),
            )).toList(),
            onChanged: (value) => setState(() => selectedRole = value!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedYear,
            decoration: const InputDecoration(labelText: "Year"),
            items: yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) => setState(() => selectedYear = v!),
          ),
          const SizedBox(height: 10),
          TextField(controller: _branch, decoration: const InputDecoration(labelText: "Branch")),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedSemester,
            decoration: const InputDecoration(labelText: "Semester"),
            items: semesterOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => selectedSemester = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Sign Up")),
        body: _screenUI(),
      );

  @override
  void dispose() {
    _name.dispose();
    _prn.dispose();
    _branch.dispose();
    _password.dispose();
    super.dispose();
  }
}
