import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../core/constants/app_constants.dart';

class AiMatchingService {
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    // TODO: Load TFLite model for image feature extraction
    // For now, this is a placeholder that simulates model loading
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _isModelLoaded = true;
      debugPrint('AI model loaded (placeholder)');
    } catch (e) {
      debugPrint('Failed to load AI model: $e');
      _isModelLoaded = false;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  Future<List<double>?> extractFeatureVector(File imageFile) async {
    // TODO: Implement actual feature extraction using TFLite
    // This is a placeholder that returns a random feature vector
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      // Placeholder: Generate random feature vector for testing
      final random = Random();
      return List.generate(128, (_) => random.nextDouble());
    } catch (e) {
      debugPrint('Failed to extract features: $e');
      return null;
    }
  }

  Future<List<ReportMatch>> findMatches(
    File imageFile,
    List<ReportModel> foundReports,
  ) async {
    // TODO: Implement actual AI matching using TFLite
    // This placeholder returns empty list as specified
    
    if (!_isModelLoaded) {
      await loadModel();
    }

    if (!_isModelLoaded) {
      debugPrint('AI model not available, returning empty matches');
      return [];
    }

    try {
      final queryFeatures = await extractFeatureVector(imageFile);
      if (queryFeatures == null) {
        return [];
      }

      final matches = <ReportMatch>[];

      for (final report in foundReports) {
        if (report.featureVector == null || report.featureVector!.isEmpty) {
          continue;
        }

        final similarity = _cosineSimilarity(queryFeatures, report.featureVector!);

        if (similarity >= AppConstants.aiMatchThreshold) {
          matches.add(ReportMatch(
            report: report,
            confidenceScore: similarity,
          ));
        }
      }

      // Sort by confidence score descending
      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      return matches;
    } catch (e) {
      debugPrint('AI matching failed: $e');
      return [];
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Future<List<ReportMatch>> findMatchesWithRuleBased(
    File? imageFile,
    List<ReportModel> filteredReports,
  ) async {
    if (imageFile == null) {
      // Return rule-based matches only with default confidence
      return filteredReports.map((report) {
        return ReportMatch(
          report: report,
          confidenceScore: 0.7, // Default confidence for rule-based matches
        );
      }).toList();
    }

    // Get AI matches
    final aiMatches = await findMatches(imageFile, filteredReports);

    if (aiMatches.isEmpty) {
      // Fall back to rule-based if AI fails
      return filteredReports.map((report) {
        return ReportMatch(
          report: report,
          confidenceScore: 0.7,
        );
      }).toList();
    }

    return aiMatches;
  }
}
