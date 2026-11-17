import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/requester/new_request/s1_general_info.dart';
import '../../screens/requester/new_request/s3_service_details.dart';
import '../../screens/requester/new_request/s4_attachments.dart';
import 'service_catalog_service.dart';

class RequestSubmissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Nombre del bucket en Supabase Storage (créalo como bucket privado 'request-attachments')
  static const String _storageBucket = 'request-attachments';

  /// Genera el siguiente folio único del año en curso: ej. CYD-2026-0001
  Future<String> _generateNextFolio() async {
    final year = DateTime.now().year;
    final prefix = 'CYD-$year-';

    final existing = await _supabase
        .from('requests')
        .select('folio')
        .like('folio', '$prefix%')
        .order('folio', ascending: false)
        .limit(1);

    int nextNumber = 1;
    if (existing.isNotEmpty) {
      final lastFolio = existing.first['folio'] as String;
      final numericPart = lastFolio.replaceFirst(prefix, '');
      final parsed = int.tryParse(numericPart);
      if (parsed != null) {
        nextNumber = parsed + 1;
      }
    }

    return '$prefix${nextNumber.toString().padLeft(4, '0')}';
  }

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

    final folio = await _generateNextFolio();

    // 1. Insertar cabecera en 'requests'
    final insertedRequest = await _supabase
        .from('requests')
        .insert({
          'folio': folio,
          'requester_id': user.id,
          'department': generalInfo.department,
          'contact_person': generalInfo.contactPerson,
          'activity_name': generalInfo.activityName,
          'request_date': _formatDateIso(DateTime.now()),
          'status': 'pending',
        })
        .select('id')
        .single();

    final String requestId = insertedRequest['id'] as String;

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
  }
}
