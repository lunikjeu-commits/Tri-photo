import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

const kBlurry = 'Floues';
const double _threshold = 20; // plus petit = plus tolérant
const _checked = ['.jpg', '.jpeg', '.heic', '.heif'];

Future<bool> isBlurry(File f) async {
  final low = f.path.toLowerCase();
  if (!_checked.any(low.endsWith)) return false;
  try {
    final bytes = await f.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 320);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width, h = img.height;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    codec.dispose();
    if (data == null || w < 8 || h < 8) return false;
    final px = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return _laplacianVariance(px, w, h) < _threshold;
  } catch (_) {
    return false;
  }
}

double _laplacianVariance(Uint8List px, int w, int h) {
  final g = Float32List(w * h);
  for (var i = 0; i < w * h; i++) {
    g[i] = 0.299 * px[i * 4] + 0.587 * px[i * 4 + 1] + 0.114 * px[i * 4 + 2];
  }
  double sum = 0, sumSq = 0;
  var n = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final v = g[i - w] + g[i + w] + g[i - 1] + g[i + 1] - 4 * g[i];
      sum += v;
      sumSq += v * v;
      n++;
    }
  }
  if (n == 0) return 1000;
  final mean = sum / n;
  return sumSq / n - mean * mean;
}
