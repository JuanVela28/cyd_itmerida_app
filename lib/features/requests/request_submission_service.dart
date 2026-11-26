import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/requester/new_request/s1_general_info.dart';
import '../../screens/requester/new_request/s3_service_details.dart';
import '../../screens/requester/new_request/s4_attachments.dart';
import 'service_catalog_service.dart';
import '../../core/constants/attachment_limits.dart';

class PartialSubmissionException implements Exception {
  final String requestId;
  final String folio;
  final Object cause;

  const PartialSubmissionException({
    required this.requestId,
    required this.folio,
    required this.cause,
  });

  @override
  String toString() =>
      'La solicitud $folio fue creada, pero '
      'no se completó el registro de todos sus datos.';
}

class RequestSubmissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Nombre del bucket en Supabase Storage (créalo como bucket privado 'request-attachments')
  static const String _storageBucket = 'request-attachments';

  /// Genera el siguiente folio único del año en curso: ej. CYD-2026-0001

  String _formatDateIso(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _formatTimeOfDay(dynamic timeOfDay) {
    if (timeOfDay == null) return null;
    final h = timeOfDay.hour.toString().padLeft(2, '0');
    final m = timeOfDay.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Valida los formatos y tamaños antes de registrar la solicitud.
  Future<void> _validateAttachments(List<PendingAttachment> attachments) async {
    for (final attachment in attachments) {
      final name = attachment.file.name;

      final extension = AttachmentLimits.getExtension(name);

      // Valida el formato institucional.
      if (!AttachmentLimits.isValidExtension(name)) {
        throw Exception(
          'El archivo $name tiene un formato no permitido. '
          '${AttachmentLimits.formatsMessage}',
        );
      }

      // Valida el formato correspondiente a su categoría.
      if (!attachment.category.allowedExtensions.contains(extension)) {
        throw Exception(
          'El archivo $name no corresponde a los formatos '
          'permitidos para su categoría.',
        );
      }

      // Verifica que exista una ruta local.
      final path = attachment.file.path;

      if (path == null || path.isEmpty) {
        throw Exception('No se pudo localizar el archivo $name.');
      }

      final file = File(path);

      // Comprueba que el archivo todavía exista.
      if (!await file.exists()) {
        throw Exception('El archivo $name ya no está disponible.');
      }

      // Comprueba el tamaño real del archivo.
      final size = await file.length();

      if (!AttachmentLimits.isValidSize(size)) {
        throw Exception(
          'El archivo $name está vacío o supera '
          'el límite de ${AttachmentLimits.maxFileMB} MB.',
        );
      }
    }
  }

  /// Envía la solicitud completa a Supabase y devuelve el folio generado
  Future<String> submitRequest({
    required GeneralInfoData generalInfo,
    required List<ServiceOption> services,
    required Map<String, ServiceDetailData> details,
    required List<PendingAttachment> attachments,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }
    // Valida los adjuntos antes de crear registros en Supabase.
    await _validateAttachments(attachments);

    // 1. Registrar solicitud y obtener el folio generado automáticamente por PostgreSQL.
    final insertedRequest = await _supabase
        .from('requests')
        .insert({
          'requester_id': user.id,
          'department': generalInfo.department,
          'contact_person': generalInfo.contactPerson,
          'activity_name': generalInfo.activityName,
          'request_date': _formatDateIso(DateTime.now()),
          'status': 'pending',
        })
        .select('id, folio')
        .single();

    final String requestId = insertedRequest['id'] as String;
    final String folio = insertedRequest['folio'] as String;
    try {
      // 2. Insertar cada servicio seleccionado en 'request_services'
      final serviceRows = services.map((service) {
        final d = details[service.id]!;
        return {
          'request_id': requestId,
          'service_id': int.parse(service.id),
          'description': d.description,
          'format_type': d.formatType,
          'required_date': d.requiredDate != null
              ? _formatDateIso(d.requiredDate!)
              : null,
          'dimensions': d.dimensions,
          'location': d.location,
          'schedule_time': _formatTimeOfDay(d.scheduleTime),
          'quantity': d.quantity ?? 1,
          'status': 'pending',
        };
      }).toList();

      await _supabase.from('request_services').insert(serviceRows);

      // 3. Subir archivos adjuntos a Supabase Storage y registrar en 'attachments'
      for (int i = 0; i < attachments.length; i++) {
        final item = attachments[i];
        final originalName = item.file.name.trim();
        final ext = originalName.contains('.')
            ? originalName.split('.').last.toLowerCase()
            : '';
        final sanitizedName = originalName.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final storagePath =
            '$requestId/${DateTime.now().millisecondsSinceEpoch}_${i}_$sanitizedName';

        await _supabase.storage
            .from(_storageBucket)
            .upload(storagePath, File(item.file.path!));

        await _supabase.from('attachments').insert({
          'request_id': requestId,
          'file_name': originalName,
          'file_url': storagePath,
          'file_type': ext,
          'category': item.category.databaseValue,
          'uploaded_by': user.id,
        });
      }

      // 4. Registrar auditoría inicial en 'request_history'
      await _supabase.from('request_history').insert({
        'request_id': requestId,
        'user_id': user.id,
        'action': 'Solicitud creada ($folio)',
        'details': {
          'folio': folio,
          'services_count': services.length,
          'attachments_count': attachments.length,
        },
      });

      return folio;
    } catch (error) {
      throw PartialSubmissionException(
        requestId: requestId,
        folio: folio,
        cause: error,
      );
    }
  }
}
