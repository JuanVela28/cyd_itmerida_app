
import 'package:flutter/material.dart';

import '../../../features/requests/service_catalog_service.dart';
import 's1_general_info.dart';
import 's2_services.dart';
import 's3_service_details.dart';
import 's4_attachments.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() =>
      _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  int _currentStep = 0;

  GeneralInfoData? _generalInfo;
  List<ServiceOption> _selectedServices = [];
  Map<String, ServiceDetailData> _serviceDetails = {};
  List<PendingAttachment> _attachments = [];

  void _saveGeneralInfo(GeneralInfoData data) {
    setState(() {
      _generalInfo = data;
      _currentStep = 1;
    });
  }

  void _saveServices(List<ServiceOption> services) {
    _selectedServices = List.of(services);

    final selectedIds = services
        .map((service) => service.id)
        .toSet();

    _serviceDetails.removeWhere(
      (id, detail) => !selectedIds.contains(id),
    );
    final requiresStudentList = services.any((service) {
  final name = service.name.trim().toLowerCase();
  return name == 'constancias' || name == 'carpetas';
});

if (!requiresStudentList) {
  _attachments.removeWhere(
    (item) =>
        item.category == AttachmentCategory.certificatesList,
  );
}
  }

  

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _saveDetailsAndBack(
    Map<String, ServiceDetailData> details,
  ) {
    setState(() {
      _serviceDetails = details;
      _currentStep = 1;
    });
  }

  void _saveDetailsAndContinue(
    Map<String, ServiceDetailData> details,
  ) {
    setState(() {
      _serviceDetails = details;
      _currentStep = 3;
    });
  }
  void _saveAttachmentsAndBack(
  List<PendingAttachment> attachments,
) {
  setState(() {
    _attachments = List.of(attachments);
    _currentStep = 2;
  });
}

void _saveAttachmentsAndContinue(
  List<PendingAttachment> attachments,
) {
  setState(() {
    _attachments = List.of(attachments);
    _currentStep = 4;
  });
}

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_currentStep == 0) {
      content = GeneralInfoStep(
        initialActivityName: _generalInfo?.activityName,
        onContinue: _saveGeneralInfo,
      );
    } else if (_currentStep == 1) {
      content = ServiceSelectionStep(
        initialSelection: _selectedServices,
        onSelectionChanged: _saveServices,
        onBack: () => _goToStep(0),
        onNext: () => _goToStep(2),
      );
    } else if (_currentStep == 2) {
      content = ServiceDetailsStep(
        services: _selectedServices,
        initialDetails: _serviceDetails,
        onBack: _saveDetailsAndBack,
        onContinue: _saveDetailsAndContinue,
      );
   } else if (_currentStep == 3) {
  content = AttachmentsStep(
    services: _selectedServices,
    initialAttachments: _attachments,
    onBack: _saveAttachmentsAndBack,
    onContinue: _saveAttachmentsAndContinue,
  );
} else {
  content = _buildStep5Preview();
}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva solicitud'),
      ),
      body: SafeArea(
        child: content,
      ),
    );
  }

  Widget _buildStep5Preview() {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(
          value: 0.8,
          borderRadius: BorderRadius.circular(8),
        ),

        const SizedBox(height: 16),

        Text(
          'Paso 5 de 5',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Detalles registrados',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Vista previa temporal. Todavía no se ha '
          'enviado ninguna solicitud.',
        ),

        const SizedBox(height: 24),

        ..._selectedServices.map((service) {
          final detail = _serviceDetails[service.id];

          return Card(
            child: ListTile(
              title: Text(service.name),
              subtitle: Text(
                '${detail?.description ?? ""}\n'
                'Fecha: ${_formatDate(detail?.requiredDate)}',
              ),
            ),
          );
        }),
            const SizedBox(height: 16),

Text(
  'Archivos adjuntos (${_attachments.length})',
  style: const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 8),

if (_attachments.isEmpty)
  const Text('No se agregaron archivos opcionales.'),

..._attachments.map(
  (attachment) => ListTile(
    leading: const Icon(Icons.attach_file),
    title: Text(attachment.file.name),
  ),
),
        const SizedBox(height: 24),

        OutlinedButton(
          onPressed: () => _goToStep(3),
          child: const Text('Volver a archivos adjuntos'),
        ),
      ],
    );
  }
}
