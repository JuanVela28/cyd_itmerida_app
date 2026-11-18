import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../features/requests/my_requests_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
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
  String _searchQuery = '';
  String _userName = 'Cargando perfil...';
  String _userDepartment = 'Consultando departamento...';
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadRequests();
  }

  // Solo consulta los datos públicos del perfil de la sesión actual.
  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _userName = 'Sin sesión activa';
          _userDepartment = 'Departamento no disponible';
        });
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('full_name, department')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final fullName = profile?['full_name']?.toString().trim() ?? '';
      final department = profile?['department']?.toString().trim() ?? '';

      setState(() {
        _userName = fullName.isEmpty ? 'Usuario' : fullName;
        _userDepartment = department.isEmpty
            ? 'Departamento no registrado'
            : department;
      });
    } catch (error) {
      debugPrint('My requests profile error: $error');
      if (!mounted) return;
      setState(() {
        _userName = 'Usuario';
        _userDepartment = 'No se pudo cargar el departamento';
      });
    }
  }

  // Conserva el servicio y el filtrado de solicitudes por usuario.
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

  Future<void> _refreshAll() async {
    await Future.wait<void>([
      _loadProfile(),
      _loadRequests(),
    ]);
  }

  List<MyRequest> get _filteredRequests {
    final search = _searchQuery.trim().toLowerCase();

    return _requests.where((request) {
      final matchesStatus = _selectedFilter == 'all' ||
          request.status == _selectedFilter;
      final matchesSearch = search.isEmpty ||
          request.folio.toLowerCase().contains(search) ||
          request.activityName.toLowerCase().contains(search);
      return matchesStatus && matchesSearch;
    }).toList();
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
    if (raw == null || raw.isEmpty) return 'Sin fecha';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // Ventana de detalles original: servicios, adjuntos e historial intactos.
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
                          if (movement.note != null) movement.note!,
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

  Widget _statistic(String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _isLoading ? '—' : '$count',
            style: const TextStyle(
              color: AppColors.primaryGuinda,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pending =
        _requests.where((request) => request.status == 'pending').length;
    final inReview = _requests
        .where((request) => request.status == 'under_review')
        .length;

    final userWords = _userName.trim().split(RegExp(r'\s+'));
    final initials = _userName == 'Cargando perfil...'
        ? '...'
        : userWords
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          decoration: const BoxDecoration(
          color: AppColors.primaryGuinda,
          borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de acciones integrada al encabezado institucional.
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Volver al inicio',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Text(
                      'CyD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isLoading ? null : _refreshAll,
                    tooltip: 'Actualizar solicitudes',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white54,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'DEPARTAMENTO DE COMUNICACIÓN Y DIFUSIÓN',
                style: TextStyle(
                  color: AppColors.secondaryGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mis solicitudes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Consulta el avance de tus trámites institucionales.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryGuindaLight,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primaryGuinda,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SESIÓN ACTIVA',
                            style: TextStyle(
                              color: AppColors.secondaryGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.apartment_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _userDepartment,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statistic('Total', _requests.length),
                    _statistic('Pendientes', pending),
                    _statistic('En revisión', inReview),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(MyRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: AppColors.surfaceWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        onTap: () => _showDetails(request),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.secondaryGold, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGuindaLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primaryGuinda,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      request.folio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryGuinda,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _statusBadge(request.status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                request.activityName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                request.department,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: AppColors.secondaryGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(request.requestDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: AppColors.secondaryGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${request.services.length} servicio(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 13),
              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalles',
                    style: TextStyle(
                      color: AppColors.primaryGuinda,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.secondaryGold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encuentra tu solicitud',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: const InputDecoration(
              hintText: 'Buscar por folio o actividad...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primaryGuinda,
              ),
              filled: true,
              fillColor: AppColors.surfaceWhite,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((filter) {
                final selected = _selectedFilter == filter.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.$2),
                    selected: selected,
                    selectedColor: AppColors.primaryGuinda,
                    backgroundColor: AppColors.surfaceWhite,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryGuinda
                          : AppColors.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryGuinda,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: Stack(
          children: [
            // Colorea solo el área de la barra de estado, sin afectar
            // las tarjetas cuando se desplaza la lista.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top,
              child: const ColoredBox(color: AppColors.primaryGuinda),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: RefreshIndicator(
                    onRefresh: _refreshAll,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildSearchAndFilters()),
                        if (_isLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 52),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        else if (_errorMessage != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: AppColors.errorRed,
                                  ),
                                  const SizedBox(height: 12),
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
                        else if (filtered.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.inbox_outlined,
                                    size: 60,
                                    color: AppColors.secondaryGold,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No hay solicitudes para mostrar.',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _requests.isEmpty
                                        ? 'Cuando registres una solicitud, aparecerá aquí.'
                                        : 'Prueba con otro filtro o búsqueda.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if (_requests.isEmpty) ...[
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/requester/new'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Nueva solicitud'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildRequestCard(filtered[index]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ), // ConstrainedBox
              ), // Center
            ), // SafeArea
          ], // Stack children
        ), // Stack
      ), // Scaffold
    ); // AnnotatedRegion
  }
}