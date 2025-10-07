//import 'package:flutter/foundation.dart};
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../exam/exam_section.dart';

class StudentPage extends StatefulWidget {
  final String prn;

  const StudentPage({super.key, required this.prn});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final List<String> subjects = ['AML', 'SET', 'ESD', 'BDA'];
  String? selectedSubject;
  List<String> selectedChapters = [];
  Map<String, Map<String, dynamic>> uploadedMaterials = {};
  Map<String, dynamic>? studentDetails;

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.prn).get();
    if (doc.exists) {
      setState(() {
        studentDetails = doc.data();
      });
    }
  }

  void _showStudentDetailsDialog() {
    if (studentDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student details not found.")),
      );
      return;
    }

    final TextEditingController nameController =
        TextEditingController(text: studentDetails!['name']);
    final TextEditingController yearController =
        TextEditingController(text: studentDetails!['year']);
    final TextEditingController branchController =
        TextEditingController(text: studentDetails!['branch']);
    final TextEditingController semesterController =
        TextEditingController(text: studentDetails!['semester']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎓 Edit Student Profile"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _editableField("Name", nameController),
              _editableField("Year", yearController),
              _editableField("Branch", branchController),
              _editableField("Semester", semesterController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedData = {
                'name': nameController.text.trim(),
                'year': yearController.text.trim(),
                'branch': branchController.text.trim(),
                'semester': semesterController.text.trim(),
              };

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.prn)
                  .update(updatedData);

              setState(() {
                studentDetails = updatedData;
              });

              if (mounted) Navigator.pop(context);

                if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated successfully!")),
                );
                }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _editableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _openMaterial(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        leading: GestureDetector(
          onTap: _showStudentDetailsDialog,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/smart_student.png'),
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome, PRN: ${widget.prn}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              const Text('Select Subject:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedSubject,
                hint: const Text('Choose a subject'),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSubject = newValue;
                    selectedChapters.clear();
                    uploadedMaterials.clear();
                  });
                },
                items: subjects.map((subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
              ),
              if (selectedSubject != null) ...[
                const SizedBox(height: 20),
                const Text('Select Chapters:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('materials')
                      .doc(selectedSubject)
                      .collection('chapters')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No chapters found.');
                    }
                    return Wrap(
                      spacing: 10,
                      children: snapshot.data!.docs.map((doc) {
                        final chapter = doc.id;
                        return FilterChip(
                          label: Text(chapter),
                          selected: selectedChapters.contains(chapter),
                          onSelected: (bool selected) async {
                            setState(() {
                              if (selected) {
                                selectedChapters.add(chapter);
                              } else {
                                selectedChapters.remove(chapter);
                                uploadedMaterials.remove(chapter);
                              }
                            });
                            if (selected) {
                              final chapterData = doc.data() as Map<String, dynamic>;
                              setState(() {
                                uploadedMaterials[chapter] = chapterData;
                              });
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('View Uploaded Materials:'),
                const SizedBox(height: 10),
                ...selectedChapters.map((chapter) {
                  final material = uploadedMaterials[chapter] ?? {};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chapter $chapter:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (material['syllabusUrl'] != null)
                        TextButton(
                          onPressed: () => _openMaterial(material['syllabusUrl']),
                          child: const Text('View Syllabus'),
                        ),
                      if (material['notesUrl'] != null)
                        TextButton(
                          onPressed: () => _openMaterial(material['notesUrl']),
                          child: const Text('View Notes'),
                        ),
                      if (material['questionBankUrl'] != null)
                        TextButton(
                          onPressed: () => _openMaterial(material['questionBankUrl']),
                          child: const Text('View Question Bank'),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamSectionPage(
                          studentPRN: widget.prn,
                          subject: selectedSubject!,
                          prn: widget.prn,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment),
                  label: const Text('Go to Exam Section'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
