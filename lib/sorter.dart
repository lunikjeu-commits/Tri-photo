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
    warning = _notes(adult, clf);
    step = SortStep.results;
    _tick();
  }

  String? _notes(AdultDetector adult, Classifier clf) {
    final notes = <String>[];
    if (!adult.ready) {
      notes.add(
          'Détection « Adultes » indisponible : ces photos sont rangées par contenu.');
    }
    if (clf.errors > 0) {
      final e = clf.lastError ?? '';
      final short = e.length > 80 ? e.substring(0, 80) : e;
      notes.add('${clf.errors} photos non lues par l\'analyse. $short');
    }
    final top = clf.unmatched.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (top.isNotEmpty) {
      final list = top.take(15).map((e) => '${e.key} (${e.value})').join(', ');
      notes.add('Étiquettes vues dans « À vérifier » : $list');
    }
    return notes.isEmpty ? null : notes.join('\n');
  }
}
