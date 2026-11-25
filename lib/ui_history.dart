import 'package:flutter/material.dart';
import 'theme.dart';
import 'undo.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _fmt(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} à ${_two(d.hour)}:${_two(d.minute)}';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RunInfo> _runs = [];
  bool _loading = true;
  bool _busy = false;
  int _done = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await listRuns();
    if (mounted) {
      setState(() {
        _runs = r;
        _loading = false;
      });
    }
  }

  Future<void> _undo(RunInfo run) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Annuler ce tri ?'),
        content: Text(
            '${run.count} photos retourneront à leur emplacement d\'origine.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Non')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Annuler le tri')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _done = 0;
      _total = run.count;
    });
    final r = await undoRun(run, onProgress: (d, t) {
      if (mounted && (d % 5 == 0 || d == t)) {
        setState(() {
          _done = d;
          _total = t;
        });
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    var msg = '${r.restored} photos remises en place';
    if (r.missing > 0) msg += ', ${r.missing} introuvables';
    if (r.failed > 0) msg += ', ${r.failed} en échec';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Historique des tris')),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_busy) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                  value: _total == 0 ? null : _done / _total, minHeight: 8),
              const SizedBox(height: 20),
              Text('Annulation $_done / $_total',
                  style: const TextStyle(color: AppColors.text)),
            ],
          ),
        ),
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_runs.isEmpty) {
      return const Center(
          child: Text('Aucun tri enregistré.',
              style: TextStyle(color: AppColors.textDim)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _runs.length,
      itemBuilder: (_, i) => _card(_runs[i], i == 0 && !_runs[i].legacy),
    );
  }

  Widget _card(RunInfo run, bool latest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(run.legacy ? Icons.history_rounded : Icons.drive_file_move_rounded,
            color: AppColors.accent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  run.legacy
                      ? 'Anciens tris (avant la mise à jour)'
                      : (latest ? 'Dernier tri' : 'Tri'),
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${_fmt(run.when)} · ${run.count} photos',
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 13)),
            ],
          ),
        ),
        OutlinedButton(
            onPressed: () => _undo(run), child: const Text('Annuler')),
      ]),
    );
  }
}
