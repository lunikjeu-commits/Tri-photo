import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class Thumb {
  final int width;
  final int height;
  final Uint8List rgba;
  final Uint8List png;
  const Thumb(this.width, this.height, this.rgba, this.png);
}

/// Décode une version réduite (320 px de large) : rapide, accepte JPG, PNG, WebP, HEIC.
Future<Thumb?> loadThumb(File f) async {
  try {
    final bytes = await f.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 320);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width, h = img.height;
    final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    codec.dispose();
    if (raw == null || png == null) return null;
    return Thumb(
      w,
      h,
      raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
      png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
  } catch (_) {
    return null;
  }
}
