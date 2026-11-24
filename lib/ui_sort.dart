import 'dart:io';
import 'package:flutter/material.dart';
import 'adult.dart';
import 'blur.dart';
import 'categories.dart';
import 'dupes.dart';
import 'mover.dart';
import 'sorter.dart';
import 'theme.dart';

const _icons = <String, IconData>{
  'Voitures': Icons.directions_car_rounded,
  'Personnes': Icons.people_rounded,
  'Nourriture': Icons.restaurant_rounded,
  'Animaux': Icons.pets_rounded,
  'Paysages': Icons.landscape_rounded,
  'Documents': Icons.description_rounded,
  'Bâtiments': Icons.apartment_rounded,
  'Maison': Icons.chair_rounded,
  'Sport': Icons.sports_soccer_rounded,
  kToCheck: Icons.help_outline_rounded,
  kDuplicates: Icons.content_copy_rounded,
  kBlurry: Icons.blur_on_rounded,
  kAdults: Icons.visibility_off_rounded,
};

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

  Future<void> _confirmMove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Déplacer les photos ?'),
        content: Text(
            '$_selCount photos seront déplacées dans Pictures/LC_Tri. Un journal est conservé pour pouvoir annuler plus tard.'),
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
    if (_finished) return _finishedView();
    if (_moving) {
      return _progress('Déplacement $_mDone / $_mTotal',
          _mTotal == 0 ? null : _mDone / _mTotal, false);
    }
    return switch (_job.step) {
      SortStep.scanning => _progress('Recherche des photos…', null, false),
      SortStep.duplicates =>
        _progress('Recherche des doublons…', _ratio, false),
      SortStep.analysing =>
        _progress('Analyse ${_job.done} / ${_job.total}', _ratio, true),
      SortStep.results => _results(),
    };
  }

  Widget _progress(String text, double? value, bool canStop) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: value, minHeight: 8),
          const SizedBox(height: 20),
          Text(text,
              style: const TextStyle(color: AppColors.text, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Laisse l\'écran allumé',
              style: TextStyle(color: AppColors.textDim)),
          if (canStop) ...[
            const SizedBox(height: 24),
            OutlinedButton(
                onPressed: _job.stop,
                child: const Text('Arrêter et voir le résultat')),
          ],
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
        const SizedBox(height: 14),
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
        Icon(_icons[name] ?? Icons.folder_rounded,
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

  Widget _finishedView() {
    final r = _result;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF66D9A0), size: 64),
          const SizedBox(height: 16),
          Text('${r?.moved ?? 0} photos déplacées',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Dossier : Pictures/LC_Tri',
              style: TextStyle(color: AppColors.textDim)),
          if ((r?.failed ?? 0) > 0)
            Text('${r!.failed} non déplacées',
                style: const TextStyle(color: Color(0xFFFFB74D))),
          const SizedBox(height: 8),
          const Text('La galerie peut mettre un moment à se mettre à jour.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Terminer')),
        ],
      ),
    );
  }
}
