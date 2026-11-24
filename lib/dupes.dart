import 'dart:io';
import 'package:crypto/crypto.dart';

const kDuplicates = 'Doublons';

Future<List<File>> findDuplicates(
  List<File> files, {
  void Function(int done, int total)? onProgress,
}) async {
  final bySize = <int, List<File>>{};
  for (final f in files) {
    try {
      bySize.putIfAbsent(await f.length(), () => []).add(f);
    } catch (_) {}
  }
  final groups = bySize.values.where((g) => g.length > 1).toList();
  final total = groups.fold<int>(0, (a, g) => a + g.length);
  var done = 0;
  final copies = <File>[];

  for (final g in groups) {
    final byHash = <String, List<File>>{};
    for (final f in g) {
      try {
        final h = (await md5.bind(f.openRead()).first).toString();
        byHash.putIfAbsent(h, () => []).add(f);
      } catch (_) {}
      done++;
      onProgress?.call(done, total);
    }
    for (final same in byHash.values) {
      if (same.length < 2) continue;
      final times = {for (final f in same) f.path: _mtime(f)};
      same.sort((a, b) {
        final c = times[a.path]!.compareTo(times[b.path]!);
        return c != 0 ? c : a.path.length.compareTo(b.path.length);
      });
      copies.addAll(same.skip(1));
    }
  }
  return copies;
}

DateTime _mtime(File f) {
  try {
    return f.lastModifiedSync();
  } catch (_) {
    return DateTime.now();
  }
}
