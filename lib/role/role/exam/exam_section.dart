import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamSectionPage extends StatefulWidget {
  final String subject;
  final String studentPRN;

  const ExamSectionPage({super.key, required this.subject, required this.studentPRN});

  @override
  ExamSectionPageState createState() => ExamSectionPageState();
}

class ExamSectionPageState extends State<ExamSectionPage> {
  List<String> selectedChapters = [];
  List<String> selectedTopics = [];
  int selectedMarks = 2;

  bool loading = false;
  List<Map<String, dynamic>> questions = [];
  Map<String, bool> readStatus = {};
  Map<String, String> studentAnswers = {};

  // Controllers map to keep TextEditingControllers per question to avoid rebuilding problem
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    // Dispose all controllers to avoid memory leaks
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
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final chapters = snapshot.data!.docs.map((d) => d.id).toList();
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
                                  // Also remove topics if chapters deselected
                                  selectedTopics.removeWhere((topic) => topic.startsWith('$chapter|'));
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Topics:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._buildTopicsSelector(),
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
                  ElevatedButton(
                    onPressed: _generateQuestions,
                    child: const Text('Generate Questions & Answers'),
                  ),
                  const SizedBox(height: 30),
                  if (questions.isNotEmpty) ...[
                    const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    ...questions.map((q) => _buildQuestionCard(q)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitAnswers,
                      child: const Text('Submit Answers & Save Results'),
                    ),
                  ]
                ],
              ),
            ),
    );
  }

  List<Widget> _buildTopicsSelector() {
    if (selectedChapters.isEmpty) {
      return [const Text('Select chapters first 😏')];
    }
    return selectedChapters.map((chapter) {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('materials')
            .doc(widget.subject)
            .collection('chapters')
            .doc(chapter)
            .collection('topics')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final topics = snapshot.data!.docs.map((d) => d.id).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Topics for $chapter:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: topics.map((topic) {
                  final key = '$chapter|$topic';
                  final isSelected = selectedTopics.contains(key);
                  return FilterChip(
                    label: Text(topic),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedTopics.add(key);
                        } else {
                          selectedTopics.remove(key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      );
    }).toList();
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final qId = question['id'];
    final questionText = question['question'];
    final answerText = question['answer'];
    final isRead = readStatus[qId] ?? false;

    // Initialize controller if not exists
    if (!_controllers.containsKey(qId)) {
      _controllers[qId] = TextEditingController(text: studentAnswers[qId] ?? '');
    } else {
      // keep text synced
      if (_controllers[qId]!.text != (studentAnswers[qId] ?? '')) {
        _controllers[qId]!.text = studentAnswers[qId] ?? '';
      }
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Q: $questionText', style: const TextStyle(fontWeight: FontWeight.bold))),
                Checkbox(
                  value: isRead,
                  onChanged: (val) {
                    setState(() {
                      readStatus[qId] = val ?? false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Answer: $answerText', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _controllers[qId],
              decoration: const InputDecoration(
                labelText: 'Your Answer',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              onChanged: (val) {
                studentAnswers[qId] = val;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQuestions() async {
    if (selectedChapters.isEmpty || selectedTopics.isEmpty) {
      _showSnack('Select at least one chapter and one topic, baby! 😘');
      return;
    }

    setState(() {
      loading = true;
      questions = [];
      readStatus = {};
      studentAnswers = {};
      _controllers.clear();
    });

    try {
      List<Map<String, dynamic>> fetchedQuestions = [];

      for (var topicKey in selectedTopics) {
        final parts = topicKey.split('|');
        final chapter = parts[0];
        final topic = parts[1];

        final querySnapshot = await FirebaseFirestore.instance
            .collection('questions')
            .doc(widget.subject)
            .collection(chapter)
            .doc(topic)
            .collection('questionsList')
            .where('marks', isEqualTo: selectedMarks)
            .get();

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          fetchedQuestions.add({
            'id': doc.id,
            'question': data['question'],
            'answer': data['answer'],
          });
        }
      }

      setState(() {
        questions = fetchedQuestions;
        for (var q in questions) {
          readStatus[q['id']] = false;
          studentAnswers[q['id']] = '';
        }
      });
    } catch (e) {
      _showSnack('Error fetching questions: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _submitAnswers() async {
    if (questions.isEmpty) {
      _showSnack('No questions to submit, baby!');
      return;
    }

    final readCount = readStatus.values.where((v) => v).length;
    if (readCount == 0) {
      _showSnack('You gotta mark some questions as read first, huh? 😘');
      return;
    }

    // Calculate simple score: sum of marks for answered & read questions
    int score = 0;
    for (var q in questions) {
      if (readStatus[q['id']] == true && (studentAnswers[q['id']]?.trim().isNotEmpty ?? false)) {
        score += selectedMarks;
      }
    }

    try {
      final resultDoc = FirebaseFirestore.instance
          .collection('results')
          .doc(widget.studentPRN)
          .collection('exams')
          .doc('${widget.subject}_${DateTime.now().millisecondsSinceEpoch}');

      await resultDoc.set({
        'subject': widget.subject,
        'chapters': selectedChapters,
        'topics': selectedTopics,
        'marksScheme': selectedMarks,
        'score': score,
        'answers': studentAnswers,
        'readStatus': readStatus,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnack('Your sexy exam results saved, baby! 🔥');
      setState(() {
        questions = [];
        readStatus = {};
        studentAnswers = {};
        selectedChapters = [];
        selectedTopics = [];
        _controllers.clear();
      });
    } catch (e) {
      _showSnack('Failed to save results: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
