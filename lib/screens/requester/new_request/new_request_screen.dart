import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/requests/service_catalog_service.dart';
import 's1_general_info.dart';
import 's2_services.dart';
import 's3_service_details.dart';
import 's4_attachments.dart';
import 's5_confirmation.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
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

    final selectedIds = services.map((service) => service.id).toSet();

    _serviceDetails.removeWhere((id, detail) => !selectedIds.contains(id));
    final requiresStudentList = services.any((service) {
      final name = service.name.trim().toLowerCase();
      return name == 'constancias' || name == 'carpetas';
    });

    if (!requiresStudentList) {
      _attachments.removeWhere(
        (item) => item.category == AttachmentCategory.certificatesList,
      );
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _saveDetailsAndBack(Map<String, ServiceDetailData> details) {
    setState(() {
      _serviceDetails = details;
      _currentStep = 1;
    });
  }

  void _saveDetailsAndContinue(Map<String, ServiceDetailData> details) {
    setState(() {
      _serviceDetails = details;
      _currentStep = 3;
    });
  }

  void _saveAttachmentsAndBack(List<PendingAttachment> attachments) {
    setState(() {
      _attachments = List.of(attachments);
      _currentStep = 2;
    });
  }

  void _saveAttachmentsAndContinue(List<PendingAttachment> attachments) {
    setState(() {
      _attachments = List.of(attachments);
      _currentStep = 4;
    });
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
      content = ConfirmationStep(
        generalInfo: _generalInfo!,
        services: _selectedServices,
        details: _serviceDetails,
        attachments: _attachments,
        onBack: () => _goToStep(3),
      );
    }

    final progress = (_currentStep + 1) / 5;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado limpio estilo Figma (sin AppBar guinda plano)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Material(
                        color: AppColors.surfaceWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (_currentStep > 0) {
                              _goToStep(_currentStep - 1);
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PASO ${_currentStep + 1} DE 5',
                              style: const TextStyle(
                                color: AppColors.secondaryGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Nueva solicitud',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGuinda,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del paso activo
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
