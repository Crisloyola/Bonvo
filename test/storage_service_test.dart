import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:bonvo/core/services/storage_service.dart';

/// Imagen con ruido aleatorio: el peor caso para comprimir.
img.Image _noise(int w, int h, {bool alpha = false}) {
  final rnd = Random(1);
  final im = img.Image(width: w, height: h, numChannels: alpha ? 4 : 3);
  for (final p in im) {
    p
      ..r = rnd.nextInt(256)
      ..g = rnd.nextInt(256)
      ..b = rnd.nextInt(256);
    if (alpha) p.a = rnd.nextBool() ? 0 : 255;
  }
  return im;
}

void main() {
  test('foto enorme queda bajo el tope y en tamaño máximo', () {
    final png = img.encodePng(_noise(4000, 3000));
    expect(png.length, greaterThan(1024 * 1024)); // > 1 MB de entrada

    final b64 = StorageService.compressToBase64(
      png,
      maxDimension: 800,
      quality: 70,
      maxBase64Bytes: 350 * 1024,
    );

    expect(b64.length, lessThanOrEqualTo(350 * 1024));
    final out = img.decodeJpg(base64Decode(b64))!;
    expect(max(out.width, out.height), lessThanOrEqualTo(800));
  });

  test('PNG con transparencia: fondo blanco, no negro', () {
    final im = img.Image(width: 50, height: 50, numChannels: 4); // todo transparente
    final b64 = StorageService.compressToBase64(
      img.encodePng(im),
      maxDimension: 400,
      quality: 80,
      maxBase64Bytes: 120 * 1024,
    );
    final px = img.decodeJpg(base64Decode(b64))!.getPixel(25, 25);
    expect(px.r, greaterThan(240));
    expect(px.g, greaterThan(240));
    expect(px.b, greaterThan(240));
  });

  test('archivo que no es imagen da un mensaje claro', () {
    expect(
      () => StorageService.compressToBase64(
        utf8.encode('esto no es una imagen'),
        maxDimension: 800,
        quality: 70,
        maxBase64Bytes: 350 * 1024,
      ),
      throwsA(isA<ImageTooLargeException>()),
    );
  });
}
