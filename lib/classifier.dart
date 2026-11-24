import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'categories.dart';

class Classifier {
  final ImageLabeler _labeler =
      ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));

  Future<String> classify(File f) async {
    try {
      final labels =
          await _labeler.processImage(InputImage.fromFilePath(f.path));
      return pickCategory(labels.map((l) => MapEntry(l.label, l.confidence)));
    } catch (_) {
      return kToCheck;
    }
  }

  Future<void> close() => _labeler.close();
}
