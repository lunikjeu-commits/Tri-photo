import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'categories.dart';

class Classifier {
  final ImageLabeler _labeler =
      ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.3));

  int errors = 0;
  String? lastError;
  final Map<String, int> unmatched = {};

  Future<String> classify(File f) async {
    try {
      final labels =
          await _labeler.processImage(InputImage.fromFilePath(f.path));
      final pairs =
          labels.map((l) => MapEntry(l.label, l.confidence)).toList();
      final cat = pickCategory(pairs);
      if (cat == kToCheck) {
        for (final p in pairs) {
          unmatched[p.key] = (unmatched[p.key] ?? 0) + 1;
        }
      }
      return cat;
    } catch (e) {
      errors++;
      lastError ??= e.toString();
      return kToCheck;
    }
  }

  Future<void> close() => _labeler.close();
}
