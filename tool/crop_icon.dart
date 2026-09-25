// One-off tool: crop the Dakahlia Group logo down to just the tree symbol
// (dropping the "Dakahlia GROUP" wordmark, which won't read at small icon
// sizes), centered on a padded square canvas suitable for app icon
// generation. Run with: dart run tool/crop_icon.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/dak.png').readAsBytesSync();
  final source = img.decodePng(bytes)!;

  // The wordmark starts well below the tree symbol; restrict the scan to
  // the top ~66% of the canvas so the text never enters the bounding box.
  final scanHeight = (source.height * 0.66).round();

  int minX = source.width, minY = source.height, maxX = 0, maxY = 0;
  for (int y = 0; y < scanHeight; y++) {
    for (int x = 0; x < source.width; x++) {
      final a = source.getPixel(x, y).a;
      if (a > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  final symbolWidth = maxX - minX + 1;
  final symbolHeight = maxY - minY + 1;
  final symbol = img.copyCrop(source, x: minX, y: minY, width: symbolWidth, height: symbolHeight);

  // Center the symbol on a square canvas with ~16% padding on each side
  // (matches Android adaptive-icon safe-zone guidance).
  final contentSize = symbolWidth > symbolHeight ? symbolWidth : symbolHeight;
  final canvasSize = (contentSize / 0.68).round();
  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final offsetX = ((canvasSize - symbolWidth) / 2).round();
  final offsetY = ((canvasSize - symbolHeight) / 2).round();
  img.compositeImage(canvas, symbol, dstX: offsetX, dstY: offsetY);

  File('assets/app_icon.png').writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Wrote assets/app_icon.png (${canvas.width}x${canvas.height}), '
      'symbol bbox: $symbolWidth x $symbolHeight at ($minX,$minY)');
}
