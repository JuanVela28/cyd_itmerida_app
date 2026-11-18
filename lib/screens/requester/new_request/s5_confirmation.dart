import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/requests/request_submission_service.dart';
import '../../../features/requests/service_catalog_service.dart';
import 's1_general_info.dart';
import 's3_service_details.dart';
import 's4_attachments.dart';

class ConfirmationStep extends StatefulWidget {
  final GeneralInfoData generalInfo;
  final List<ServiceOption> services;
  final Map<String, ServiceDetailData> details;
  final List<PendingAttachment> attachments;
  final VoidCallback onBack;

  const ConfirmationStep({
    super.key,
    required this.generalInfo,
    required this.services,
    required this.details,
    required this.attachments,
    required this.onBack,
  });

  @override
  State<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends State<ConfirmationStep> {
  final _submissionService = RequestSubmissionService();
  bool _isSubmitting = false;
  bool _partialSubmission = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final folio = await _submissionService.submitRequest(
        generalInfo: widget.generalInfo,
        services: widget.services,
        details: widget.details,
        attachments: widget.attachments,
      );

      if (!mounted) return;
      await _showSuccessDialog(folio);
    } catch (e) {
      if (!mounted) return;

      final isPartial = e is PartialSubmissionException;

      setState(() {
        _isSubmitting = false;
        _partialSubmission = isPartial;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            isPartial
                ? 'Solicitud parcialmente registrada'
                : 'Error al enviar solicitud',
          ),
          content: Text(
            isPartial
                ? 'Se creó la solicitud con folio ${e.folio}, '
                      'pero no se completaron todos sus datos '
                      'o archivos. No vuelvas a enviarla. '
                      'Comunícate con el administrador para '
                      'revisar este folio.'
                : 'No se pudo completar el envío: $e',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showSuccessDialog(String folio) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.statusDoneBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.statusDoneText,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Solicitud enviada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu trámite ha sido registrado correctamente con el folio:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryGuindaLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                folio,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGuinda,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/requester');
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Revisión y confirmación',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Verifica que toda la información esté correcta antes de generar tu folio.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        // 1. Resumen de Datos Generales
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DATOS GENERALES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryGold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              _infoRow('Actividad', widget.generalInfo.activityName),
              const SizedBox(height: 6),
              _infoRow('Departamento', widget.generalInfo.department),
              const SizedBox(height: 6),
              _infoRow('Responsable', widget.generalInfo.contactPerson),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Resumen de Servicios Solicitados
        Text(
          'Servicios solicitados (${widget.services.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        ...widget.services.map((service) {
          final d = widget.details[service.id];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGuindaLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGuinda,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Fecha: ${_formatDate(d?.requiredDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                if (d != null && d.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    d.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (d?.location != null ||
                    d?.dimensions != null ||
                    d?.quantity != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (d?.location != null)
                        Text(
                          'Lugar: ${d!.location}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (d?.dimensions != null)
                        Text(
                          'Medidas: ${d!.dimensions}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (d?.quantity != null)
                        Text(
                          'Cantidad: ${d!.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // 3. Resumen de Archivos Adjuntos
        Text(
          'Archivos adjuntos (${widget.attachments.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.attachments.isEmpty)
          const Text(
            'Sin archivos adjuntos.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          )
        else
          ...widget.attachments.map(
            (att) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 20,
                    color: AppColors.primaryGuinda,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      att.file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 28),

        // Botones de navegación y envío final
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting || _partialSubmission ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSubmitting ? 'Enviando...' : 'Enviar solicitud'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
