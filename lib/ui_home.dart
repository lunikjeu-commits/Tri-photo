import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'ui_sort.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _granted = false;
  bool _includeChats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final ok = await Permission.manageExternalStorage.isGranted;
    if (mounted) setState(() => _granted = ok);
  }

  Future<void> _ask() async {
    await Permission.manageExternalStorage.request();
    await _check();
  }

  void _openSort() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SortScreen(includeChats: _includeChats)),
    );
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'Tri Photos',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Créé par lunikapp',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Tri Photos',
              style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
                onPressed: _about, icon: const Icon(Icons.info_outline_rounded)),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _statusCard(),
              const SizedBox(height: 12),
              _chatsOption(),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _granted ? _openSort : _ask,
                  icon: Icon(_granted
                      ? Icons.auto_awesome_rounded
                      : Icons.lock_open_rounded),
                  label: Text(_granted
                      ? 'Analyser mes photos'
                      : 'Autoriser l\'accès aux fichiers'),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Bientôt',
                  style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              const _Feature(Icons.lock_outline_rounded, 'Dossier privé',
                  'Masqué de la galerie, visible dans l\'app'),
              const _Feature(Icons.undo_rounded, 'Annuler le dernier tri',
                  'Remet les photos à leur place'),
              const _Feature(Icons.tune_rounded, 'Dossiers personnalisés',
                  'Tu choisis les catégories'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatsOption() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: _includeChats,
        onChanged: (v) => setState(() => _includeChats = v),
        title: const Text('Inclure WhatsApp et Telegram',
            style:
                TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        subtitle: const Text(
            'Attention : les photos déplacées disparaissent des conversations.',
            style: TextStyle(color: AppColors.textDim, fontSize: 13)),
      ),
    );
  }

  Widget _statusCard() {
    final color = _granted ? const Color(0xFF66D9A0) : AppColors.accent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(_granted ? Icons.check_circle_rounded : Icons.photo_library_rounded,
              color: color, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _granted
                  ? 'Accès autorisé. Prêt à trier tes photos.'
                  : 'Pour déplacer tes photos dans des dossiers, l\'app a besoin de l\'accès aux fichiers.',
              style: const TextStyle(color: AppColors.text, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x331B2440),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
