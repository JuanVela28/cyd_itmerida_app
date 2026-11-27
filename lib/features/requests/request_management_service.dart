import 'package:supabase_flutter/supabase_flutter.dart';

import '../schedule/schedule_service.dart';

class RequestItemDetail {
  final String id;
  final String serviceName;
  final String description;
  final String? formatType;
  final String? requiredDate;
  final String? endDate;
  final String? dimensions;
  final String? location;
  final String? scheduleTime;
  final int quantity;
  final String status;

  const RequestItemDetail({
    required this.id,
    required this.serviceName,
    required this.description,
    this.formatType,
    this.requiredDate,
    this.endDate,
    this.dimensions,
    this.location,
    this.scheduleTime,
    required this.quantity,
    required this.status,
  });

  factory RequestItemDetail.fromJson(Map<String, dynamic> json) {
    final serviceObj = json['services'] as Map<String, dynamic>?;
    return RequestItemDetail(
      id: json['id'].toString(),
      serviceName: serviceObj?['name'] as String? ?? 'Servicio',
      description: json['description'] as String? ?? '',
      formatType: json['format_type'] as String?,
      requiredDate: json['required_date'] as String?,
      endDate: json['end_date'] as String?,
      dimensions: json['dimensions'] as String?,
      location: json['location'] as String?,
      scheduleTime: json['schedule_time'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class RequestAttachmentItem {
  final String id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final String category;

  const RequestAttachmentItem({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    required this.category,
  });

  factory RequestAttachmentItem.fromJson(Map<String, dynamic> json) {
    return RequestAttachmentItem(
      id: json['id'].toString(),
      fileName: json['file_name'] as String? ?? 'Archivo',
      fileUrl: json['file_url'] as String? ?? '',
      fileType: json['file_type'] as String?,
      category: json['category'] as String? ?? 'general_reference',
    );
  }
}

class AdminRequestModel {
  final String id;
  final String folio;
  final String department;
  final String contactPerson;
  final String activityName;
  final String requestDate;
  final String status;
  final DateTime createdAt;
  final List<RequestItemDetail> services;
  final List<RequestAttachmentItem> attachments;

  const AdminRequestModel({
    required this.id,
    required this.folio,
    required this.department,
    required this.contactPerson,
    required this.activityName,
    required this.requestDate,
    required this.status,
    required this.createdAt,
    required this.services,
    required this.attachments,
  });

  factory AdminRequestModel.fromJson(Map<String, dynamic> json) {
    final rawServices = (json['request_services'] as List<dynamic>?) ?? [];
    final rawAttachments = (json['attachments'] as List<dynamic>?) ?? [];

    return AdminRequestModel(
      id: json['id'].toString(),
      folio: json['folio'] as String? ?? '',
      department: json['department'] as String? ?? '',
      contactPerson: json['contact_person'] as String? ?? '',
      activityName: json['activity_name'] as String? ?? 'Sin título',
      requestDate: json['request_date'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      services: rawServices
          .map((s) => RequestItemDetail.fromJson(s as Map<String, dynamic>))
          .toList(),
      attachments: rawAttachments
          .map((a) => RequestAttachmentItem.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RequestManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScheduleService _scheduleService = ScheduleService();

  /// Cuenta las solicitudes registradas según su estado.
  Future<int> countRequestsByStatus(String status) async {
    final response = await _supabase
        .from('requests')
        .select('id')
        .eq('status', status)
        .count(CountOption.exact);

    return response.count;
  }

  /// Obtiene todas las solicitudes recibidas ordenadas por las más recientes
  Future<List<AdminRequestModel>> fetchAllRequests({
    String? statusFilter,
  }) async {
    var query = _supabase.from('requests').select('''
      id,
      folio,
      department,
      contact_person,
      activity_name,
      request_date,
      status,
      created_at,
      request_services (
        id,
        description,
        format_type,
        required_date,
        end_date,
        dimensions,
        location,
        schedule_time,
        quantity,
        status,
        services ( name )
      ),
      attachments (
        id,
        file_name,
        file_url,
        file_type,
        category
      )
    ''');

    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => AdminRequestModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Actualiza el estado de la solicitud y registra movimiento en request_history
  Future<void> updateRequestStatus({
    required String requestId,
    required String folio,
    required String newStatus,
    String? note,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('requests')
        .update({'status': newStatus})
        .eq('id', requestId);

    await _supabase
        .from('request_services')
        .update({'status': newStatus})
        .eq('request_id', requestId);

    await _supabase.from('request_history').insert({
      'request_id': requestId,
      'user_id': userId,
      'action': 'Estado actualizado a $newStatus ($folio)',
      'details': {
        'new_status': newStatus,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    });
  }

  /// Agenda una solicitud directamente en schedule_events y la pasa a 'under_review'
  Future<void> scheduleRequestInCalendar({
    required AdminRequestModel request,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _scheduleService.createEvent(
      requestId: request.id,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      isIndependent: false,
    );

    if (request.status == 'pending') {
      await _supabase
          .from('requests')
          .update({'status': 'under_review'})
          .eq('id', request.id);
    }

    await _supabase.from('request_history').insert({
      'request_id': request.id,
      'user_id': userId,
      'action': 'Actividad agendada en calendario (${request.folio})',
      'details': {
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': location,
      },
    });
  }

  /// Genera una URL temporal (1 hora) para descargar o visualizar un adjunto privado
  Future<String> getSignedAttachmentUrl(String storagePath) async {
    return await _supabase.storage
        .from('request-attachments')
        .createSignedUrl(storagePath, 3600);
  }
}
