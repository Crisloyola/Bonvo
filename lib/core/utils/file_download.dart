// Descarga un archivo generado en la app (p. ej. el afiche del QR).
// En web usa el navegador; en otras plataformas aún no está disponible.
export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
