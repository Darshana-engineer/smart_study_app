import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  // User authentication and management
  static Future<Map<String, dynamic>?> getUserByPRN(String prn) async {
    try {
      final doc = await _firestore.collection('users').doc(prn).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  static Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userData['prn']).set(userData);
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<void> updateUser(String prn, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(prn).update(updates);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Material management
  static Future<void> saveMaterialLink({
    required String subject,
    required String chapter,
    required String materialType,
    required String url,
  }) async {
    try {
      final docRef = _firestore
          .collection('materials')
          .doc(subject)
          .collection('chapters')
          .doc(chapter);

      final Map<String, dynamic> dataToSave = {
        'timestamp': FieldValue.serverTimestamp(),
      };

      switch (materialType) {
        case 'Notes':
          dataToSave['notesUrl'] = url;
          break;
        case 'Syllabus':
          dataToSave['syllabusUrl'] = url;
          break;
        case 'Question Bank':
          dataToSave['questionBankUrl'] = url;
          break;
      }

      await docRef.set(dataToSave, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving material: $e');
    }
  }

  static Future<QuerySnapshot> getChapters(String subject) async {
    try {
      return await _firestore
          .collection('materials')
          .doc(subject)
          .collection('chapters')
          .get();
    } catch (e) {
      throw Exception('Error fetching chapters: $e');
    }
  }

  static Future<DocumentSnapshot> getChapterData(String subject, String chapter) async {
    try {
      return await _firestore
          .collection('materials')
          .doc(subject)
          .collection('chapters')
          .doc(chapter)
          .get();
    } catch (e) {
      throw Exception('Error fetching chapter data: $e');
    }
  }

  // Database operations for exam questions
  static Future<DatabaseEvent> getChaptersFromDatabase(String subject) async {
    try {
      return await _database.ref('materials/$subject/chapters').once();
    } catch (e) {
      throw Exception('Error fetching chapters from database: $e');
    }
  }

  static Future<DatabaseEvent> getTopicsFromDatabase(String subject, String chapter) async {
    try {
      return await _database.ref('materials/$subject/chapters/$chapter/topics').once();
    } catch (e) {
      throw Exception('Error fetching topics from database: $e');
    }
  }

  static Future<DatabaseEvent> getQuestionsFromDatabase({
    required String subject,
    required String chapter,
    required String topic,
    required int marks,
  }) async {
    try {
      return await _database
          .ref('questions/$subject/$chapter/$topic')
          .orderByChild('marks')
          .equalTo(marks)
          .once();
    } catch (e) {
      throw Exception('Error fetching questions from database: $e');
    }
  }

  // Gemini AI API integration
  static Future<List<Map<String, dynamic>>> generateQuestionsWithGemini({
    required String subject,
    required int selectedMarks,
  }) async {
    const String apiKey = 'AIzaSyDmH3HC500z7GcyEtkMrkTSmT37JmMwVZA';
    
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-002:generateContent?key=$apiKey",
    );

    final prompt = '''
Generate exactly 5 question-answer pairs for the subject "$subject" worth $selectedMarks marks each.
Format strictly as:

Q1: <question>
Ans: <answer>

Q2: ...
Ans: ...

Only plain text. No explanation or intro.
''';

    final headers = {
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
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
          } catch (_) {
            final regex = RegExp(
              r"Q\d+[:\-\.]?\s*(.*?)\s*Ans[:\-\.]?\s*(.*?)(?=(?:Q\d+[:\-\.]|$))",
              dotAll: true,
            );
            final matches = regex.allMatches(content);

            return matches.map((m) {
              final question = m.group(1)?.trim() ?? '';
              final answer = m.group(2)?.trim() ?? '';
              return {
                'id': 'gemini_fallback_${m.start}',
                'question': question,
                'answer': answer,
              };
            }).where((q) => q['question']!.isNotEmpty && q['answer']!.isNotEmpty).toList();
          }
        }
      } else {
        throw Exception("Gemini API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Exception during Gemini API call: $e");
    }

    return [];
  }
}
