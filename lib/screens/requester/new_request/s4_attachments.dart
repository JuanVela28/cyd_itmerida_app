import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
      AttachmentCategory.generalReference => ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
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

      setState(() => _attachments.addAll(accepted));

      final message =
          '${accepted.length} archivo(s) agregado(s).'
          '${rejected > 0 ? ' $rejected rechazado(s) o duplicado(s).' : ''}';
      _showMessage(message);
    } catch (error) {
      debugPrint('File picker error: $error');
      _showMessage('No se pudieron seleccionar los archivos.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeAttachment(PendingAttachment attachment) {
    setState(() => _attachments.remove(attachment));
  }

  void _goBack() => widget.onBack(List.of(_attachments));

  void _continue() {
    if (_requiresStudentList &&
        !_attachments.any(
          (item) => item.category == AttachmentCategory.certificatesList,
        )) {
      _showMessage(
        'Debes agregar una lista XLSX o CSV para constancias o carpetas.',
      );
      return;
    }
    widget.onContinue(List.of(_attachments));
  }

  IconData _categoryIcon(AttachmentCategory category) {
    return switch (category) {
      AttachmentCategory.generalReference => Icons.folder_copy_outlined,
      AttachmentCategory.certificatesList => Icons.table_chart_outlined,
      AttachmentCategory.eventPhotosPdf => Icons.photo_library_outlined,
    };
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGuindaLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(category),
                  size: 22,
                  color: AppColors.primaryGuinda,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      requiredFile ? 'Obligatorio' : 'Opcional',
                      style: TextStyle(
                        color: requiredFile
                            ? AppColors.statusPendingText
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Formatos: ${category.allowedExtensions.join(', ').toUpperCase()}',
            style: const TextStyle(
              color: AppColors.primaryGuinda,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          if (files.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 17, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todavía no hay archivos agregados.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            ...files.map((item) {
              final megabytes = item.sizeBytes / (1024 * 1024);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(10, 4, 2, 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        color: AppColors.primaryGuinda, size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.file.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${megabytes.toStringAsFixed(2)} MB',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      iconSize: 19,
                      tooltip: 'Quitar archivo',
                      color: AppColors.primaryGuinda,
                      onPressed: () => _removeAttachment(item),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGuinda,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: AppColors.primaryGuinda),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isPicking ? null : () => _pickFiles(category),
              icon: _isPicking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded, size: 19),
              label: const Text('Agregar archivos'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                foregroundColor: AppColors.primaryGuinda,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            children: [
              const Text(
                'Archivos adjuntos',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Agrega documentos e imágenes de referencia cuando sea necesario.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _attachmentSection(
                title: 'Referencias generales',
                description: 'Imágenes y documentos que ayuden a explicar tu solicitud.',
                category: AttachmentCategory.generalReference,
              ),
              if (_requiresStudentList)
                _attachmentSection(
                  title: 'Lista de alumnos',
                  description:
                      'Adjunta una hoja de cálculo con nombre, carrera o '
                      'disciplina y motivo de la constancia o reconocimiento.',
                  category: AttachmentCategory.certificatesList,
                  requiredFile: true,
                ),
              _attachmentSection(
                title: 'Fotografías de evento',
                description:
                    'Si Comunicación y Difusión no cubre el evento, '
                    'adjunta un PDF con fotografías para publicación.',
                category: AttachmentCategory.eventPhotosPdf,
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryGuindaLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Archivos seleccionados: ${_attachments.length}',
                      style: const TextStyle(
                        color: AppColors.primaryGuinda,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Máximo 20 MB por archivo. La carga se realiza al enviar la solicitud.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _footer(),
      ],
    );
  }
}
