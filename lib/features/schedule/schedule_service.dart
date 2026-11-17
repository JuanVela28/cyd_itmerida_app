import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/schedule_event_model.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene los eventos dentro de un rango de fechas (ej. la semana visible)
  Future<List<ScheduleEventModel>> getEventsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final startIso = DateTime(
      start.year,
      start.month,
      start.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();
    final endIso = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    final response = await _supabase
        .from('schedule_events')
        .select()
        .gte('start_time', startIso)
        .lte('start_time', endIso)
        .neq('status', 'cancelled')
        .order('start_time', ascending: true);

    return (response as List)
        .map((item) => ScheduleEventModel.fromJson(item))
        .toList();
  }

  /// Crea un evento institucional independiente (o vinculado a solicitud)
  Future<void> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    bool isIndependent = true,
    String? requestId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('schedule_events').insert({
      'title': title.trim(),
      'description': description?.trim(),
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'location': location?.trim(),
      'status': 'scheduled',
      'is_independent': isIndependent,
      'request_id': requestId,
      'created_by': userId,
    });
  }

  /// Busca eventos existentes que se empalmen con el rango propuesto
  Future<List<ScheduleEventModel>> findOverlappingEvents({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final startIso = startTime.toUtc().toIso8601String();
    final endIso = endTime.toUtc().toIso8601String();

    final response = await _supabase
        .from('schedule_events')
        .select()
        .neq('status', 'cancelled')
        .lt('start_time', endIso)
        .gt('end_time', startIso)
        .order('start_time', ascending: true);

    return (response as List)
        .map((item) => ScheduleEventModel.fromJson(item))
        .toList();
  }

  /// Actualiza el estado de un evento ('done', 'cancelled', 'scheduled')
  Future<void> updateEventStatus({
    required String eventId,
    required String newStatus,
  }) async {
    await _supabase
        .from('schedule_events')
        .update({'status': newStatus})
        .eq('id', eventId);
  }

  /// Reprograma fecha/hora de un evento y actualiza su estado a 'rescheduled'
  Future<void> rescheduleEvent({
    required String eventId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    await _supabase
        .from('schedule_events')
        .update({
          'start_time': newStartTime.toUtc().toIso8601String(),
          'end_time': newEndTime.toUtc().toIso8601String(),
          'status': 'rescheduled',
        })
        .eq('id', eventId);
  }
}
