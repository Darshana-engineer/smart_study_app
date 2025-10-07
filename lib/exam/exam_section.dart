import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../role/exam/gemini_service.dart';
import '../test_gemini.dart';

class ExamSectionPage extends StatefulWidget {
  final String subject;
  final String studentPRN;
  final String prn;

  const ExamSectionPage({
    super.key,
    required this.subject,
    required this.studentPRN,
    required this.prn,
  });

  @override
  State<ExamSectionPage> createState() => _ExamSectionPageState();
}

class _ExamSectionPageState extends State<ExamSectionPage> {
  List<String> selectedChapters = [];
  int selectedMarks = 2;

  bool loading = false;
  List<Map<String, dynamic>> questions = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Exam Section'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Chapters:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('materials')
                        .doc(widget.subject)
                        .collection('chapters')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No chapters found. Please upload materials first.');
                      }
                      final chapters = snapshot.data!.docs.map((doc) => doc.id).toList();
                      return Wrap(
                        spacing: 8,
                        children: chapters.map((chapter) {
                          final isSelected = selectedChapters.contains(chapter);
                          return FilterChip(
                            label: Text(chapter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedChapters.add(chapter);
                                } else {
                                  selectedChapters.remove(chapter);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Marks Scheme:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: [2, 3, 4, 5, 6].map((mark) {
                      return ChoiceChip(
                        label: Text('$mark Marks'),
                        selected: selectedMarks == mark,
                        onSelected: (_) {
                          setState(() {
                            selectedMarks = mark;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _generateQuestions,
                          child: const Text('Generate Questions for Selected Chapters'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _generateQuestionsForSubject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Generate General Questions'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _testApiConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Test API Connection'),
                  ),
                  const SizedBox(height: 30),
                  if (questions.isNotEmpty) ...[
                    const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    ...questions.map((q) => _buildQuestionCard(q)),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final questionText = question['question'];
    final answerText = question['answer'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Q: $questionText', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Answer: $answerText', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQuestions() async {
  if (selectedChapters.isEmpty) {
    _showSnack('Select at least one chapter');
    return;
  }

  setState(() {
    loading = true;
    questions = [];
  });

  try {
      print("🚀 Starting question generation for subject: ${widget.subject}");
      print("📚 Selected chapters: $selectedChapters");
      print("🎯 Selected marks: $selectedMarks");

      // Generate questions using Gemini API based on selected chapters
      final geminiService = GeminiService();
      
      // Test API key first
      print("🔑 Testing API key and available models...");
      await geminiService.testApiKey();
      
      // Create a comprehensive prompt with selected chapters
      final chaptersText = selectedChapters.join(', ');
      final prompt = '''
Generate exactly 5 question-answer pairs for the subject "${widget.subject}" covering these chapters: $chaptersText
Each question should be worth $selectedMarks marks.

Format strictly as:

Q1: <question>
Ans: <answer>

Q2: <question>
Ans: <answer>

Q3: <question>
Ans: <answer>

Q4: <question>
Ans: <answer>

Q5: <question>
Ans: <answer>

Only plain text. No explanation or intro. Make questions relevant to the selected chapters.
''';

      final generatedQuestions = await geminiService.generateQuestionsWithCustomPrompt(
        prompt: prompt,
        subject: widget.subject,
        selectedMarks: selectedMarks,
      );
      
      if (generatedQuestions.isNotEmpty) {
        setState(() {
          questions = generatedQuestions;
        });
        _showSnack('✅ Generated ${generatedQuestions.length} questions using AI for chapters: $chaptersText');
        print("✅ Successfully generated ${generatedQuestions.length} questions");
      } else {
        _showSnack('❌ Failed to generate questions. Please try again.');
        print("❌ No questions generated");
      }

    } catch (e) {
      print("❌ Error generating questions: $e");
      _showSnack('Error generating questions: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _generateQuestionsForSubject() async {
    setState(() {
      loading = true;
      questions = [];
    });

    try {
      print("🚀 Generating general questions for subject: ${widget.subject}");
      print("🎯 Selected marks: $selectedMarks");

      // Generate general questions using Gemini API
      final geminiService = GeminiService();
      
      // Test API key first
      print("🔑 Testing API key and available models...");
      await geminiService.testApiKey();
      
      final prompt = '''
Generate exactly 5 question-answer pairs for the subject "${widget.subject}" worth $selectedMarks marks each.
Create questions that cover the main topics and concepts of this subject.

Format strictly as:

Q1: <question>
Ans: <answer>

Q2: <question>
Ans: <answer>

Q3: <question>
Ans: <answer>

Q4: <question>
Ans: <answer>

Q5: <question>
Ans: <answer>

Only plain text. No explanation or intro. Make questions comprehensive and relevant to the subject.
''';

      final generatedQuestions = await geminiService.generateQuestionsWithCustomPrompt(
        prompt: prompt,
        subject: widget.subject,
        selectedMarks: selectedMarks,
      );
      
      if (generatedQuestions.isNotEmpty) {
        setState(() {
          questions = generatedQuestions;
        });
        _showSnack('✅ Generated ${generatedQuestions.length} general questions for ${widget.subject}');
        print("✅ Successfully generated ${generatedQuestions.length} general questions");
      } else {
        _showSnack('❌ Failed to generate questions. Please try again.');
        print("❌ No questions generated");
      }

    } catch (e) {
      print("❌ Error generating questions: $e");
      _showSnack('Error generating questions: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    setState(() {
      loading = true;
    });

    try {
      print("🔧 Testing API connection...");
      
      // Use the comprehensive tester
      await GeminiTester.testAllEndpoints();
      
      _showSnack("✅ API test completed! Check console for detailed results.");
  } catch (e) {
      print("❌ API test error: $e");
      _showSnack("❌ API test failed: $e");
  } finally {
    setState(() {
      loading = false;
    });
  }
}

    void _showSnack(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
