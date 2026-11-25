import 'dart:io';
import 'package:flutter/material.dart';
import 'adult.dart';
import 'categories.dart';
import 'folder_icons.dart';
import 'mover.dart';
import 'sort_views.dart';
import 'sorter.dart';
import 'theme.dart';

class SortScreen extends StatefulWidget {
  final bool includeChats;
  const SortScreen({super.key, this.includeChats = false});

  @override
  State<SortScreen> createState() => _SortScreenState();
}

class _SortScreenState extends State<SortScreen> {
  late final SortJob _job;
  final Set<String> _excluded = {};
  bool _moving = false;
  bool _finished = false;
  int _mDone = 0, _mTotal = 0;
  MoveResult? _result;

  @override
  void initState() {
    super.initState();
    _job = SortJob(includeChats: widget.includeChats)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _job.run();
  }

  @override
  void dispose() {
    _job.dispose();
    super.dispose();
  }

  Map<String, List<File>> get _selected => {
        for (final e in _job.plan.entries)
          if (!_excluded.contains(e.key)) e.key: e.value
      };

  int get _selCount => _selected.values.fold(0, (a, l) => a + l.length);

  double? get _ratio => _job.total == 0 ? null : _job.done / _job.total;

  bool get _allOn => _excluded.isEmpty;

  void _toggleAll() {
    setState(() {
      if (_allOn) {
        _excluded.addAll(_job.plan.keys);
      } else {
        _excluded.clear();
      }
    });
  }

  Future<void> _confirmMove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Déplacer les photos ?'),
        content: Text(
            '$_selCount photos seront déplacées dans Pictures/LC_Tri. Tu pourras annuler ce tri depuis l\'historique.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Déplacer')),
        ],
      ),
    );
    if (ok != true) return;
    final sel = _selected;
    setState(() {
      _moving = true;
      _mDone = 0;
      _mTotal = _selCount;
    });
    final r = await moveAll(sel, onProgress: (d, t) {
      if (mounted && (d % 5 == 0 || d == t)) {
        setState(() {
          _mDone = d;
          _mTotal = t;
        });
      }
    });
    if (mounted) {
      setState(() {
        _result = r;
        _moving = false;
        _finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Tri des photos')),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(20), child: _body()),
        ),
      ),
    );
  }

  Widget _body() {
    if (_finished) return FinishedView(result: _result);
    if (_moving) {
      return ProgressView(
          text: 'Déplacement $_mDone / $_mTotal',
          value: _mTotal == 0 ? null : _mDone / _mTotal);
    }
    return switch (_job.step) {
      SortStep.scanning => const ProgressView(text: 'Recherche des photos…'),
      SortStep.duplicates =>
        ProgressView(text: 'Recherche des doublons…', value: _ratio),
      SortStep.analysing => ProgressView(
          text: 'Analyse ${_job.done} / ${_job.total}',
          value: _ratio,
          onStop: _job.stop),
      SortStep.results => _results(),
    };
  }

  Widget _sensitivity() {
    final n = _job.plan[kAdults]?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Sensibilité « Adultes » : seuil ${_job.adultThreshold.toStringAsFixed(2)} → $n photos',
              style: const TextStyle(
                  color: AppColors.text, fontWeight: FontWeight.w600)),
          Slider(
            value: _job.adultThreshold,
            min: 0.05,
            max: 0.95,
            divisions: 90,
            onChanged: (v) => _job.setThreshold(v),
          ),
          const Text('Plus bas = plus de photos classées Adultes',
              style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _results() {
    if (_job.count == 0) {
      return const Center(
          child: Text('Aucune photo trouvée.',
              style: TextStyle(color: AppColors.text)));
    }
    final entries = _job.plan.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Column(
      children: [
        Text('${_job.count} photos analysées',
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Désactive un dossier pour ne pas déplacer ses photos',
            style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        if (_job.warning != null) ...[
          const SizedBox(height: 6),
          Text(_job.warning!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 13)),
        ],
        _sensitivity(),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _toggleAll,
            icon: Icon(_allOn
                ? Icons.check_box_outline_blank_rounded
                : Icons.check_box_rounded),
            label: Text(_allOn ? 'Tout décocher' : 'Tout cocher'),
          ),
        ),
        Expanded(
          child: ListView(
            children: [for (final e in entries) _row(e.key, e.value.length)],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _selCount == 0 ? null : _confirmMove,
            icon: const Icon(Icons.drive_file_move_rounded),
            label: Text('Déplacer $_selCount photos'),
          ),
        ),
      ],
    );
  }

  Widget _row(String name, int n) {
    final on = !_excluded.contains(name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(iconForFolder(name),
            color: name == kToCheck
                ? const Color(0xFFFFB74D)
                : (on ? AppColors.accent : AppColors.textDim)),
        const SizedBox(width: 14),
        Expanded(
            child: Text(name,
                style: TextStyle(
                    color: on ? AppColors.text : AppColors.textDim,
                    fontWeight: FontWeight.w600))),
        Text('$n',
            style: const TextStyle(color: AppColors.textDim, fontSize: 16)),
        Switch(
          value: on,
          onChanged: (v) => setState(() {
            v ? _excluded.remove(name) : _excluded.add(name);
          }),
        ),
      ]),
    );
  }
}
