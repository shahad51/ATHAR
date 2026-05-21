import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBL9rPan1EJkqM5IrcsaHsberYtKQ6ZNQU';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-3-pro-image-preview',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, String>?> analyzeItemImage(File imageFile) async {
    try {
      debugPrint('🤖 [GeminiService] Starting image analysis...');

      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Analyze this image of a lost item and extract the following information in Arabic:

1. نوع الغرض (Item Type): What type of item is this? Choose from: Passport, Phone, Wallet, Bag, Clothing, Jewelry, Keys, Other
2. اللون (Color): What is the primary color of the item?
3. الوصف (Description): Provide a brief description of the item (2-3 sentences)

Respond ONLY in this exact JSON format (no markdown, no code blocks):
{
  "itemType": "type in English",
  "itemColor": "color in Arabic",
  "description": "description in Arabic"
}

Important:
- For itemType, use ONLY these English words: Passport, Phone, Wallet, Bag, Clothing, Jewelry, Keys, Other
- For itemColor, use Arabic color names
- For description, write in Arabic
- Return ONLY the JSON object, nothing else
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      debugPrint('🤖 [GeminiService] Sending request to Gemini...');
      final response = await _model.generateContent(content);

      if (response.text == null) {
        debugPrint('❌ [GeminiService] No response text from Gemini');
        return null;
      }

      debugPrint('🤖 [GeminiService] Response: ${response.text}');

      // Parse the JSON response
      final responseText = response.text!.trim();

      // Remove markdown code blocks if present
      String cleanedResponse = responseText;
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse =
            cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Try to extract JSON from the response
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        debugPrint('❌ [GeminiService] No valid JSON found in response');
        return null;
      }

      final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
      debugPrint('🤖 [GeminiService] Extracted JSON: $jsonString');

      // Manual JSON parsing (simple approach)
      final result = <String, String>{};

      // Extract itemType
      final itemTypeMatch =
          RegExp(r'"itemType"\s*:\s*"([^"]+)"').firstMatch(jsonString);
      if (itemTypeMatch != null) {
        result['itemType'] = itemTypeMatch.group(1)!;
      }

      // Extract itemColor
      final itemColorMatch =
          RegExp(r'"itemColor"\s*:\s*"([^"]+)"').firstMatch(jsonString);
      if (itemColorMatch != null) {
        result['itemColor'] = itemColorMatch.group(1)!;
      }

      // Extract description
      final descriptionMatch =
          RegExp(r'"description"\s*:\s*"([^"]+)"').firstMatch(jsonString);
      if (descriptionMatch != null) {
        result['description'] = descriptionMatch.group(1)!;
      }

      if (result.isEmpty) {
        debugPrint('❌ [GeminiService] Failed to parse JSON response');
        return null;
      }

      debugPrint('✅ [GeminiService] Successfully analyzed image');
      debugPrint('   Item Type: ${result['itemType']}');
      debugPrint('   Color: ${result['itemColor']}');
      debugPrint('   Description: ${result['description']}');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [GeminiService] Error analyzing image: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
