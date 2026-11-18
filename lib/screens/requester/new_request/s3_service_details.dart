import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/requests/service_catalog_service.dart';

class ServiceDetailData {
  final String serviceId;
  final String description;
  final DateTime? requiredDate;
  final String? formatType;
  final String? dimensions;
  final int? quantity;
  final String? location;
  final TimeOfDay? scheduleTime;

  const ServiceDetailData({
    required this.serviceId,
    required this.description,
    required this.requiredDate,
    this.formatType,
    this.dimensions,
    this.quantity,
    this.location,
    this.scheduleTime,
  });
}

class _ServiceFields {
  final TextEditingController description;
  final TextEditingController formatType;
  final TextEditingController dimensions;
  final TextEditingController quantity;
  final TextEditingController location;

  DateTime? requiredDate;
  TimeOfDay? scheduleTime;

  _ServiceFields(ServiceDetailData? data)
      : description = TextEditingController(text: data?.description ?? ''),
        formatType = TextEditingController(text: data?.formatType ?? ''),
        dimensions = TextEditingController(text: data?.dimensions ?? ''),
        quantity = TextEditingController(text: data?.quantity?.toString() ?? ''),
        location = TextEditingController(text: data?.location ?? ''),
        requiredDate = data?.requiredDate,
        scheduleTime = data?.scheduleTime;

  void dispose() {
    description.dispose();
    formatType.dispose();
    dimensions.dispose();
    quantity.dispose();
    location.dispose();
  }
}

class ServiceDetailsStep extends StatefulWidget {
  final List<ServiceOption> services;
  final Map<String, ServiceDetailData> initialDetails;
  final ValueChanged<Map<String, ServiceDetailData>> onBack;
  final ValueChanged<Map<String, ServiceDetailData>> onContinue;

  const ServiceDetailsStep({
    super.key,
    required this.services,
    required this.initialDetails,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<ServiceDetailsStep> createState() => _ServiceDetailsStepState();
}

class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, _ServiceFields> _fields;

  @override
  void initState() {
    super.initState();
    _fields = {
      for (final service in widget.services)
        service.id: _ServiceFields(widget.initialDetails[service.id]),
    };
  }

  @override
  void dispose() {
    for (final fields in _fields.values) {
      fields.dispose();
    }
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _addBusinessDays(DateTime start, int days) {
    var date = start;
    var remaining = days;
    while (remaining > 0) {
      date = date.add(const Duration(days: 1));
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        remaining--;
      }
    }
    return date;
  }

  bool _requiresAdvance(ServiceOption service) {
    final category = service.categoryName.trim().toLowerCase();
    final name = service.name.trim().toLowerCase();
    return category == 'diseño' || name == 'constancias';
  }

  DateTime _minimumDate(ServiceOption service) {
    final today = _today();
    return _requiresAdvance(service) ? _addBusinessDays(today, 5) : today;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Map<String, ServiceDetailData> _collectDetails() {
    return {
      for (final service in widget.services) service.id: _buildDetail(service),
    };
  }

  ServiceDetailData _buildDetail(ServiceOption service) {
    final fields = _fields[service.id]!;
    final quantity = int.tryParse(fields.quantity.text.trim());
    return ServiceDetailData(
      serviceId: service.id,
      description: fields.description.text.trim(),
      requiredDate: fields.requiredDate,
      formatType: _optionalText(fields.formatType.text),
      dimensions: service.requiresDimensions
          ? _optionalText(fields.dimensions.text)
          : null,
      quantity: service.requiresQuantity ? quantity : null,
      location: _optionalText(fields.location.text),
      scheduleTime: fields.scheduleTime,
    );
  }

  void _goBack() => widget.onBack(_collectDetails());

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos obligatorios de cada servicio.'),
        ),
      );
      return;
    }
    widget.onContinue(_collectDetails());
  }

  Widget _fieldLabel(String title, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: AppColors.errorRed)),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 18, color: AppColors.textMuted),
      fillColor: AppColors.surfaceWhite,
      filled: true,
    );
  }

  Widget _dateField(ServiceOption service, _ServiceFields fields) {
    final earliest = _minimumDate(service);
    return FormField<DateTime>(
      initialValue: fields.requiredDate,
      validator: (value) {
        if (value == null) return 'Selecciona la fecha requerida.';
        if (DateTime(value.year, value.month, value.day).isBefore(earliest)) {
          return _requiresAdvance(service)
              ? 'Este servicio requiere 5 días hábiles de anticipación.'
              : 'La fecha no puede ser anterior a hoy.';
        }
        return null;
      },
      builder: (field) {
        final date = field.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceWhite,
                  foregroundColor: AppColors.primaryGuinda,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final initial = date != null && !date.isBefore(earliest)
                      ? date
                      : earliest;
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: earliest,
                    lastDate: DateTime(_today().year + 3, 12, 31),
                    helpText: 'Fecha requerida',
                  );
                  if (selected == null || !mounted || !field.mounted) return;
                  fields.requiredDate = selected;
                  field.didChange(selected);
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 19),
                label: Text(
                  date == null
                      ? 'Seleccionar fecha requerida'
                      : 'Fecha: ${_formatDate(date)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _timeField(_ServiceFields fields) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceWhite,
          foregroundColor: AppColors.primaryGuinda,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final selected = await showTimePicker(
            context: context,
            initialTime: fields.scheduleTime ?? TimeOfDay.now(),
            helpText: 'Hora del evento',
          );
          if (!mounted || selected == null) return;
          setState(() => fields.scheduleTime = selected);
        },
        icon: const Icon(Icons.access_time_outlined, size: 19),
        label: Text(
          fields.scheduleTime == null
              ? 'Seleccionar hora (opcional)'
              : 'Hora: ${fields.scheduleTime!.format(context)}',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceOption service) {
    final fields = _fields[service.id]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        iconColor: AppColors.primaryGuinda,
        collapsedIconColor: AppColors.textMuted,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          service.name,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          service.categoryName,
          style: const TextStyle(
            color: AppColors.secondaryGold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Descripción del servicio', required: true),
                TextFormField(
                  controller: fields.description,
                  decoration: _fieldDecoration('Explica qué necesitas'),
                  maxLines: 3,
                  maxLength: 1000,
                  style: const TextStyle(fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _fieldLabel('Fecha requerida', required: true),
                _dateField(service, fields),
                if (_requiresAdvance(service)) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusPendingBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Este servicio requiere 5 días hábiles de '
                      'anticipación. Los festivos institucionales '
                      'aún no se descuentan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.statusPendingText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _fieldLabel('Formato de entrega (opcional)'),
                TextFormField(
                  controller: fields.formatType,
                  decoration: _fieldDecoration('Ej. digital, impreso, horizontal'),
                  maxLength: 100,
                  style: const TextStyle(fontSize: 14),
                ),
                if (service.requiresDimensions) ...[
                  const SizedBox(height: 6),
                  _fieldLabel('Dimensiones', required: true),
                  TextFormField(
                    controller: fields.dimensions,
                    decoration: _fieldDecoration('Ej. 2 m x 1 m'),
                    maxLength: 100,
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Especifica las dimensiones.';
                      }
                      return null;
                    },
                  ),
                ],
                if (service.requiresQuantity) ...[
                  const SizedBox(height: 6),
                  _fieldLabel('Cantidad', required: true),
                  TextFormField(
                    controller: fields.quantity,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('Ej. 50'),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Ingresa una cantidad válida.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                _fieldLabel('Lugar del evento (opcional)'),
                TextFormField(
                  controller: fields.location,
                  decoration: _fieldDecoration('Ej. Auditorio principal'),
                  maxLength: 200,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _fieldLabel('Hora del evento (opcional)'),
                _timeField(fields),
              ],
            ),
          ),
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
              onPressed: _goBack,
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles de los servicios',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Completa los datos de cada servicio seleccionado.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ...widget.services.map(_buildServiceCard),
                ],
              ),
            ),
          ),
        ),
        _footer(),
      ],
    );
  }
}
