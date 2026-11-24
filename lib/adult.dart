import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'thumb.dart';

const kAdults = 'Adultes';
const double kAdultThreshold = 0.7; // plus bas = plus sensible

class AdultDetector {
  bool _ready = false;
  int errors = 0;
  String? lastError;

  bool get ready => _ready;

  Future<void> init() async {
    try {
      await NsfwDetector.initialize(threshold: kAdultThreshold);
      _ready = true;
    } catch (e) {
      _ready = false;
      lastError = e.toString();
    }
  }

  Future<bool> isAdult(Thumb t) async {
    if (!_ready) return false;
    try {
      final r = await NsfwDetector.instance.detectNSFWFromBytes(t.png);
      if (r == null) {
        errors++;
        lastError ??= 'image non décodée';
        return false;
      }
      return r.isNsfw;
    } catch (e) {
      errors++;
      lastError ??= e.toString();
      return false;
    }
  }

  void close() {
    if (_ready) NsfwDetector.disposeInstance();
  }
}
