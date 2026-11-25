import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'ui_history.dart';
import 'ui_private.dart';
import 'ui_sort.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _granted = false;
  bool _includeChats = false; // = inclure Telegram

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

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
                  onPressed: _granted
                      ? () => _go(SortScreen(includeChats: _includeChats))
                      : _ask,
                  icon: Icon(_granted
                      ? Icons.auto_awesome_rounded
                      : Icons.lock_open_rounded),
                  label: Text(_granted
                      ? 'Analyser mes photos'
                      : 'Autoriser l\'accès aux fichiers'),
                ),
              ),
              const SizedBox(height: 20),
              if (_granted) ...[
                _Feature(Icons.visibility_off_rounded, 'Dossier privé',
                    'Voir le dossier « Adultes » (masqué de la galerie)',
                    onTap: () => _go(const PrivateScreen())),
                _Feature(Icons.undo_rounded, 'Historique et annulation',
                    'Annuler un tri : les photos reviennent à leur place',
                    onTap: () => _go(const HistoryScreen())),
              ],
              const SizedBox(height: 18),
              const Text('Bientôt',
                  style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
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
        title: const Text('Inclure Telegram',
            style:
                TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        subtitle: const Text(
            'Les photos déplacées disparaissent des conversations (Telegram les retélécharge en général).',
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
  final VoidCallback? onTap;
  const _Feature(this.icon, this.title, this.subtitle, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0x331B2440) : AppColors.surface,
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
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}
