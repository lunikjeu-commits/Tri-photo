import 'dart:convert';
import 'dart:io';
import 'adult.dart';
import 'scanner.dart';

class MoveResult {
  final int moved;
  final int failed;
  const MoveResult(this.moved, this.failed);
}

Future<MoveResult> moveAll(
  Map<String, List<File>> plan, {
  void Function(int done, int total)? onProgress,
}) async {
  await Directory(kOutputRoot).create(recursive: true);
  final sink =
      File('$kOutputRoot/.journal.jsonl').openWrite(mode: FileMode.append);
  final total = plan.values.fold<int>(0, (a, l) => a + l.length);
  int moved = 0, failed = 0, done = 0;

  for (final entry in plan.entries) {
    final dir = Directory('$kOutputRoot/${entry.key}');
    await dir.create(recursive: true);
    if (entry.key == kAdults) {
      await File('${dir.path}/.nomedia').create();
    }
    for (final f in entry.value) {
      try {
        final dest = _uniquePath(dir.path, f.path.split('/').last);
        await _move(f, dest);
        sink.writeln(jsonEncode({
          'from': f.path,
          'to': dest,
          't': DateTime.now().toIso8601String(),
        }));
        moved++;
      } catch (_) {
        failed++;
      }
      done++;
      onProgress?.call(done, total);
    }
  }
  await sink.flush();
  await sink.close();
  return MoveResult(moved, failed);
}

String _uniquePath(String dir, String name) {
  var path = '$dir/$name';
  if (!File(path).existsSync()) return path;
  final dot = name.lastIndexOf('.');
  final base = dot > 0 ? name.substring(0, dot) : name;
  final ext = dot > 0 ? name.substring(dot) : '';
  var i = 1;
  while (File(path).existsSync()) {
    path = '$dir/${base}_$i$ext';
    i++;
  }
  return path;
}

Future<void> _move(File src, String dest) async {
  try {
    await src.rename(dest);
  } on FileSystemException {
    final copy = await src.copy(dest);
    if (await copy.length() == await src.length()) {
      await src.delete();
    } else {
      await copy.delete();
      throw const FileSystemException('copie incomplète');
    }
  }
}
