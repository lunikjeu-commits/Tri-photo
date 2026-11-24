import 'dart:io';
import 'package:flutter/foundation.dart';
import 'adult.dart';
import 'blur.dart';
import 'classifier.dart';
import 'dupes.dart';
import 'scanner.dart';

enum SortStep { scanning, duplicates, analysing, results }

class SortJob extends ChangeNotifier {
  final bool includeChats;
  SortJob({required this.includeChats});

  SortStep step = SortStep.scanning;
  int done = 0, total = 0;
  String? warning;
  bool _stop = false;
  bool _disposed = false;
  final Map<String, List<File>> plan = {};

  int get count => plan.values.fold(0, (a, l) => a + l.length);

  void stop() => _stop = true;

  @override
  void dispose() {
    _stop = true;
    _disposed = true;
    super.dispose();
  }

  void _tick() {
    if (!_disposed) notifyListeners();
  }

  void _begin(SortStep s, int t) {
    step = s;
    done = 0;
    total = t;
    _tick();
  }

  Future<void> run() async {
    final files = await scanImages(includeChats: includeChats);
    if (_disposed) return;

    _begin(SortStep.duplicates, files.length);
    final copies = await findDuplicates(files, onProgress: (d, t) {
      done = d;
      total = t;
      if (d % 10 == 0 || d == t) _tick();
    });
    if (_disposed) return;
    if (copies.isNotEmpty) plan[kDuplicates] = copies;
    final copySet = copies.map((f) => f.path).toSet();
    final rest = files.where((f) => !copySet.contains(f.path)).toList();

    _begin(SortStep.analysing, rest.length);
    final adult = AdultDetector();
    await adult.init();
    if (!adult.ready) {
      warning =
          'Détection « Adultes » indisponible : ces photos sont rangées par contenu.';
    }
    final clf = Classifier();
    for (final f in rest) {
      if (_stop || _disposed) break;
      final String cat;
      if (await adult.isAdult(f)) {
        cat = kAdults;
      } else if (await isBlurry(f)) {
        cat = kBlurry;
      } else {
        cat = await clf.classify(f);
      }
      plan.putIfAbsent(cat, () => []).add(f);
      done++;
      if (done % 5 == 0 || done == total) _tick();
    }
    await clf.close();
    if (_disposed) return;
    step = SortStep.results;
    _tick();
  }
}
