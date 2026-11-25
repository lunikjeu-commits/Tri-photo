import 'package:flutter/material.dart';
import 'mover.dart';
import 'theme.dart';

class ProgressView extends StatelessWidget {
  final String text;
  final double? value;
  final VoidCallback? onStop;
  const ProgressView({super.key, required this.text, this.value, this.onStop});

  @override
  Widget build(BuildContext context) {
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
          if (onStop != null) ...[
            const SizedBox(height: 24),
            OutlinedButton(
                onPressed: onStop,
                child: const Text('Arrêter et voir le résultat')),
          ],
        ],
      ),
    );
  }
}

class FinishedView extends StatelessWidget {
  final MoveResult? result;
  const FinishedView({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
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
          const Text(
              'La galerie est rafraîchie. Tu peux annuler ce tri depuis l\'historique.',
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
