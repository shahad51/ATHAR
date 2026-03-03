import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';
import '../core/constants/app_constants.dart';

class AiMatchingService {
  static const String _modelPath = 'assets/models/image_embedding_model.tflite';
  static const int _inputSize = 224;
  static const int _featureSize = 1000; // EfficientNet-Lite0 output size

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    if (_isModelLoaded && _interpreter != null) return;

    try {
      debugPrint('🤖 [AI] Loading TFLite model...');
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isModelLoaded = true;
      debugPrint('🤖 [AI] Model loaded successfully!');
      debugPrint(
          '🤖 [AI] Input shape: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint(
          '🤖 [AI] Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      debugPrint('🤖 [AI] Failed to load model: $e');
      _isModelLoaded = false;
      _interpreter = null;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }

  Future<List<double>?> extractFeatureVector(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    if (_interpreter == null) {
      debugPrint('🤖 [AI] Model not available');
      return null;
    }

    try {
      debugPrint('🤖 [AI] Processing image: ${imageFile.path}');

      // Read and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        debugPrint('🤖 [AI] Failed to decode image');
        return null;
      }

      // Resize to model input size
      final resizedImage =
          img.copyResize(image, width: _inputSize, height: _inputSize);

      // Convert to normalized float array [0, 1]
      final input = _imageToFloatArray(resizedImage);

      // Prepare output buffer
      final output = List.filled(_featureSize, 0.0).reshape([1, _featureSize]);

      // Run inference
      _interpreter!.run(input, output);

      // Extract and normalize feature vector
      final features = List<double>.from(output[0]);
      final normalizedFeatures = _normalizeVector(features);

      debugPrint(
          '🤖 [AI] Feature extraction complete. Vector size: ${normalizedFeatures.length}');
      return normalizedFeatures;
    } catch (e) {
      debugPrint('🤖 [AI] Feature extraction failed: $e');
      return null;
    }
  }

  List<List<List<List<double>>>> _imageToFloatArray(img.Image image) {
    // Create input tensor [1, 224, 224, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // Normalize to [0, 1] - EfficientNet expects values in [0, 255] / 255
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  List<double> _normalizeVector(List<double> vector) {
    // L2 normalization for better similarity comparison
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = sqrt(norm);

    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  Future<List<ReportMatch>> findMatches(
    File imageFile,
    List<ReportModel> foundReports,
  ) async {
    debugPrint(
        '🤖 [AI] Finding matches for image against ${foundReports.length} reports');

    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
    }

    if (_interpreter == null) {
      debugPrint('🤖 [AI] Model not available, returning empty matches');
      return [];
    }

    try {
      final queryFeatures = await extractFeatureVector(imageFile);
      if (queryFeatures == null) {
        debugPrint('🤖 [AI] Failed to extract query features');
        return [];
      }

      final matches = <ReportMatch>[];

      for (final report in foundReports) {
        if (report.featureVector == null || report.featureVector!.isEmpty) {
          continue;
        }

        final similarity =
            _cosineSimilarity(queryFeatures, report.featureVector!);
        debugPrint(
            '🤖 [AI] Report ${report.reportId}: similarity = ${(similarity * 100).toStringAsFixed(1)}%');

        if (similarity >= AppConstants.aiMatchThreshold) {
          matches.add(ReportMatch(
            report: report,
            confidenceScore: similarity,
          ));
        }
      }

      // Sort by confidence score descending
      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
      debugPrint('🤖 [AI] Found ${matches.length} matches above threshold');

      return matches;
    } catch (e) {
      debugPrint('🤖 [AI] Matching failed: $e');
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
      // No image provided - return empty (user must provide image for AI matching)
      debugPrint('🤖 [AI] No image provided for matching');
      return [];
    }

    // Get AI matches - only return actual matches
    final aiMatches = await findMatches(imageFile, filteredReports);

    // Return only actual matches, don't fall back to showing all items
    debugPrint('🤖 [AI] Returning ${aiMatches.length} AI matches');
    return aiMatches;
  }
}
