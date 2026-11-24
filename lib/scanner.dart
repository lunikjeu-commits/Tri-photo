import 'dart:io';

const kOutputRoot = '/storage/emulated/0/Pictures/LC_Tri';

const _base = '/storage/emulated/0';
const _roots = ['$_base/DCIM', '$_base/Pictures', '$_base/Download'];
const _chatRoots = [
  '$_base/Android/media/com.whatsapp/WhatsApp/Media',
  '$_base/Android/media/com.whatsapp.w4b/WhatsApp Business/Media',
  '$_base/WhatsApp/Media',
  '$_base/Telegram',
];
const _exts = [
  '.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.gif', '.bmp',
];

Future<List<File>> scanImages({bool includeChats = false}) async {
  final out = <File>[];
  for (final r in [..._roots, if (includeChats) ..._chatRoots]) {
    await _walk(Directory(r), out);
  }
  return out;
}

Future<void> _walk(Directory d, List<File> out) async {
  try {
    await for (final e in d.list(followLinks: false)) {
      final name = e.path.split('/').last;
      if (name.startsWith('.')) continue;
      if (e is Directory) {
        if (e.path == kOutputRoot) continue;
        if (name.toLowerCase().contains('sticker')) continue;
        await _walk(e, out);
      } else if (e is File) {
        final low = name.toLowerCase();
        if (_exts.any(low.endsWith)) out.add(e);
      }
    }
  } catch (_) {}
}
