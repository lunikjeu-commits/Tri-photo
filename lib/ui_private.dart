import 'dart:io';
import 'package:flutter/material.dart';
import 'adult.dart';
import 'scanner.dart';
import 'theme.dart';

const _dir = '$kOutputRoot/$kAdults';
const _exts = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.gif', '.bmp'];

class PrivateScreen extends StatefulWidget {
  const PrivateScreen({super.key});

  @override
  State<PrivateScreen> createState() => _PrivateScreenState();
}

class _PrivateScreenState extends State<PrivateScreen> {
  List<File> _files = [];
  bool _loading = true;
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final out = <File>[];
    try {
      final d = Directory(_dir);
      if (await d.exists()) {
        await for (final e in d.list()) {
          final low = e.path.toLowerCase();
          if (e is File && _exts.any(low.endsWith)) out.add(e);
        }
      }
    } catch (_) {}
    out.sort((a, b) => b.path.compareTo(a.path));
    final hidden = File('$_dir/.nomedia').existsSync();
    if (mounted) {
      setState(() {
        _files = out;
        _hidden = hidden;
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    final f = File('$_dir/.nomedia');
    try {
      if (_hidden) {
        await f.delete();
      } else {
        await f.create(recursive: true);
      }
      setState(() => _hidden = !_hidden);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_hidden
            ? 'Dossier masqué. La galerie se met à jour au prochain rafraîchissement.'
            : 'Dossier visible. La galerie peut mettre un moment à l\'afficher.'),
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Dossier privé')),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(_hidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                      color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        _hidden
                            ? 'Masqué de la galerie'
                            : 'Visible dans la galerie',
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                      onPressed: _toggle,
                      child: Text(_hidden ? 'Rendre visible' : 'Masquer')),
                ]),
              ),
              Expanded(child: _grid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_files.isEmpty) {
      return const Center(
          child: Text('Aucune photo dans ce dossier.',
              style: TextStyle(color: AppColors.textDim)));
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: _files.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _Viewer(_files, i)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_files[i],
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppColors.surface,
                  child: Icon(Icons.broken_image_rounded,
                      color: AppColors.textDim))),
        ),
      ),
    );
  }
}

class _Viewer extends StatefulWidget {
  final List<File> files;
  final int start;
  const _Viewer(this.files, this.start);

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final PageController _pc = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${_i + 1} / ${widget.files.length}'),
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.file(widget.files[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textDim)),
          ),
        ),
      ),
    );
  }
}
