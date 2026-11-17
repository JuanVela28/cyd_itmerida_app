import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../features/requests/service_catalog_service.dart';

enum AttachmentCategory { generalReference, certificatesList, eventPhotosPdf }

extension AttachmentCategoryInfo on AttachmentCategory {
  String get databaseValue {
    return switch (this) {
      AttachmentCategory.generalReference => 'general_reference',
      AttachmentCategory.certificatesList => 'certificates_list',
      AttachmentCategory.eventPhotosPdf => 'event_photos_pdf',
    };
  }

  List<String> get allowedExtensions {
    return switch (this) {
      AttachmentCategory.generalReference => [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'docx',
      ],
      AttachmentCategory.certificatesList => ['xlsx', 'csv'],
      AttachmentCategory.eventPhotosPdf => ['pdf'],
    };
  }
}

class PendingAttachment {
  final PlatformFile file;
  final AttachmentCategory category;
  final int sizeBytes;

  const PendingAttachment({
    required this.file,
    required this.category,
    required this.sizeBytes,
  });
}

class AttachmentsStep extends StatefulWidget {
  final List<ServiceOption> services;
  final List<PendingAttachment> initialAttachments;
  final ValueChanged<List<PendingAttachment>> onBack;
  final ValueChanged<List<PendingAttachment>> onContinue;

  const AttachmentsStep({
    super.key,
    required this.services,
    required this.initialAttachments,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<AttachmentsStep> createState() => _AttachmentsStepState();
}

class _AttachmentsStepState extends State<AttachmentsStep> {
  // Límite provisional por archivo: 20 MiB.
  static const int _maxFileBytes = 20 * 1024 * 1024;

  late final List<PendingAttachment> _attachments;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _attachments = List.of(widget.initialAttachments);
  }

  bool get _requiresStudentList {
    return widget.services.any((service) {
      final name = service.name.trim().toLowerCase();
      return name == 'constancias' || name == 'carpetas';
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFiles(AttachmentCategory category) async {
    if (_isPicking) return;

    setState(() => _isPicking = true);

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: category.allowedExtensions,
      );

      if (!mounted || files.isEmpty) return;

      final accepted = <PendingAttachment>[];
      var rejected = 0;

      for (final file in files) {
        final name = file.name.trim();
        final extension = name.contains('.')
            ? name.split('.').last.toLowerCase()
            : '';

        if (!category.allowedExtensions.contains(extension)) {
          rejected++;
          continue;
        }

        final int? size = file.lengthSync() ?? await file.length();

        if (!mounted) return;

        if (size == null || size <= 0 || size > _maxFileBytes) {
          rejected++;
          continue;
        }

        final duplicate = [..._attachments, ...accepted].any(
          (item) =>
              item.category == category &&
              item.file.name.toLowerCase() == name.toLowerCase() &&
              item.sizeBytes == size,
        );

        if (duplicate) {
          rejected++;
          continue;
        }

        accepted.add(
          PendingAttachment(file: file, category: category, sizeBytes: size),
        );
      }

      setState(() {
        _attachments.addAll(accepted);
      });

      final message =
          '${accepted.length} archivo(s) agregado(s).'
          '${rejected > 0 ? ' $rejected rechazado(s) o duplicado(s).' : ''}';

      _showMessage(message);
    } catch (error) {
      debugPrint('File picker error: $error');
      _showMessage('No se pudieron seleccionar los archivos.');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removeAttachment(PendingAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  void _goBack() {
    widget.onBack(List.of(_attachments));
  }

  void _continue() {
    if (_requiresStudentList &&
        !_attachments.any(
          (item) => item.category == AttachmentCategory.certificatesList,
        )) {
      _showMessage(
        'Debes agregar una lista XLSX o CSV '
        'para constancias o carpetas.',
      );
      return;
    }

    widget.onContinue(List.of(_attachments));
  }

  Widget _attachmentSection({
    required String title,
    required String description,
    required AttachmentCategory category,
    bool requiredFile = false,
  }) {
    final files = _attachments
        .where((item) => item.category == category)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (requiredFile)
                  const Text(
                    'Obligatorio',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(description),

            const SizedBox(height: 12),

            Text(
              'Formatos: '
              '${category.allowedExtensions.join(', ').toUpperCase()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            if (files.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('No hay archivos seleccionados.'),
              ),

            ...files.map((item) {
              final megabytes = item.sizeBytes / (1024 * 1024);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  item.file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${megabytes.toStringAsFixed(2)} MB'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Quitar archivo',
                  onPressed: () => _removeAttachment(item),
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: _isPicking ? null : () => _pickFiles(category),
              icon: const Icon(Icons.attach_file),
              label: const Text('Agregar archivos'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),

        Text(
          'Paso 4 de 5',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Archivos adjuntos',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Adjunta los documentos necesarios '
          'para complementar tu solicitud.',
        ),

        const SizedBox(height: 24),

        _attachmentSection(
          title: 'Referencias generales',
          description:
              'Agrega imágenes, documentos o referencias '
              'que ayuden a explicar tu solicitud.',
          category: AttachmentCategory.generalReference,
        ),

        if (_requiresStudentList)
          _attachmentSection(
            title: 'Lista de alumnos',
            description:
                'Adjunta una hoja de cálculo con nombre '
                'del alumno, carrera o disciplina y motivo '
                'de la constancia o reconocimiento.',
            category: AttachmentCategory.certificatesList,
            requiredFile: true,
          ),

        _attachmentSection(
          title: 'Fotografías de evento',
          description:
              'Si el personal de Comunicación y Difusión '
              'no cubre el evento, puedes adjuntar '
              'un PDF con fotografías para publicación.',
          category: AttachmentCategory.eventPhotosPdf,
        ),

        Text(
          'Archivos seleccionados: ${_attachments.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          'Tamaño máximo provisional: 20 MB por archivo. '
          'Los archivos todavía no se han enviado.',
          style: TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                child: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continue,
                child: const Text('Siguiente'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
