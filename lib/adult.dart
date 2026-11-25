import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'thumb.dart';

const kAdults = 'Adultes';
const double kDefaultAdultThreshold = 0.35; // plus bas = plus sensible

class AdultDetector {
  bool _ready = false;
  int errors = 0;
  String? lastError;
  double maxScore = 0;

  /// Répartition : <0,2 · 0,2–0,35 · 0,35–0,5 · 0,5–0,7 · 0,7–0,9 · ≥0,9
  final List<int> bands = List.filled(6, 0);

  bool get ready => _ready;

  Future<void> init() async {
    try {
      await NsfwDetector.initialize();
      _ready = true;
    } catch (e) {
      _ready = false;
      lastError = e.toString();
    }
  }

  /// Score de 0 à 1, ou null si la photo n'a pas pu être lue.
  Future<double?> score(Thumb t) async {
    if (!_ready) return null;
    try {
      final r = await NsfwDetector.instance.detectNSFWFromBytes(t.png);
      if (r == null) {
        errors++;
        lastError ??= 'image non décodée';
        return null;
      }
      final s = r.score;
      if (s > maxScore) maxScore = s;
      bands[_band(s)]++;
      return s;
    } catch (e) {
      errors++;
      lastError ??= e.toString();
      return null;
    }
  }

  int _band(double s) {
    if (s < 0.2) return 0;
    if (s < 0.35) return 1;
    if (s < 0.5) return 2;
    if (s < 0.7) return 3;
    if (s < 0.9) return 4;
    return 5;
  }

  void close() {
    if (_ready) NsfwDetector.disposeInstance();
  }
}
