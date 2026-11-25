import 'dart:io';
import 'package:flutter/foundation.dart';
import 'adult.dart';
import 'blur.dart';
import 'classifier.dart';
import 'dupes.dart';
import 'scanner.dart';
import 'thumb.dart';

enum SortStep { scanning, duplicates, analysing, results }

class _Item {
  final File file;
  final double score; // -1 si la photo n'a pas pu être lue
  final String fallback; // dossier si elle n'est pas « Adultes »
  const _Item(this.file, this.score, this.fallback);
}

class SortJob extends ChangeNotifier {
  final bool includeChats;
  SortJob({required this.includeChats});

  SortStep step = SortStep.scanning;
  int done = 0, total = 0;
  String? warning;
  double adultThreshold = kDefaultAdultThreshold;
  Map<String, List<File>> plan = {};

  bool _stop = false;
  bool _disposed = false;
  final List<_Item> _items = [];
  final List<File> _copies = [];
  final Map<String, String> _copyOf = {};
  final Map<String, double> _score = {};

  int get count => plan.values.fold(0, (a, l) => a + l.length);

  void stop() => _stop = true;

  void setThreshold(double v) {
    adultThreshold = v;
    _rebuild();
    _tick();
  }

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

  void _rebuild() {
    final out = <String, List<File>>{};
    for (final it in _items) {
      final cat = it.score >= adultThreshold ? kAdults : it.fallback;
      out.putIfAbsent(cat, () => []).add(it.file);
    }
    for (final c in _copies) {
      final orig = _copyOf[c.path];
      final adult = orig != null && (_score[orig] ?? -1) >= adultThreshold;
      out.putIfAbsent(adult ? kAdults : kDuplicates, () => []).add(c);
    }
    plan = out;
  }

  Future<void> run() async {
    final files = await scanImages(includeChats: includeChats);
    if (_disposed) return;

    _begin(SortStep.duplicates, files.length);
    final copyOf = await findDuplicates(files, onProgress: (d, t) {
      done = d;
      total = t;
      if (d % 10 == 0 || d == t) _tick();
    });
    if (_disposed) return;
    _copyOf.addAll(copyOf);
    _copies.addAll(files.where((f) => copyOf.containsKey(f.path)));
    final rest = files.where((f) => !copyOf.containsKey(f.path)).toList();

    _begin(SortStep.analysing, rest.length);
    final adult = AdultDetector();
    await adult.init();
    final clf = Classifier();
    for (final f in rest) {
      if (_stop || _disposed) break;
      final t = await loadThumb(f);
      double score = -1;
      final String fallback;
      if (t != null) {
        score = await adult.score(t) ?? -1;
        fallback = isBlurry(f.path, t) ? kBlurry : await clf.classify(f);
      } else {
        fallback = await clf.classify(f);
      }
      _score[f.path] = score;
      _items.add(_Item(f, score, fallback));
      done++;
      if (done % 5 == 0 || done == total) _tick();
    }
    await clf.close();
    final notes = _notes(adult, clf);
    adult.close();
    if (_disposed) return;
    warning = notes;
    _rebuild();
    step = SortStep.results;
    _tick();
  }

  String _cut(String s, int n) => s.length > n ? s.substring(0, n) : s;

  String? _notes(AdultDetector adult, Classifier clf) {
    final notes = <String>[];
    if (!adult.ready) {
      notes.add(
          'Détection « Adultes » indisponible : ${_cut(adult.lastError ?? '', 150)}');
    } else {
      final b = adult.bands;
      notes.add(
          'Scores « Adultes » : <0,2 : ${b[0]} · 0,2–0,35 : ${b[1]} · 0,35–0,5 : ${b[2]} · 0,5–0,7 : ${b[3]} · 0,7–0,9 : ${b[4]} · ≥0,9 : ${b[5]}');
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
