import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/schedule/schedule_service.dart';
import '../../shared/models/schedule_event_model.dart';
import 'create_event_screen.dart';
import 'event_detail_sheet.dart';

class ScheduleScreen extends StatefulWidget {
  /// Permite ocultar el botón '+' si quien entra es rol 'staff' (solo consulta)
  final bool canCreateEvents;

  const ScheduleScreen({super.key, this.canCreateEvents = true});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _scheduleService = ScheduleService();

  late DateTime _selectedDate;
  late DateTime _weekStart; // Lunes de la semana visible
  List<ScheduleEventModel> _weekEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _weekStart = _getMondayOfWeek(_selectedDate);
    _loadWeekEvents();
  }

  DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadWeekEvents() async {
    setState(() => _isLoading = true);
    try {
      final weekEnd = _weekStart.add(const Duration(days: 6));
      final events = await _scheduleService.getEventsInRange(
        start: _weekStart,
        end: weekEnd,
      );
      if (mounted) {
        setState(() {
          _weekEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar agenda: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _changeWeek(int offsetWeeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * offsetWeeks));
      _selectedDate = _weekStart;
    });
    _loadWeekEvents();
  }

  List<ScheduleEventModel> _eventsForDay(DateTime day) {
    return _weekEvents.where((e) {
      return e.startTime.year == day.year &&
          e.startTime.month == day.month &&
          e.startTime.day == day.day;
    }).toList();
  }

  String _monthYearLabel(DateTime date) {
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _daySectionTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Hoy';
    if (date == today.add(const Duration(days: 1))) return 'Mañana';
    if (date == today.subtract(const Duration(days: 1))) return 'Ayer';

    const weekDays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${weekDays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  String _formatHour(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEvents = _eventsForDay(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado superior (Mes/Año, Título "Agenda" y botón '+')
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _monthYearLabel(_selectedDate),
                            style: const TextStyle(
                              color: AppColors.secondaryGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Flechas sutiles para cambiar de semana
                          InkWell(
                            onTap: () => _changeWeek(-1),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _changeWeek(1),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Agenda',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (widget.canCreateEvents)
                    Material(
                      color: AppColors.primaryGuinda,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final created = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                CreateEventSheet(initialDate: _selectedDate),
                          );
                          if (created == true) {
                            _loadWeekEvents();
                          }
                        },
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Tira semanal de días (LUN - DOM)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = _weekStart.add(Duration(days: index));
                  final isSelected = day == _selectedDate;
                  final hasEvents = _eventsForDay(day).isNotEmpty;
                  const shortDays = [
                    'LUN',
                    'MAR',
                    'MIÉ',
                    'JUE',
                    'VIE',
                    'SÁB',
                    'DOM',
                  ];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDate = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryGuinda
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              shortDays[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasEvents
                                    ? (isSelected
                                          ? Colors.white
                                          : AppColors.secondaryGold)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Sub-encabezado del día seleccionado ("Hoy" + contador)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _daySectionTitle(_selectedDate),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDayEvents.length == 1
                            ? '1 actividad programada'
                            : '${selectedDayEvents.length} actividades programadas',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGuindaLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedDayEvents.length}',
                      style: const TextStyle(
                        color: AppColors.primaryGuinda,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Línea de tiempo de eventos del día
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGuinda,
                      ),
                    )
                  : selectedDayEvents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primaryGuinda,
                      onRefresh: _loadWeekEvents,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: selectedDayEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedDayEvents[index];
                          final isLast = index == selectedDayEvents.length - 1;
                          return _buildTimelineEventItem(
                            event: event,
                            index: index,
                            isLast: isLast,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 52,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin actividades para este día',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEventItem({
    required ScheduleEventModel event,
    required int index,
    required bool isLast,
  }) {
    final bool isInstitutional = event.isIndependent;
    final Color dotColor = isInstitutional
        ? AppColors.statusDoneText
        : (index % 2 == 0 ? AppColors.primaryGuinda : AppColors.secondaryGold);

    final Color badgeBg = isInstitutional
        ? AppColors.statusDoneBg
        : (index % 2 == 0
              ? AppColors.primaryGuindaLight
              : AppColors.statusPendingBg);

    final Color badgeText = isInstitutional
        ? AppColors.statusDoneText
        : (index % 2 == 0
              ? AppColors.primaryGuinda
              : AppColors.statusPendingText);

    final String badgeLabel = isInstitutional ? 'Institucional' : 'Solicitud';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: Hora
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatHour(event.startTime),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // Columna central: Punto de color + línea vertical conectora
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: AppColors.borderSubtle),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Columna derecha: Tarjeta del evento (tocable para ver detalle / gestionar)
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final updated = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EventDetailSheet(
                    event: event,
                    canManage: widget.canCreateEvents,
                  ),
                );
                if (updated == true) {
                  _loadWeekEvents();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeText,
                            ),
                          ),
                        ),
                        if (event.status == 'done' ||
                            event.status == 'rescheduled') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: event.status == 'done'
                                  ? AppColors.statusDoneBg
                                  : AppColors.statusPendingBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.status == 'done'
                                  ? 'Realizado'
                                  : 'Reprogramado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: event.status == 'done'
                                    ? AppColors.statusDoneText
                                    : AppColors.statusPendingText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        decoration: event.status == 'done'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatHour(event.startTime)} h',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
