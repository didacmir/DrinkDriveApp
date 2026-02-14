import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/snackbar_helper.dart';

/// Pantalla de verificación de conductor
class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _licenseUploaded = false;
  String _step = 'license'; // 'license', 'car', 'review'

  @override
  void dispose() {
    _carModelController.dispose();
    _carPlateController.dispose();
    super.dispose();
  }

  Future<void> _uploadLicense() async {
    // En una implementación real, aquí se abriría el selector de imágenes
    // y se subiría a Firebase Storage
    
    setState(() {
      _isLoading = true;
    });

    // Simular carga
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _licenseUploaded = true;
        _step = 'car';
      });
      SnackBarHelper.showSuccess(context, 'Carnet subido correctamente');
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Actualizar datos del usuario en Firestore
      // En una app real, también se subiría la imagen del carnet
      
      // Simular envío
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _step = 'review';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarHelper.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Conductor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 'license':
        return _buildLicenseStep();
      case 'car':
        return _buildCarStep();
      case 'review':
        return _buildReviewStep();
      default:
        return _buildLicenseStep();
    }
  }

  Widget _buildLicenseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(1),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.badge,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Sube tu carnet de conducir',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        Text(
          'Necesitamos verificar que tienes un carnet de conducir válido.',
          style: TextStyle(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Área de subida
        InkWell(
          onTap: _isLoading ? null : _uploadLicense,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _licenseUploaded ? Colors.green : Colors.grey,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _licenseUploaded ? Icons.check_circle : Icons.cloud_upload,
                        size: 48,
                        color: _licenseUploaded ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _licenseUploaded
                            ? 'Carnet subido'
                            : 'Toca para subir imagen',
                        style: TextStyle(
                          color: _licenseUploaded ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),

        if (_licenseUploaded)
          CustomButton(
            text: 'Continuar',
            onPressed: () {
              setState(() {
                _step = 'car';
              });
            },
          ),
      ],
    );
  }

  Widget _buildCarStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(2),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Datos de tu vehículo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Ingresa los datos de tu coche para que los pasajeros puedan identificarte.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Modelo de coche
          TextFormField(
            controller: _carModelController,
            decoration: InputDecoration(
              labelText: 'Modelo del coche',
              hintText: 'Ej: Toyota Corolla 2020',
              prefixIcon: const Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el modelo del coche';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Matrícula
          TextFormField(
            controller: _carPlateController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Matrícula',
              hintText: 'Ej: 1234 ABC',
              prefixIcon: const Icon(Icons.pin),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa la matrícula';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: 'Enviar para verificación',
            onPressed: _isLoading ? null : _submitVerification,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepIndicator(3),
        const SizedBox(height: 48),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_top,
            size: 60,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'En revisión',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        Text(
          'Tu solicitud de verificación ha sido enviada. '
          'Te notificaremos cuando sea aprobada.',
          style: TextStyle(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Tiempo estimado: 24-48 horas'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Recibirás una notificación'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        CustomButton(
          text: 'Volver al inicio',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, currentStep >= 1, 'Carnet'),
        _buildStepLine(currentStep >= 2),
        _buildStepCircle(2, currentStep >= 2, 'Coche'),
        _buildStepLine(currentStep >= 3),
        _buildStepCircle(3, currentStep >= 3, 'Revisión'),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool active, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: active
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.withOpacity(0.3),
    );
  }
}
