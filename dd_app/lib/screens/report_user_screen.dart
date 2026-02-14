import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/snackbar_helper.dart';

/// Pantalla para reportar un usuario
class ReportUserScreen extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;

  const ReportUserScreen({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _reportService = ReportService();

  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Comportamiento inapropiado',
    'No se presentó al servicio',
    'Conducción peligrosa',
    'Vehículo en mal estado',
    'Fraude o estafa',
    'Acoso o amenazas',
    'Otro',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      SnackBarHelper.showWarning(context, 'Selecciona un motivo');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Aquí deberías obtener el ID del usuario actual
      final success = await _reportService.createReport(
        reportedUserId: widget.reportedUserId,
        reporterUserId: 'currentUserId', // TODO: Obtener del AuthService
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        if (success) {
          SnackBarHelper.showSuccess(context, 'Reporte enviado correctamente');
          Navigator.pop(context);
        } else {
          SnackBarHelper.showError(context, 'Error al enviar el reporte');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info del usuario reportado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reportando a:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.reportedUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selección de motivo
              Text(
                'Motivo del reporte',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...(_reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ))),

              const SizedBox(height: 24),

              // Descripción opcional
              Text(
                'Descripción (opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Añade más detalles sobre lo ocurrido...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón enviar
              CustomButton(
                text: 'Enviar Reporte',
                onPressed: _isLoading ? null : _submitReport,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              // Nota
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los reportes son revisados por nuestro equipo. '
                        'Los reportes falsos pueden resultar en suspensión de cuenta.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
