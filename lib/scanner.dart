import 'dart:io';

const kOutputRoot = '/storage/emulated/0/Pictures/LC_Tri';

const _base = '/storage/emulated/0';
const _roots = ['$_base/DCIM', '$_base/Pictures', '$_base/Download'];

// Option « Inclure Telegram » (WhatsApp n'est jamais analysé).
const _telegramRoots = [
  '$_base/Telegram',
  '$_base/Android/media/org.telegram.messenger/Telegram',
  '$_base/Android/media/org.telegram.messenger.web/Telegram',
];
const _exts = [
  '.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.gif', '.bmp',
];

Future<List<File>> scanImages({bool includeChats = false}) async {
  final out = <File>[];
  for (final r in [..._roots, if (includeChats) ..._telegramRoots]) {
    await _walk(Directory(r), out);
  }
  // Les plus récentes d'abord (utile si tu arrêtes l'analyse en route).
  final times = <String, int>{};
  for (final f in out) {
    try {
      times[f.path] = f.lastModifiedSync().millisecondsSinceEpoch;
    } catch (_) {
      times[f.path] = 0;
    }
  }
  out.sort((a, b) => times[b.path]!.compareTo(times[a.path]!));
  return out;
}

Future<void> _walk(Directory d, List<File> out) async {
  try {
    await for (final e in d.list(followLinks: false)) {
      final name = e.path.split('/').last;
      if (name.startsWith('.')) continue;
      if (e is Directory) {
        if (e.path == kOutputRoot) continue;
        final low = name.toLowerCase();
        if (low.contains('sticker') || low.contains('whatsapp')) continue;
        await _walk(e, out);
      } else if (e is File) {
        final low = name.toLowerCase();
        if (_exts.any(low.endsWith)) out.add(e);
      }
    }
  } catch (_) {}
}
