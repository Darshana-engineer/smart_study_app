import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = 'AIzaSyDmH3HC500z7GcyEtkMrkTSmT37JmMwVZA'; // Replace with your actual Gemini API key
  
  // List of API endpoints to try in order (using ACTUAL available models from the list)
  final List<String> apiEndpoints = [
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-002:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-002:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-001:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-001:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent",
  ];

  // Test API key and list available models
  Future<void> testApiKey() async {
    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey");
      final response = await http.get(url);
      
      print("🔑 API Key Test - Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Available models:");
        if (data['models'] != null) {
          for (var model in data['models']) {
            print("  - ${model['name']}");
          }
        }
      } else {
        print("❌ API Key test failed: ${response.body}");
      }
    } catch (e) {
      print("❌ API Key test error: $e");
    }
  }

  // Simple test to verify API is working
  Future<bool> testSimpleGeneration() async {
    try {
      final testPrompt = "Say hello in one word.";
      final result = await _makeApiCall(apiEndpoints[0], testPrompt);
      return result.isNotEmpty;
    } catch (e) {
      print("❌ Simple generation test failed: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> generateQuestions({
    required String subject,
    required int selectedMarks,
  }) async {
    final prompt = '''
Generate exactly 5 question-answer pairs for the subject "$subject" worth $selectedMarks marks each.
Format strictly as:

Q1: <question>
Ans: <answer>

Q2: ...
Ans: ...

Only plain text. No explanation or intro.
''';
    
    return generateQuestionsWithCustomPrompt(
      prompt: prompt,
      subject: subject,
      selectedMarks: selectedMarks,
    );
  }

  Future<List<Map<String, dynamic>>> generateQuestionsWithCustomPrompt({
    required String prompt,
    required String subject,
    required int selectedMarks,
  }) async {
    print("🚀 Starting question generation with custom prompt");
    print("📝 Prompt: $prompt");
    
    // Try each endpoint until one works
    for (int i = 0; i < apiEndpoints.length; i++) {
      try {
        print("🔄 Trying endpoint ${i + 1}/${apiEndpoints.length}: ${apiEndpoints[i]}");
        final result = await _makeApiCall(apiEndpoints[i], prompt);
        if (result.isNotEmpty) {
          print("✅ Success with endpoint: ${apiEndpoints[i]}");
          return result;
        } else {
          print("⚠️ Endpoint ${i + 1} returned empty result");
        }
      } catch (e) {
        print("❌ Endpoint ${i + 1} failed: $e");
        if (i == apiEndpoints.length - 1) {
          // Last endpoint failed, rethrow the error
          print("💥 All endpoints failed!");
          rethrow;
        }
      }
    }
    print("❌ No working endpoints found");
    return [];
  }

  Future<List<Map<String, dynamic>>> _makeApiCall(String endpoint, String prompt) async {
    final url = Uri.parse("$endpoint?key=$apiKey");

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
      print("🌐 Making API request to: $url");
      print("📝 Request body: $body");
      
      final response = await http.post(url, headers: headers, body: body);
      
      print("📊 Response status: ${response.statusCode}");
      print("📄 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        print("✅ API Response parsed successfully");
        
        final content = resData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        print("📝 Generated content: $content");

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
            print("🔄 Using regex fallback for content parsing");
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
        } else {
          print("❌ No content found in API response");
        }
      } else {
        print("❌ Gemini API Error: ${response.statusCode} - ${response.body}");
        throw Exception("API Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception during Gemini API call: $e");
      throw Exception("API call failed: $e");
    }

    return [];
  }
}