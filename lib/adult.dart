import 'dart:io';
import 'package:flutter_nsfw_detector/flutter_nsfw_detector.dart';

const kAdults = 'Adultes';
const double kAdultThreshold = 0.7; // plus haut = moins sensible

class AdultDetector {
  bool _ready = false;
  int errors = 0;
  String? lastError;

  bool get ready => _ready;

  Future<void> init() async {
    try {
      await FlutterNsfwDetector.initialize();
      _ready = true;
    } catch (e) {
      _ready = false;
      lastError = e.toString();
    }
  }

  Future<bool> isAdult(File f) async {
    if (!_ready) return false;
    try {
      final r = await FlutterNsfwDetector.scanImage(file: f);
      final score = (r.nsfwScore as num?) ?? 0;
      return score >= kAdultThreshold;
    } catch (e) {
      errors++;
      lastError ??= e.toString();
      return false;
    }
  }
}
