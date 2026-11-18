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
    setState(() => _currentStep = step);
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
    final baseTheme = Theme.of(context);

    // La tipografia Roboto se aplica solo a este asistente de solicitud.
    // No modifica el diseño de inicio, login, administración ni seguimiento.
    final requestTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'Roboto'),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
      ),
    );

    return Theme(
      data: requestTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Material(
                          color: AppColors.backgroundCream,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Nueva solicitud',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGuindaLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentStep + 1} de 5',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryGuinda,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGuinda,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}