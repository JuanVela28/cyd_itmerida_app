import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../features/requests/request_management_service.dart';
import '../../features/schedule/schedule_service.dart';
import '../../shared/widgets/institutional_logos.dart';

class RequestManagementScreen extends StatefulWidget {
  const RequestManagementScreen({super.key});

  @override
  State<RequestManagementScreen> createState() =>
      _RequestManagementScreenState();
}

class _RequestManagementScreenState extends State<RequestManagementScreen> {
  final _service = RequestManagementService();
  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<AdminRequestModel> _requests = [];

  static const _filters = [
    ('all', 'Todas'),
    ('pending', 'Pendientes'),
    ('under_review', 'En revisión'),
    ('completed', 'Atendidas'),
    ('rejected', 'Rechazadas'),
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.fetchAllRequests(
        statusFilter: _selectedFilter,
      );
      if (mounted) {
        setState(() {
          _requests = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar solicitudes: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  (String, Color, Color) _statusBadge(String status) {
    switch (status) {
      case 'under_review':
        return (
          'En revisión',
          AppColors.statusReviewBg,
          AppColors.statusReviewText,
        );
      case 'completed':
        return ('Atendida', AppColors.statusDoneBg, AppColors.statusDoneText);
      case 'rejected':
        return ('Rechazada', const Color(0xFFFEE2E2), AppColors.errorRed);
      case 'cancelled':
        return ('Cancelada', const Color(0xFFF3F4F6), AppColors.textMuted);
      default:
        return (
          'Pendiente',
          AppColors.statusPendingBg,
          AppColors.statusPendingText,
        );
    }
  }

  void _openDetailSheet(AdminRequestModel req) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _RequestDetailBottomSheet(request: req, service: _service),
    );

    if (changed == true) {
      _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logotipos institucionales.
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Center(
                child: InstitutionalLogos(height: 44, withBackground: true),
              ),
            ),

            // Encabezado limpio estilo Figma
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 24, 12),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    Material(
                      color: AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textDark,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GESTIÓN DE TRÁMITES',
                          style: TextStyle(
                            color: AppColors.secondaryGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Solicitudes',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadRequests,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primaryGuinda,
                    ),
                    tooltip: 'Actualizar lista',
                  ),
                ],
              ),
            ),

            // Barra de filtros por estado
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final (key, label) = _filters[index];
                  final isSelected = _selectedFilter == key;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = key);
                      _loadRequests();
                    },
                    selectedColor: AppColors.primaryGuinda,
                    backgroundColor: AppColors.surfaceWhite,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryGuinda
                            : AppColors.borderSubtle,
                      ),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Listado de solicitudes
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGuinda,
                      ),
                    )
                  : _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay solicitudes en esta categoría',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryGuinda,
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final (statusLabel, badgeBg, badgeText) =
                              _statusBadge(req.status);

                          return GestureDetector(
                            onTap: () => _openDetailSheet(req),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        req.folio,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryGuinda,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: badgeText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    req.activityName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${req.department} · ${req.contactPerson}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if (req.services.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: req.services.map((s) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundCream,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            s.requiredDate != null
                                                ? '${s.serviceName} (${s.requiredDate})'
                                                : s.serviceName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
}

class _RequestDetailBottomSheet extends StatefulWidget {
  final AdminRequestModel request;
  final RequestManagementService service;

  const _RequestDetailBottomSheet({
    required this.request,
    required this.service,
  });

  @override
  State<_RequestDetailBottomSheet> createState() =>
      _RequestDetailBottomSheetState();
}

class _RequestDetailBottomSheetState extends State<_RequestDetailBottomSheet> {
  bool _isProcessing = false;

  TimeOfDay? _parseTimeOfDay(String? raw) {
    if (raw == null || !raw.contains(':')) return null;
    final parts = raw.split(':');
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await widget.service.updateRequestStatus(
        requestId: widget.request.id,
        folio: widget.request.folio,
        newStatus: newStatus,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Abre el modal prellenado con un servicio específico de la solicitud
  Future<void> _openScheduleSingleService(RequestItemDetail item) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));
    if (item.requiredDate != null) {
      final parsed = DateTime.tryParse(item.requiredDate!);
      if (parsed != null) initialDate = parsed;
    }

    final parsedStart = _parseTimeOfDay(item.scheduleTime);
    final initialStart = parsedStart ?? const TimeOfDay(hour: 10, minute: 0);
    final initialEnd = TimeOfDay(
      hour: (initialStart.hour + 1).clamp(0, 23),
      minute: initialStart.minute,
    );

    final scheduled = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFromRequestSheet(
        request: widget.request,
        service: widget.service,
        initialTitle:
            '${widget.request.folio} · ${item.serviceName} (${widget.request.activityName})',
        initialDate: initialDate,
        initialStartTime: initialStart,
        initialEndTime: initialEnd,
        initialLocation: item.location?.trim() ?? '',
        initialDescription: item.description.trim(),
      ),
    );

    if (scheduled == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _copySignedLink(RequestAttachmentItem att) async {
    try {
      final url = await widget.service.getSignedAttachmentUrl(att.fileUrl);
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enlace de descarga copiado: ${att.fileName}'),
          backgroundColor: AppColors.statusDoneText,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo obtener enlace: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Logotipos institucionales.
          const Center(
            child: InstitutionalLogos(height: 40, withBackground: true),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGuindaLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req.folio,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGuinda,
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
          Expanded(
            child: ListView(
              children: [
                Text(
                  req.activityName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${req.department} · ${req.contactPerson}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Servicios solicitados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                ...req.services.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                s.serviceName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryGuinda,
                                ),
                              ),
                            ),
                            if (s.requiredDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  s.requiredDate!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (s.location != null && s.location!.isNotEmpty)
                              Text(
                                'Lugar: ${s.location}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            if (s.scheduleTime != null &&
                                s.scheduleTime!.isNotEmpty)
                              Text(
                                'Hora: ${s.scheduleTime}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            if (s.dimensions != null &&
                                s.dimensions!.isNotEmpty)
                              Text(
                                'Medidas: ${s.dimensions}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            if (s.quantity > 1)
                              Text(
                                'Cantidad: ${s.quantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _openScheduleSingleService(s),
                            icon: const Icon(
                              Icons.event_available_rounded,
                              size: 16,
                            ),
                            label: Text(
                              'Agendar "${s.serviceName}"',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGuinda,
                              backgroundColor: AppColors.surfaceWhite,
                              side: BorderSide(
                                color: AppColors.primaryGuinda.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (req.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Archivos adjuntos (toca para copiar enlace de descarga)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...req.attachments.map((att) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      leading: const Icon(
                        Icons.file_present_rounded,
                        color: AppColors.primaryGuinda,
                      ),
                      title: Text(
                        att.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: const Icon(Icons.copy_rounded, size: 18),
                      onTap: () => _copySignedLink(att),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_isProcessing)
            const CircularProgressIndicator(color: AppColors.primaryGuinda)
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus('completed'),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Atendida'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusDoneText,
                      side: BorderSide(
                        color: AppColors.statusDoneText.withValues(alpha: 0.4),
                      ),
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
                    onPressed: () => _updateStatus('rejected'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: BorderSide(
                        color: AppColors.errorRed.withValues(alpha: 0.4),
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
      ),
    );
  }
}

class _ScheduleFromRequestSheet extends StatefulWidget {
  final AdminRequestModel request;
  final RequestManagementService service;
  final String initialTitle;
  final DateTime initialDate;
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;
  final String initialLocation;
  final String initialDescription;

  const _ScheduleFromRequestSheet({
    required this.request,
    required this.service,
    required this.initialTitle,
    required this.initialDate,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.initialLocation,
    required this.initialDescription,
  });

  @override
  State<_ScheduleFromRequestSheet> createState() =>
      _ScheduleFromRequestSheetState();
}

class _ScheduleFromRequestSheetState extends State<_ScheduleFromRequestSheet> {
  final _scheduleService = ScheduleService();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _locationController = TextEditingController(text: widget.initialLocation);
    _notesController = TextEditingController(text: widget.initialDescription);
    _selectedDate = widget.initialDate;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _saveToAgenda() async {
    final start = _combine(_selectedDate, _startTime);
    final end = _combine(_selectedDate, _endTime);

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser posterior a la de inicio.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final overlaps = await _scheduleService.findOverlappingEvents(
        startTime: start,
        endTime: end,
      );

      if (overlaps.isNotEmpty && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Empalme de horario'),
            content: Text(
              'Ya existe "${overlaps.first.title}" en ese horario. ¿Deseas agendarlo de todas formas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cambiar hora'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, agendar'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }
      }

      await widget.service.scheduleRequestInCalendar(
        request: widget.request,
        title: _titleController.text.trim(),
        description: _notesController.text.trim(),
        startTime: start,
        endTime: end,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio agendado en el calendario institucional'),
          backgroundColor: AppColors.statusDoneText,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agendar: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logotipos institucionales.
            const Center(
              child: InstitutionalLogos(height: 40, withBackground: true),
            ),

            const SizedBox(height: 16),

            const Text(
              'Agendar en calendario CyD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título en agenda'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (t != null) setState(() => _startTime = t);
                    },
                    child: Text('Inicio: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (t != null) setState(() => _endTime = t);
                    },
                    child: Text('Fin: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Lugar'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas operativas'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveToAgenda,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isSaving ? 'Guardando...' : 'Confirmar en agenda'),
            ),
          ],
        ),
      ),
    );
  }
}
