class ScheduleEventModel {
  final String id;
  final String? requestId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String
  status; // 'unscheduled', 'scheduled', 'done', 'cancelled', 'rescheduled'
  final bool isIndependent;

  ScheduleEventModel({
    required this.id,
    this.requestId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.status,
    required this.isIndependent,
  });

  factory ScheduleEventModel.fromJson(Map<String, dynamic> json) {
    return ScheduleEventModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      isIndependent: json['is_independent'] as bool? ?? false,
    );
  }
}
