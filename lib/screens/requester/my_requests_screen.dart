
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/requests/my_requests_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() =>
      _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final MyRequestsService _service = MyRequestsService();

  static const _filters = [
    ('all', 'Todas'),
    ('pending', 'Pendientes'),
    ('under_review', 'En revisión'),
    ('completed', 'Completadas'),
    ('rejected', 'Rechazadas'),
    ('cancelled', 'Canceladas'),
  ];

  List<MyRequest> _requests = [];
  String _selectedFilter = 'all';
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _service.fetchMyRequests();

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('My requests error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudieron cargar las solicitudes. '
            'Verifica tu conexión y los permisos de acceso.';
      });
    }
  }

  List<MyRequest> get _filteredRequests {
    if (_selectedFilter == 'all') {
      return _requests;
    }

    return _requests
        .where((request) => request.status == _selectedFilter)
        .toList();
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pendiente',
      'under_review' => 'En revisión',
      'completed' => 'Completada',
      'rejected' => 'Rechazada',
      'cancelled' => 'Cancelada',
      _ => 'Desconocido',
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => AppColors.statusPendingText,
      'under_review' => AppColors.statusReviewText,
      'completed' => AppColors.statusDoneText,
      'rejected' => AppColors.errorRed,
      _ => AppColors.textMuted,
    };
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Sin fecha';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) return raw;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _attachmentCategory(String value) {
    return switch (value) {
      'certificates_list' => 'Lista de alumnos',
      'event_photos_pdf' => 'Fotografías de evento',
      _ => 'Referencia general',
    };
  }

  void _showDetails(MyRequest request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    request.folio,
                    style: const TextStyle(
                      color: AppColors.primaryGuinda,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    request.activityName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: _statusBadge(request.status),
                  ),
                  const SizedBox(height: 12),

                  Text('Departamento: ${request.department}'),
                  Text(
                    'Fecha de solicitud: '
                    '${_formatDate(request.requestDate)}',
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Servicios (${request.services.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (request.services.isEmpty)
                    const Text('No hay servicios visibles.'),

                  ...request.services.map((service) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.design_services_outlined,
                          color: AppColors.primaryGuinda,
                        ),
                        title: Text(service.name),
                        subtitle: Text(
                          [
                            if (service.description.isNotEmpty)
                              service.description,
                            'Fecha requerida: '
                                '${_formatDate(service.requiredDate)}',
                            'Estado: ${_statusLabel(service.status)}',
                            if (service.dimensions != null)
                              'Dimensiones: ${service.dimensions}',
                            if (service.quantity != null)
                              'Cantidad: ${service.quantity}',
                            if (service.location != null)
                              'Lugar: ${service.location}',
                            if (service.scheduleTime != null)
                              'Hora: ${service.scheduleTime}',
                          ].join('\n'),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  Text(
                    'Archivos adjuntos '
                    '(${request.attachments.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (request.attachments.isEmpty)
                    const Text('Sin archivos registrados.'),

                  ...request.attachments.map(
                    (attachment) => ListTile(
                      leading: const Icon(
                        Icons.attach_file,
                        color: AppColors.primaryGuinda,
                      ),
                      title: Text(attachment.fileName),
                      subtitle: Text(
                        _attachmentCategory(attachment.category),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Historial de movimientos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (request.history.isEmpty)
                    const Text(
                      'No hay movimientos visibles para esta solicitud.',
                    ),

                  ...request.history.map((movement) {
                    final date = movement.createdAt;

                    return ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: AppColors.secondaryGold,
                      ),
                      title: Text(movement.action),
                      subtitle: Text(
                        [
                          if (date != null)
                            '${_formatDate(date.toIso8601String())} '
                                '${date.hour.toString().padLeft(2, '0')}:'
                                '${date.minute.toString().padLeft(2, '0')}',
                          if (movement.note != null)
                            movement.note!,
                        ].join('\n'),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(MyRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.folio,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGuinda,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _statusBadge(request.status),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                request.activityName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Fecha: ${_formatDate(request.requestDate)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${request.services.length} servicio(s)',
                style: const TextStyle(
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 12),

              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalles',
                    style: TextStyle(
                      color: AppColors.primaryGuinda,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryGuinda,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadRequests,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filters.map((filter) {
                  final selected = _selectedFilter == filter.$1;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.$2),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter.$1;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadRequests,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRequests,
                          child: filtered.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    const SizedBox(height: 90),
                                    const Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    const Center(
                                      child: Text(
                                        'No hay solicitudes para mostrar.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/requester/new'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Nueva solicitud'),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    return _buildRequestCard(
                                      filtered[index],
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
