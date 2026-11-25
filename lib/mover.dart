import 'dart:convert';
import 'dart:io';
import 'adult.dart';
import 'fs_utils.dart';
import 'media_scan.dart';
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
  final jdir = Directory('$kOutputRoot/.journals');
  await jdir.create(recursive: true);
  final journal =
      File('${jdir.path}/run_${DateTime.now().millisecondsSinceEpoch}.jsonl');
  final sink = journal.openWrite();
  final total = plan.values.fold<int>(0, (a, l) => a + l.length);
  final touched = <String>[];
  int moved = 0, failed = 0, done = 0;

  for (final entry in plan.entries) {
    final dir = Directory('$kOutputRoot/${entry.key}');
    await dir.create(recursive: true);
    if (entry.key == kAdults) {
      await File('${dir.path}/.nomedia').create();
    }
    for (final f in entry.value) {
      try {
        final dest = uniquePath(dir.path, f.path.split('/').last);
        await moveFile(f, dest);
        sink.writeln(jsonEncode({'from': f.path, 'to': dest}));
        touched.add(f.path);
        touched.add(dest);
        moved++;
      } catch (_) {
        failed++;
      }
      done++;
      if (done % 25 == 0) await sink.flush();
      onProgress?.call(done, total);
    }
  }
  await sink.flush();
  await sink.close();
  if (moved == 0) {
    try {
      await journal.delete();
    } catch (_) {}
  }
  await rescanGallery(touched);
  return MoveResult(moved, failed);
}
