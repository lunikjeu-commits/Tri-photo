import 'dart:io';
import 'package:flutter/foundation.dart';
import 'adult.dart';
import 'blur.dart';
import 'classifier.dart';
import 'dupes.dart';
import 'scanner.dart';
import 'thumb.dart';

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
      final t = await loadThumb(f);
      final String cat;
      if (t != null && await adult.isAdult(t)) {
        cat = kAdults;
      } else if (t != null && isBlurry(f.path, t)) {
        cat = kBlurry;
      } else {
        cat = await clf.classify(f);
      }
      plan.putIfAbsent(cat, () => []).add(f);
      done++;
      if (done % 5 == 0 || done == total) _tick();
    }
    await clf.close();
    final notes = _notes(adult, clf);
    adult.close();
    if (_disposed) return;
    warning = notes;
    step = SortStep.results;
    _tick();
  }

  String _cut(String s, int n) => s.length > n ? s.substring(0, n) : s;

  String? _notes(AdultDetector adult, Classifier clf) {
    final notes = <String>[];
    if (!adult.ready) {
      notes.add(
          'Détection « Adultes » indisponible : ${_cut(adult.lastError ?? '', 150)}');
    }
    if (adult.errors > 0) {
      notes.add(
          '${adult.errors} photos non lues (adultes). ${_cut(adult.lastError ?? '', 200)}');
    }
    if (clf.errors > 0) {
      notes.add(
          '${clf.errors} photos non lues (analyse). ${_cut(clf.lastError ?? '', 450)}');
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
