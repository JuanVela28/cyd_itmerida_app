/// Restricciones institucionales para los archivos adjuntos.
class AttachmentLimits {
  AttachmentLimits._();

  /// Tamaño máximo permitido por archivo en MB.
  static const int maxFileMB = 10;

  /// Tamaño máximo permitido en bytes.
  static const int maxFileBytes = maxFileMB * 1024 * 1024;

  /// Formatos permitidos para referencias generales.
  static const List<String> allowedExtensions = ['pdf', 'xls', 'xlsx'];

  /// Formatos permitidos para listas de alumnos.
  static const List<String> spreadsheetExtensions = ['xls', 'xlsx'];

  /// Formato permitido para fotografías de eventos.
  static const List<String> pdfExtensions = ['pdf'];

  /// Verifica que el tamaño del archivo sea válido.
  static bool isValidSize(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes <= maxFileBytes;
  }

  /// Obtiene la extensión del archivo en minúsculas.
  static String getExtension(String fileName) {
    final name = fileName.trim();

    return name.contains('.') ? name.split('.').last.toLowerCase() : '';
  }

  /// Verifica que el formato esté permitido.
  static bool isValidExtension(String fileName) {
    return allowedExtensions.contains(getExtension(fileName));
  }

  /// Mensaje informativo sobre el tamaño máximo.
  static const String limitMessage = 'Máximo $maxFileMB MB por archivo.';

  /// Mensaje informativo sobre los formatos permitidos.
  static const String formatsMessage = 'Formatos permitidos: PDF, XLS y XLSX.';
}
