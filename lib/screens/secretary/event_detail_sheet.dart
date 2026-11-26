import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/schedule/schedule_service.dart';
import '../../shared/models/schedule_event_model.dart';
import '../../shared/widgets/institutional_logos.dart';

class EventDetailSheet extends StatefulWidget {
  final ScheduleEventModel event;
  final bool canManage; // false si entra el rol 'staff'

  const EventDetailSheet({
    super.key,
    required this.event,
    this.canManage = true,
  });

  @override
  State<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<EventDetailSheet> {
  final _scheduleService = ScheduleService();
  bool _isProcessing = false;

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatHour(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  (String, Color, Color) _statusBadgeInfo(String status) {
    switch (status) {
      case 'done':
        return ('Realizado', AppColors.statusDoneBg, AppColors.statusDoneText);
      case 'rescheduled':
        return (
          'Reprogramado',
          AppColors.statusPendingBg,
          AppColors.statusPendingText,
        );
      case 'cancelled':
        return ('Cancelado', const Color(0xFFFEE2E2), AppColors.errorRed);
      default:
        return (
          'Programado',
          AppColors.statusReviewBg,
          AppColors.statusReviewText,
        );
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await _scheduleService.updateEventStatus(
        eventId: widget.event.id,
        newStatus: newStatus,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('No se pudo actualizar el estado: $e');
      }
    }
  }

  Future<void> _handleReschedule() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.event.startTime,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.event.startTime),
      helpText: 'Selecciona nueva hora de inicio',
    );
    if (pickedStart == null || !mounted) return;

    // Conserva la duración original del evento al calcular la nueva hora fin
    final duration = widget.event.endTime.difference(widget.event.startTime);
    final newStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedStart.hour,
      pickedStart.minute,
    );
    final newEnd = newStart.add(
      duration.inMinutes > 0 ? duration : const Duration(hours: 1),
    );

    setState(() => _isProcessing = true);
    try {
      await _scheduleService.rescheduleEvent(
        eventId: widget.event.id,
        newStartTime: newStart,
        newEndTime: newEnd,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('No se pudo reprogramar: $e');
      }
    }
  }

  Future<void> _confirmCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar actividad'),
        content: Text(
          '¿Seguro que deseas cancelar "${widget.event.title}"? Dejará de mostrarse en la agenda activa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _changeStatus('cancelled');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusBg, statusText) = _statusBadgeInfo(
      widget.event.status,
    );
    final isDone = widget.event.status == 'done';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador superior de arrastre
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const Center(
            child: InstitutionalLogos(height: 40, withBackground: true),
          ),

          const SizedBox(height: 12),

          // Etiquetas superiores (Tipo + Estado) y botón cerrar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: widget.event.isIndependent
                      ? AppColors.statusDoneBg
                      : AppColors.primaryGuindaLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.event.isIndependent ? 'Institucional' : 'Solicitud',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.event.isIndependent
                        ? AppColors.statusDoneText
                        : AppColors.primaryGuinda,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusText,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Título de la actividad
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 18),

          // Bloque de Fecha, Horario y Ubicación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primaryGuinda,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(widget.event.startTime),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: AppColors.primaryGuinda,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_formatHour(widget.event.startTime)} h  –  ${_formatHour(widget.event.endTime)} h',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (widget.event.location != null &&
                    widget.event.location!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.primaryGuinda,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.event.location!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Notas adicionales (si existen)
          if (widget.event.description != null &&
              widget.event.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notas y detalles técnicos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.event.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ],

          // Botones de gestión (solo para Admin y Secretaría)
          if (widget.canManage) ...[
            const SizedBox(height: 24),
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGuinda,
                ),
              )
            else ...[
              // Acción principal: Marcar como Realizado (o volver a Programado)
              ElevatedButton.icon(
                onPressed: () => _changeStatus(isDone ? 'scheduled' : 'done'),
                icon: Icon(
                  isDone
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  isDone ? 'Marcar como pendiente' : 'Marcar como realizado',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone
                      ? AppColors.textMuted
                      : AppColors.statusDoneText,
                ),
              ),
              const SizedBox(height: 10),
              // Acciones secundarias: Reprogramar y Cancelar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleReschedule,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: const Text('Reprogramar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGuinda,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: BorderSide(
                          color: AppColors.errorRed.withValues(alpha: 0.3),
                        ),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
