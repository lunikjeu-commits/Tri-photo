import 'dart:io';

const kAdults = 'Adultes';

/// Version temporaire : le détecteur est en cours de remplacement.
class AdultDetector {
  bool get ready => false;
  int errors = 0;
  String? lastError = 'détecteur retiré temporairement';

  Future<void> init() async {}

  Future<bool> isAdult(File f) async => false;
}
