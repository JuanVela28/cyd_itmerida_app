import 'package:supabase_flutter/supabase_flutter.dart';

class MyRequestService {
  final String name;
  final String description;
  final String? requiredDate;
  final String? endDate;
  final String status;
  final String? dimensions;
  final String? location;
  final String? scheduleTime;
  final int? quantity;

  const MyRequestService({
    required this.name,
    required this.description,
    required this.requiredDate,
    required this.endDate,
    required this.status,
    this.dimensions,
    this.location,
    this.scheduleTime,
    this.quantity,
  });

  factory MyRequestService.fromJson(Map<String, dynamic> json) {
    final linkedService = json['services'];

    final name = linkedService is Map
        ? linkedService['name']?.toString() ?? 'Servicio'
        : 'Servicio';

    return MyRequestService(
      name: name,
      description: json['description']?.toString() ?? '',
      requiredDate: json['required_date']?.toString(),
      endDate: json['end_date']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      dimensions: json['dimensions']?.toString(),
      location: json['location']?.toString(),
      scheduleTime: json['schedule_time']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
    );
  }
}

class MyRequestAttachment {
  final String fileName;
  final String category;

  const MyRequestAttachment({required this.fileName, required this.category});

  factory MyRequestAttachment.fromJson(Map<String, dynamic> json) {
    return MyRequestAttachment(
      fileName: json['file_name']?.toString() ?? 'Archivo',
      category: json['category']?.toString() ?? 'general_reference',
    );
  }
}

class MyRequestHistory {
  final String action;
  final DateTime? createdAt;
  final String? note;

  const MyRequestHistory({
    required this.action,
    required this.createdAt,
    this.note,
  });

  factory MyRequestHistory.fromJson(Map<String, dynamic> json) {
    final details = json['details'];

    return MyRequestHistory(
      action: json['action']?.toString() ?? 'Actualización',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')
          ?.toLocal(),
      note: details is Map ? details['note']?.toString() : null,
    );
  }
}

class MyRequest {
  final String id;
  final String folio;
  final String activityName;
  final String department;
  final String requestDate;
  final String status;
  final List<MyRequestService> services;
  final List<MyRequestAttachment> attachments;
  final List<MyRequestHistory> history;

  const MyRequest({
    required this.id,
    required this.folio,
    required this.activityName,
    required this.department,
    required this.requestDate,
    required this.status,
    required this.services,
    required this.attachments,
    required this.history,
  });

  factory MyRequest.fromJson(Map<String, dynamic> json) {
    final services = ((json['request_services'] as List?) ?? [])
        .map(
          (item) =>
              MyRequestService.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    final attachments = ((json['attachments'] as List?) ?? [])
        .map(
          (item) => MyRequestAttachment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final history = ((json['request_history'] as List?) ?? [])
        .map(
          (item) =>
              MyRequestHistory.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    history.sort((a, b) {
      final first = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final second = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return second.compareTo(first);
    });

    return MyRequest(
      id: json['id'].toString(),
      folio: json['folio']?.toString() ?? '',
      activityName: json['activity_name']?.toString() ?? 'Sin título',
      department: json['department']?.toString() ?? '',
      requestDate: json['request_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      services: services,
      attachments: attachments,
      history: history,
    );
  }
}

class MyRequestsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MyRequest>> fetchMyRequests() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError('No hay una sesión activa.');
    }

    final rows = await _supabase
        .from('requests')
        .select('''
          id,
          folio,
          activity_name,
          department,
          request_date,
          status,
          created_at,
          request_services (
            id,
            description,
            required_date,
            end_date,
            status,
            dimensions,
            location,
            schedule_time,
            quantity,
            services ( name )
          ),
          attachments (
            id,
            file_name,
            category
          ),
          request_history (
            id,
            action,
            details,
            created_at
          )
        ''')
        .eq('requester_id', user.id)
        .order('created_at', ascending: false);

    return rows.map((row) => MyRequest.fromJson(row)).toList();
  }
}
