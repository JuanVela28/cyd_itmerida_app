
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeneralInfoData {
  final String department;
  final String contactPerson;
  final String activityName;

  const GeneralInfoData({
    required this.department,
    required this.contactPerson,
    required this.activityName,
  });
}

class GeneralInfoStep extends StatefulWidget {
  final String? initialActivityName;
  final ValueChanged<GeneralInfoData> onContinue;

  const GeneralInfoStep({
    super.key,
    this.initialActivityName,
    required this.onContinue,
  });

  @override
  State<GeneralInfoStep> createState() =>
      _GeneralInfoStepState();
}

class _GeneralInfoStepState extends State<GeneralInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _department = '';
  String _contactPerson = '';

  @override
  void initState() {
    super.initState();
    _activityController.text =
        widget.initialActivityName ?? '';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('No hay una sesión activa.');
      }

      final profile = await client
          .from('profiles')
          .select('full_name, department, role')
          .eq('id', user.id)
          .single();

      if (profile['role'] != 'requester') {
        throw Exception(
          'Tu cuenta no tiene permiso para crear solicitudes.',
        );
      }

      final name =
          (profile['full_name'] as String?)?.trim() ?? '';
      final department =
          (profile['department'] as String?)?.trim() ?? '';

      if (name.isEmpty || department.isEmpty) {
        throw Exception(
          'Tu perfil no tiene nombre o departamento asignado.',
        );
      }

      if (!mounted) return;

      setState(() {
        _contactPerson = name;
        _department = department;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'No se pudieron cargar los datos de tu perfil. '
            'Verifica tu conexión y tus permisos.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onContinue(
      GeneralInfoData(
        department: _department,
        contactPerson: _contactPerson,
        activityName: _activityController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(
            value: 0.2,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 16),

          Text(
            'Paso 1 de 5',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Datos generales',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            'Verifica tus datos y proporciona '
            'la información de la actividad.',
          ),

          const SizedBox(height: 24),

          TextFormField(
            initialValue: _department,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Departamento solicitante',
              prefixIcon: Icon(Icons.apartment),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            initialValue: _contactPerson,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Responsable de la solicitud',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            initialValue: formattedDate,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Fecha de elaboración',
              prefixIcon: Icon(Icons.today),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _activityController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Nombre de la actividad o evento',
              hintText: 'Ej. Congreso de Ingeniería',
              prefixIcon: Icon(Icons.event_note),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el nombre de la actividad.';
              }

              if (value.trim().length < 3) {
                return 'Escribe al menos 3 caracteres.';
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _continue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}
