import 'dart:convert';
import 'dart:io';
import 'fs_utils.dart';
import 'media_scan.dart';
import 'scanner.dart';

class RunInfo {
  final File file;
  final DateTime when;
  final int count;
  final bool legacy;
  const RunInfo(this.file, this.when, this.count, this.legacy);
}

class UndoResult {
  final int restored;
  final int missing;
  final int failed;
  const UndoResult(this.restored, this.missing, this.failed);
}

Future<List<RunInfo>> listRuns() async {
  final out = <RunInfo>[];
  try {
    final dir = Directory('$kOutputRoot/.journals');
    if (await dir.exists()) {
      await for (final e in dir.list()) {
        if (e is File && e.path.endsWith('.jsonl')) {
          final info = await _info(e, false);
          if (info != null) out.add(info);
        }
      }
    }
    final legacy = File('$kOutputRoot/.journal.jsonl');
    if (await legacy.exists()) {
      final info = await _info(legacy, true);
      if (info != null) out.add(info);
    }
  } catch (_) {}
  out.sort((a, b) => b.when.compareTo(a.when));
  return out;
}

Future<RunInfo?> _info(File f, bool legacy) async {
  try {
    final n = (await _readEntries(f)).length;
    if (n == 0) return null;
    var when = await f.lastModified();
    final m = RegExp(r'run_(\d+)\.jsonl$').firstMatch(f.path);
    if (m != null) {
      when = DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(1)!));
    }
    return RunInfo(f, when, n, legacy);
  } catch (_) {
    return null;
  }
}

Future<List<Map<String, dynamic>>> _readEntries(File f) async {
  final out = <Map<String, dynamic>>[];
  for (final l in await f.readAsLines()) {
    if (l.trim().isEmpty) continue;
    try {
      final m = jsonDecode(l);
      if (m is Map<String, dynamic> && m['from'] is String && m['to'] is String) {
        out.add(m);
      }
    } catch (_) {}
  }
  return out;
}

Future<UndoResult> undoRun(
  RunInfo run, {
  void Function(int done, int total)? onProgress,
}) async {
  final entries = await _readEntries(run.file);
  int restored = 0, missing = 0, done = 0;
  final failed = <Map<String, dynamic>>[];
  final touched = <String>[];

  for (final e in entries.reversed) {
    final from = e['from'] as String;
    final to = e['to'] as String;
    try {
      final src = File(to);
      if (!await src.exists()) {
        missing++;
      } else {
        final slash = from.lastIndexOf('/');
        final dir = from.substring(0, slash);
        await Directory(dir).create(recursive: true);
        final dest = uniquePath(dir, from.substring(slash + 1));
        await moveFile(src, dest);
        restored++;
        touched.add(to);
        touched.add(dest);
      }
    } catch (_) {
      failed.add(e);
    }
    done++;
    onProgress?.call(done, entries.length);
  }

  try {
    if (failed.isEmpty) {
      await run.file.delete();
    } else {
      await run.file
          .writeAsString('${failed.map((e) => jsonEncode(e)).join('\n')}\n');
    }
  } catch (_) {}
  await _cleanEmptyDirs();
  await rescanGallery(touched);
  return UndoResult(restored, missing, failed.length);
}

Future<void> _cleanEmptyDirs() async {
  try {
    final root = Directory(kOutputRoot);
    if (!await root.exists()) return;
    final dirs = await root.list().where((e) => e is Directory).toList();
    for (final d in dirs) {
      final name = d.path.split('/').last;
      if (name.startsWith('.')) continue;
      final names = await (d as Directory)
          .list()
          .map((x) => x.path.split('/').last)
          .toList();
      if (names.every((n) => n == '.nomedia')) {
        await d.delete(recursive: true);
      }
    }
  } catch (_) {}
}
