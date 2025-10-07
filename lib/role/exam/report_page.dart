import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  final String prn;
  final String subject;
  final String date;
  final int totalQuestions;
  final int correctAnswers;
  final int marksPerQuestion;
  final int totalMarksScored;
  final List<Map<String, dynamic>> questions;

  const ReportPage({
    super.key,
    required this.prn,
    required this.subject,
    required this.date,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.marksPerQuestion,
    required this.totalMarksScored,
    required this.questions,
  });

  bool isAnswerCorrect(String correctAns, String studentAns) {
    final correctWords = correctAns.split(RegExp(r'\s+')).map((w) => w.toLowerCase()).toList();
    final studentWords = studentAns.split(RegExp(r'\s+')).map((w) => w.toLowerCase()).toList();
    int matchCount = correctWords.where((word) => studentWords.contains(word)).length;
    double matchPercent = (matchCount / correctWords.length) * 100;
    return matchPercent >= 60;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PRN: $prn", style: const TextStyle(fontSize: 16)),
              Text("Subject: $subject", style: const TextStyle(fontSize: 16)),
              Text("Date: $date", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text("Total Questions: $totalQuestions"),
              Text("Correct Answers: $correctAnswers"),
              Text("Marks per Question: $marksPerQuestion"),
              Text("Total Marks Scored: $totalMarksScored"),
              const Divider(height: 30),
              const Text(
                "Question-wise Breakdown:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...questions.map((q) {
                final studentAns = (q['studentAnswer'] ?? '').toString().trim();
                final correctAns = (q['correctAnswer'] ?? '').toString().trim();
                final isCorrect = isAnswerCorrect(correctAns, studentAns);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Q: ${q['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("Your Answer: $studentAns"),
                        Text("Correct Answer: $correctAns"),
                        Text(
                          isCorrect ? "Status: ✅ Correct" : "Status: ❌ Incorrect",
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
