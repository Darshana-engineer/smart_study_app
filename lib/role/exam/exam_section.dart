import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_page.dart';

class ExamSectionPage extends StatefulWidget {
  final String subject;
  final String studentPRN;

  const ExamSectionPage({
    super.key,
    required this.subject,
    required this.studentPRN,
  });

  @override
  State<ExamSectionPage> createState() => _ExamSectionPageState();
}

class _ExamSectionPageState extends State<ExamSectionPage> {
  int selectedMarks = 2;
  bool loading = false;
  List<Map<String, dynamic>> questions = [];
  Map<String, bool> readStatus = {};
  Map<String, String> studentAnswers = {};
  final Map<String, TextEditingController> _controllers = {};
  final String geminiApiKey = 'AIzaSyCJnnvDJ2uGQ_EILhlANX0zsgVQ86VTs8c';

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool isAnswerCorrect(String correctAns, String studentAns) {
    final correctWords = correctAns.split(RegExp(r'\s+')).map((w) => w.toLowerCase()).toList();
    final studentWords = studentAns.split(RegExp(r'\s+')).map((w) => w.toLowerCase()).toList();
    int matchCount = correctWords.where((word) => studentWords.contains(word)).length;
    double matchPercent = (matchCount / correctWords.length) * 100;
    return matchPercent >= 60;
  }

  Future<void> _generateQuestions() async {
    setState(() {
      loading = true;
      questions.clear();
      readStatus.clear();
      studentAnswers.clear();
      _controllers.clear();
    });

    try {
      final dbRef = FirebaseDatabase.instance.ref('questions/${widget.subject}');
      final snapshot = await dbRef.once();
      final data = snapshot.snapshot.value;

      List<Map<String, dynamic>> fetchedQuestions = [];

      if (data is Map) {
        for (var chapter in data.values) {
          if (chapter is Map) {
            for (var topic in chapter.values) {
              if (topic is Map) {
                for (var qEntry in topic.entries) {
                  final qData = qEntry.value;
                  if (qData is Map && qData['marks'] == selectedMarks) {
                    fetchedQuestions.add({
                      'id': qEntry.key,
                      'question': qData['question'],
                      'answer': qData['answer'],
                    });
                  }
                }
              }
            }
          }
        }
      }

      if (fetchedQuestions.isEmpty) {
        _showSnack("No questions in Firebase, generating with Gemini...");
        fetchedQuestions = await _generateUsingGemini();
      }

      setState(() {
        questions = fetchedQuestions;
        for (var q in questions) {
          final qId = q['id'];
          readStatus[qId] = false;
          studentAnswers[qId] = '';
          _controllers[qId] = TextEditingController();
        }
      });

      if (questions.isEmpty) {
        _showSnack("No questions found or generated.");
      }
    } catch (e) {
      _showSnack("Error loading questions: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _generateUsingGemini() async {
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey");

    final prompt = '''
Generate 5 exam-style questions with answers for the subject "${widget.subject}" for $selectedMarks marks each. Provide output in JSON like:
[
  {"question": "...", "answer": "..."},
  ...
]
Only return JSON array.
''';

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "contents": [
        {
          "parts": [{"text": prompt}]
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      final content = resData['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (content != null) {
        try {
          final generated = json.decode(content);
          return List<Map<String, dynamic>>.from(generated).asMap().entries.map((entry) {
            return {
              'id': 'gemini_q${entry.key}',
              'question': entry.value['question'],
              'answer': entry.value['answer'],
            };
          }).toList();
        } catch (e) {
          debugPrint("Gemini JSON error: $e");
        }
      }
    } else {
      debugPrint("Gemini API failed: ${response.statusCode} ${response.body}");
    }

    return [];
  }

  Future<void> _submitAnswers() async {
    if (questions.isEmpty) {
      _showSnack("No questions to submit.");
      return;
    }

    setState(() => loading = true);

    try {
      final answersCollection = FirebaseFirestore.instance
          .collection('exam_answers')
          .doc(widget.studentPRN)
          .collection(widget.subject);

      for (var q in questions) {
        final qId = q['id'];
        await answersCollection.doc(qId).set({
          'question': q['question'],
          'correctAnswer': q['answer'],
          'studentAnswer': studentAnswers[qId] ?? '',
          'read': readStatus[qId] ?? false,
          'marks': selectedMarks,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      int correctAnswers = 0;
      for (var q in questions) {
        final qId = q['id'];
        final studentAns = (studentAnswers[qId] ?? '').trim();
        final correctAns = (q['answer'] ?? '').trim();
        if (isAnswerCorrect(correctAns, studentAns)) correctAnswers++;
      }

      final totalMarksScored = correctAnswers * selectedMarks;
      final reportId = "${widget.studentPRN}_${DateTime.now().toIso8601String().substring(0, 10)}";

      await FirebaseFirestore.instance.collection('exam_reports').doc(reportId).set({
        'prn': widget.studentPRN,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'totalQuestions': questions.length,
        'correctAnswers': correctAnswers,
        'marksPerQuestion': selectedMarks,
        'totalMarksScored': totalMarksScored,
        'subject': widget.subject,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPage(
              prn: widget.studentPRN,
              subject: widget.subject,
              date: DateTime.now().toIso8601String().substring(0, 10),
              totalQuestions: questions.length,
              correctAnswers: correctAnswers,
              marksPerQuestion: selectedMarks,
              totalMarksScored: totalMarksScored,
              questions: questions.map((q) {
                final qId = q['id'];
                return {
                  'question': q['question'],
                  'correctAnswer': q['answer'],
                  'studentAnswer': studentAnswers[qId] ?? '',
                };
              }).toList(),
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack("Submission error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final qId = q['id'];
    _controllers.putIfAbsent(qId, () => TextEditingController());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text("Q: ${q['question']}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Checkbox(
                  value: readStatus[qId] ?? false,
                  onChanged: (val) => setState(() => readStatus[qId] = val ?? false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controllers[qId]!..text = studentAnswers[qId] ?? '',
              onChanged: (val) => studentAnswers[qId] = val,
              decoration: const InputDecoration(
                labelText: "Your Answer",
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject} Exam Section')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Marks Scheme:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [2, 3, 4, 5, 6].map((mark) {
                        return ChoiceChip(
                          label: Text("$mark Marks"),
                          selected: selectedMarks == mark,
                          onSelected: (_) => setState(() => selectedMarks = mark),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _generateQuestions,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Generate Questions"),
                    ),
                    const SizedBox(height: 30),
                    if (questions.isNotEmpty) ...[
                      const Text("Questions:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...questions.map(_buildQuestionCard),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _submitAnswers,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: const Text("Submit Answers"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
