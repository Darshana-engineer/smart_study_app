import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiTester {
  static const String apiKey = 'AIzaSyDmH3HC500z7GcyEtkMrkTSmT37JmMwVZA';
  
  static Future<void> testAllEndpoints() async {
    final endpoints = [
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-002:generateContent",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-002:generateContent",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-001:generateContent",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-001:generateContent",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent",
    ];

    print("🧪 Testing all Gemini API endpoints...");
    
    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      print("\n🔄 Testing endpoint ${i + 1}: $endpoint");
      
      try {
        final url = Uri.parse("$endpoint?key=$apiKey");
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": "Say hello in one word."}
                ]
              }
            ]
          }),
        );
        
        print("📊 Status: ${response.statusCode}");
        if (response.statusCode == 200) {
          print("✅ SUCCESS! This endpoint works!");
          final data = json.decode(response.body);
          final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          print("📝 Response: $content");
          return; // Found working endpoint
        } else {
          print("❌ Failed: ${response.body}");
        }
      } catch (e) {
        print("❌ Error: $e");
      }
    }
    
    print("\n🔍 Testing API key validity...");
    await testApiKey();
  }
  
  static Future<void> testApiKey() async {
    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey");
      final response = await http.get(url);
      
      print("🔑 API Key Test - Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ API Key is valid!");
        print("📋 Available models:");
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
}
