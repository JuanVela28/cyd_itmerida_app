
import 'package:flutter/material.dart';

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
      : description = TextEditingController(
          text: data?.description ?? '',
        ),
        formatType = TextEditingController(
          text: data?.formatType ?? '',
        ),
        dimensions = TextEditingController(
          text: data?.dimensions ?? '',
        ),
        quantity = TextEditingController(
          text: data?.quantity?.toString() ?? '',
        ),
        location = TextEditingController(
          text: data?.location ?? '',
        ),
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
  State<ServiceDetailsStep> createState() =>
      _ServiceDetailsStepState();
}

class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, _ServiceFields> _fields;

  @override
  void initState() {
    super.initState();

    _fields = {
      for (final service in widget.services)
        service.id: _ServiceFields(
          widget.initialDetails[service.id],
        ),
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

    return _requiresAdvance(service)
        ? _addBusinessDays(today, 5)
        : today;
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
      for (final service in widget.services)
        service.id: _buildDetail(service),
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

  void _goBack() {
    widget.onBack(_collectDetails());
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa los campos obligatorios de cada servicio.',
          ),
        ),
      );
      return;
    }

    widget.onContinue(_collectDetails());
  }

  Widget _dateField(
    ServiceOption service,
    _ServiceFields fields,
  ) {
    final earliest = _minimumDate(service);

    return FormField<DateTime>(
      initialValue: fields.requiredDate,
      validator: (value) {
        if (value == null) {
          return 'Selecciona la fecha requerida.';
        }

        if (DateTime(
          value.year,
          value.month,
          value.day,
        ).isBefore(earliest)) {
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
            OutlinedButton.icon(
              onPressed: () async {
                final initial = date != null &&
                        !date.isBefore(earliest)
                    ? date
                    : earliest;

                final selected = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: earliest,
                  lastDate: DateTime(_today().year + 3, 12, 31),
                  helpText: 'Fecha requerida',
                );

                if (selected == null ||
                    !mounted ||
                    !field.mounted) {
                  return;
                }

                fields.requiredDate = selected;
                field.didChange(selected);
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                date == null
                    ? 'Seleccionar fecha requerida'
                    : 'Fecha: ${_formatDate(date)}',
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
    return OutlinedButton.icon(
      onPressed: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: fields.scheduleTime ?? TimeOfDay.now(),
          helpText: 'Hora del evento',
        );

        if (!mounted || selected == null) return;

        setState(() {
          fields.scheduleTime = selected;
        });
      },
      icon: const Icon(Icons.access_time_outlined),
      label: Text(
        fields.scheduleTime == null
            ? 'Seleccionar hora (opcional)'
            : 'Hora: ${fields.scheduleTime!.format(context)}',
      ),
    );
  }

  Widget _buildServiceCard(ServiceOption service) {
    final fields = _fields[service.id]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        maintainState: true,
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(service.categoryName),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: fields.description,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del servicio *',
                    hintText: 'Explica qué necesitas',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                const Text(
                  'Fecha requerida *',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                _dateField(service, fields),

                if (_requiresAdvance(service)) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Requiere al menos 5 días hábiles '
                    'de anticipación. No se descuentan '
                    'festivos institucionales todavía.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],

                const SizedBox(height: 16),

                TextFormField(
                  controller: fields.formatType,
                  decoration: const InputDecoration(
                    labelText: 'Formato de entrega (opcional)',
                    hintText: 'Ej. digital, impreso, horizontal',
                  ),
                  maxLength: 100,
                ),

                if (service.requiresDimensions) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fields.dimensions,
                    decoration: const InputDecoration(
                      labelText: 'Dimensiones *',
                      hintText: 'Ej. 2 m x 1 m',
                    ),
                    maxLength: 100,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Especifica las dimensiones.';
                      }
                      return null;
                    },
                  ),
                ],

                if (service.requiresQuantity) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fields.quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad *',
                      hintText: 'Ej. 50',
                    ),
                    validator: (value) {
                      final quantity =
                          int.tryParse(value?.trim() ?? '');

                      if (quantity == null || quantity <= 0) {
                        return 'Ingresa una cantidad válida.';
                      }

                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 12),

                TextFormField(
                  controller: fields.location,
                  decoration: const InputDecoration(
                    labelText: 'Lugar del evento (opcional)',
                    hintText: 'Ej. Auditorio principal',
                  ),
                  maxLength: 200,
                ),

                const SizedBox(height: 12),

                _timeField(fields),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 0.6,
              borderRadius: BorderRadius.circular(8),
            ),

            const SizedBox(height: 16),

            Text(
              'Paso 3 de 5',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Detalles de los servicios',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Completa la información de cada '
              'servicio seleccionado.',
            ),

            const SizedBox(height: 24),

            ...widget.services.map(_buildServiceCard),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
