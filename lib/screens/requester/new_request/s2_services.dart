import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
  State<ServiceSelectionStep> createState() => _ServiceSelectionStepState();
}

class _ServiceSelectionStepState extends State<ServiceSelectionStep> {
  final ServiceCatalogService _catalogService = ServiceCatalogService();
  late Set<String> _selectedIds;
  ServiceCatalog? _catalog;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelection.map((service) => service.id).toSet();
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
      final availableIds = catalog.services.map((service) => service.id).toSet();

      setState(() {
        _catalog = catalog;
        _selectedIds.removeWhere((id) => !availableIds.contains(id));
        _isLoading = false;
      });
      widget.onSelectionChanged(_selectedServices);
    } catch (error) {
      debugPrint('Service catalog error: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar el catálogo de servicios.';
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
          content: Text('Selecciona al menos un servicio para continuar.'),
        ),
      );
      return;
    }
    widget.onNext();
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('video')) return Icons.videocam_outlined;
    if (value.contains('dise')) return Icons.palette_outlined;
    if (value.contains('cobertura')) return Icons.camera_alt_outlined;
    if (value.contains('protocolo')) return Icons.verified_outlined;
    return Icons.widgets_outlined;
  }

  Widget _buildCategory(ServiceCategory category) {
    final services = _catalog!.services
        .where((service) => service.categoryId == category.id)
        .toList();
    if (services.isEmpty) return const SizedBox.shrink();

    final selectedCount = services
        .where((service) => _selectedIds.contains(service.id))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(category.id),
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        iconColor: AppColors.primaryGuinda,
        collapsedIconColor: AppColors.textMuted,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryGuindaLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _categoryIcon(category.name),
            color: AppColors.primaryGuinda,
            size: 22,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '$selectedCount de ${services.length} seleccionados',
          style: TextStyle(
            color: selectedCount > 0
                ? AppColors.primaryGuinda
                : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          const Divider(height: 12, color: AppColors.borderSubtle),
          ...services.map((service) {
            final selected = _selectedIds.contains(service.id);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: CheckboxListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: selected ? AppColors.primaryGuindaLight : null,
                activeColor: AppColors.primaryGuinda,
                value: selected,
                title: Text(
                  service.name,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                onChanged: (value) {
                  _toggleService(service.id, value ?? false);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedSummary() {
    final selected = _selectedServices;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGuindaLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 19, color: AppColors.primaryGuinda),
              const SizedBox(width: 8),
              Text(
                'Seleccionados: ${selected.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGuinda,
                ),
              ),
            ],
          ),
          if (selected.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Elige los servicios que necesitas.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: selected.map((service) {
                return InputChip(
                  label: Text(service.name),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  deleteIconColor: AppColors.primaryGuinda,
                  onDeleted: () => _toggleService(service.id, false),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                foregroundColor: AppColors.primaryGuinda,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadCatalog, child: const Text('Reintentar')),
              TextButton(onPressed: widget.onBack, child: const Text('Volver')),
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
              const Text('No hay servicios disponibles.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCatalog,
                child: const Text('Actualizar catálogo'),
              ),
              TextButton(onPressed: widget.onBack, child: const Text('Volver')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            children: [
              const Text(
                'Seleccionar servicios',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Elige una o varias opciones por categoría.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ..._catalog!.categories.map(_buildCategory),
              const SizedBox(height: 6),
              _buildSelectedSummary(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        _footer(),
      ],
    );
  }
}
