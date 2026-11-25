import 'package:flutter/services.dart';

const _channel = MethodChannel('lc/media');

/// Demande à Android de rafraîchir la galerie pour ces chemins.
Future<void> rescanGallery(Iterable<String> paths) async {
  final list = paths.toList();
  for (var i = 0; i < list.length; i += 200) {
    final end = i + 200 > list.length ? list.length : i + 200;
    try {
      await _channel.invokeMethod('scan', {'paths': list.sublist(i, end)});
    } catch (_) {}
  }
}
