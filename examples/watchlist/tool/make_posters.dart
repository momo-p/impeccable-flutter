import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Writes the placeholder posters the example ships.
///
/// Real film artwork is copyrighted, so these are generated: a vertical
/// gradient in the film's colour with a lighter band near the bottom, at a
/// real 2:3 poster ratio so they scale cleanly instead of upsampling from a
/// few pixels. `dart:io` supplies the zlib encoder PNG needs, which keeps the
/// files a few KB rather than the hundreds an uncompressed stream would cost.
void main(List<String> argv) {
  const w = 300, h = 450;

  void write(String path, int r, int g, int b) {
    final raw = BytesBuilder();
    for (var y = 0; y < h; y++) {
      raw.addByte(0); // filter: none
      final t = y / (h - 1);
      // Darker at the top, lifting toward the bottom third.
      final lift = t < 0.66 ? t * 0.35 : 0.23 + (t - 0.66) * 1.1;
      for (var x = 0; x < w; x++) {
        final vignette = 1.0 - ((x / w - 0.5).abs() * 0.25);
        int ch(int c) =>
            ((c * (0.62 + lift) * vignette).round()).clamp(0, 255);
        raw.add([ch(r), ch(g), ch(b)]);
      }
    }

    final png = BytesBuilder()
      ..add([137, 80, 78, 71, 13, 10, 26, 10])
      ..add(_chunk('IHDR', [
        ..._be32(w), ..._be32(h), 8, 2, 0, 0, 0,
      ]))
      ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes())))
      ..add(_chunk('IEND', const []));

    File(path).writeAsBytesSync(png.takeBytes());
    stdout.writeln('wrote $path (${File(path).lengthSync()} bytes)');
  }

  write('${argv[0]}/paris-texas.png', 198, 122, 84);
  write('${argv[0]}/brighter-summer-day.png', 96, 132, 116);
}

List<int> _be32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];

List<int> _chunk(String type, List<int> data) {
  final body = <int>[...utf8.encode(type), ...data];
  var c = 0xFFFFFFFF;
  for (final byte in body) {
    c ^= byte;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
  }
  return [..._be32(data.length), ...body, ..._be32(c ^ 0xFFFFFFFF)];
}
