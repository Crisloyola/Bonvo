import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageTooLargeException implements Exception {
  final String message;
  const ImageTooLargeException(this.message);
  @override
  String toString() => message;
}

/// Las imágenes se guardan como JPEG en base64 dentro de Firestore (sin
/// Firebase Storage). Un documento admite máx. 1 MB, así que cada imagen
/// se comprime hasta un tope; el negocio guarda logo + banner en el mismo
/// documento, por eso esos topes suman bastante menos de 1 MB.
class StorageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickProfilePhoto() => _pickAndEncode(
      maxDimension: 300, quality: 70, maxBase64Bytes: 80 * 1024);

  Future<String?> pickBannerImage() => _pickAndEncode(
      maxDimension: 800, quality: 70, maxBase64Bytes: 350 * 1024);

  Future<String?> pickLogoImage() => _pickAndEncode(
      maxDimension: 400, quality: 80, maxBase64Bytes: 120 * 1024);

  Future<String?> _pickAndEncode({
    required int maxDimension,
    required int quality,
    required int maxBase64Bytes,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    // En web image_picker no siempre reduce la imagen (p. ej. PNG), así que
    // se comprime aquí en todas las plataformas.
    return compressToBase64(
      bytes,
      maxDimension: maxDimension,
      quality: quality,
      maxBase64Bytes: maxBase64Bytes,
    );
  }

  /// Redimensiona a [maxDimension] px (lado mayor), convierte a JPEG y baja
  /// calidad/tamaño hasta que el base64 quepa en [maxBase64Bytes].
  static String compressToBase64(
    Uint8List bytes, {
    required int maxDimension,
    required int quality,
    required int maxBase64Bytes,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const ImageTooLargeException(
          'No se pudo leer la imagen. Usa una foto JPG o PNG.');
    }
    final source = img.bakeOrientation(decoded);

    var dim = maxDimension;
    var q = quality;
    while (true) {
      var resized = source;
      if (source.width > dim || source.height > dim) {
        resized = source.width >= source.height
            ? img.copyResize(source,
                width: dim, interpolation: img.Interpolation.average)
            : img.copyResize(source,
                height: dim, interpolation: img.Interpolation.average);
      }
      // JPEG no tiene transparencia: se pone fondo blanco (si no, queda negro)
      if (resized.hasAlpha) {
        final bg = img.Image(width: resized.width, height: resized.height);
        img.fill(bg, color: img.ColorRgb8(255, 255, 255));
        img.compositeImage(bg, resized);
        resized = bg;
      }
      final b64 = base64Encode(img.encodeJpg(resized, quality: q));
      if (b64.length <= maxBase64Bytes) return b64;

      if (q > 40) {
        q -= 10;
      } else if (dim > 200) {
        dim = (dim * 0.75).round();
        q = quality;
      } else {
        throw const ImageTooLargeException(
            'La imagen es demasiado pesada. Prueba con otra foto.');
      }
    }
  }
}
