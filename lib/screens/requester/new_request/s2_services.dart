
import 'package:flutter/material.dart';

import '../../../features/requests/service_catalog_service.dart';

class ServiceSelectionStep extends StatefulWidget {
  final List<ServiceOption> initialSelection;
  final ValueChanged<List<ServiceOption>> onSelectionChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ServiceSelectionStep({
    super.key,
    required this.initialSelection,
    required this.onSelectionChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<ServiceSelectionStep> createState() =>
      _ServiceSelectionStepState();
}

class _ServiceSelectionStepState
    extends State<ServiceSelectionStep> {
  final ServiceCatalogService _catalogService =
      ServiceCatalogService();

  late Set<String> _selectedIds;

  ServiceCatalog? _catalog;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _selectedIds = widget.initialSelection
        .map((service) => service.id)
        .toSet();

    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catalog = await _catalogService.fetchCatalog();

      if (!mounted) return;

      final availableIds = catalog.services
          .map((service) => service.id)
          .toSet();

      setState(() {
        _catalog = catalog;
        _selectedIds.removeWhere(
          (id) => !availableIds.contains(id),
        );
        _isLoading = false;
      });

      widget.onSelectionChanged(_selectedServices);
    } catch (error) {
      debugPrint('Service catalog error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudo cargar el catálogo de servicios.';
      });
    }
  }

  List<ServiceOption> get _selectedServices {
    if (_catalog == null) return [];

    return _catalog!.services
        .where((service) => _selectedIds.contains(service.id))
        .toList();
  }

  void _toggleService(String serviceId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(serviceId);
      } else {
        _selectedIds.remove(serviceId);
      }
    });

    widget.onSelectionChanged(_selectedServices);
  }

  void _continue() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona al menos un servicio para continuar.',
          ),
        ),
      );
      return;
    }

    widget.onNext();
  }

  Widget _buildCategory(ServiceCategory category) {
    final services = _catalog!.services
        .where((service) => service.categoryId == category.id)
        .toList();

    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCount = services
        .where((service) => _selectedIds.contains(service.id))
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(category.id),
        initiallyExpanded: true,
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$selectedCount de ${services.length} seleccionados',
        ),
        children: services.map((service) {
          final isSelected = _selectedIds.contains(service.id);

          return CheckboxListTile(
  value: isSelected,
  controlAffinity: ListTileControlAffinity.leading,
  title: Text(service.name),
  onChanged: (value) {
    _toggleService(service.id, value ?? false);
  },
);
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedSummary() {
    final selected = _selectedServices;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servicios seleccionados (${selected.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (selected.isEmpty)
              const Text(
                'Todavía no has seleccionado servicios.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected.map((service) {
                  return InputChip(
                    label: Text(service.name),
                    onDeleted: () {
                      _toggleService(service.id, false);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCatalog,
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: widget.onBack,
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    if (_catalog == null ||
        _catalog!.categories.isEmpty ||
        _catalog!.services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No hay servicios disponibles.',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCatalog,
                child: const Text('Actualizar catálogo'),
              ),
              TextButton(
                onPressed: widget.onBack,
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(
          value: 0.4,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 16),

        Text(
          'Paso 2 de 5',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Seleccionar servicios',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Selecciona uno o varios servicios de '
          'Comunicación y Difusión.',
        ),

        const SizedBox(height: 24),

        ..._catalog!.categories.map(_buildCategory),

        const SizedBox(height: 12),

        _buildSelectedSummary(),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continue,
                child: const Text('Siguiente'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
