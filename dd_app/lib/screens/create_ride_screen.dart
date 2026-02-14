import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/ride_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/snackbar_helper.dart';

/// Pantalla para crear una nueva solicitud u oferta de viaje
class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  
  final _authService = AuthService();
  final _rideService = RideService();

  String _rideType = 'request'; // 'request' = busco conductor, 'offer' = ofrezco plazas
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _numberOfPeople = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final rideTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final ride = await _rideService.createRide(
        creatorId: userId,
        rideType: _rideType,
        location: _locationController.text.trim(),
        destination: _destinationController.text.trim(),
        time: rideTime,
        price: double.parse(_priceController.text),
        numberOfPeople: _numberOfPeople,
      );

      if (ride != null && mounted) {
        Navigator.pop(context);
        SnackBarHelper.showSuccess(
          context, 
          _rideType == 'request' 
            ? 'Solicitud creada exitosamente' 
            : 'Oferta publicada exitosamente',
        );
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
        title: Text(_rideType == 'request' ? 'Buscar Conductor' : 'Ofrecer Plazas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de tipo
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Ubicación de recogida
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación de recogida',
                  prefixIcon: const Icon(Icons.trip_origin, color: Colors.green),
                  hintText: 'Ej: Calle Mayor 123, Madrid',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Destino
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destino',
                  prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                  hintText: 'Ej: Aeropuerto de Madrid',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el destino';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Fecha y hora en fila
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Precio
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _rideType == 'request' 
                      ? 'Precio que ofreces (€)' 
                      : 'Precio por persona (€)',
                  prefixIcon: const Icon(Icons.euro),
                  hintText: 'Ej: 25.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el precio';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Número de personas/plazas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _rideType == 'request' 
                          ? '¿Cuántas personas sois?' 
                          : '¿Cuántas plazas ofreces?',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _numberOfPeople > 1
                              ? () => setState(() => _numberOfPeople--)
                              : null,
                          icon: Icon(
                            Icons.remove_circle,
                            color: _numberOfPeople > 1 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_numberOfPeople',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _numberOfPeople < 8
                              ? () => setState(() => _numberOfPeople++)
                              : null,
                          icon: Icon(
                            Icons.add_circle,
                            color: _numberOfPeople < 8 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Resumen
              _buildSummaryCard(),
              const SizedBox(height: 24),

              // Botón crear
              CustomButton(
                text: _rideType == 'request' ? 'Publicar Solicitud' : 'Publicar Oferta',
                onPressed: _isLoading ? null : _createRide,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _rideType = 'request'),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _rideType == 'request'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.hail,
                      color: _rideType == 'request' ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Busco Conductor',
                      style: TextStyle(
                        color: _rideType == 'request' ? Colors.white : Colors.grey,
                        fontWeight: _rideType == 'request' ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _rideType = 'offer'),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _rideType == 'offer'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: _rideType == 'offer' ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ofrezco Plazas',
                      style: TextStyle(
                        color: _rideType == 'offer' ? Colors.white : Colors.grey,
                        fontWeight: _rideType == 'offer' ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _rideType == 'request' ? Icons.hail : Icons.directions_car,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _rideType == 'request' ? 'Solicitud de conductor' : 'Oferta de plazas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildSummaryRow(Icons.trip_origin, 'Origen',
                _locationController.text.isEmpty ? '-' : _locationController.text,
                Colors.green),
            _buildSummaryRow(Icons.location_on, 'Destino',
                _destinationController.text.isEmpty ? '-' : _destinationController.text,
                Colors.red),
            _buildSummaryRow(Icons.calendar_today, 'Fecha',
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                Colors.blue),
            _buildSummaryRow(Icons.access_time, 'Hora',
                _selectedTime.format(context),
                Colors.orange),
            _buildSummaryRow(
                _rideType == 'request' ? Icons.group : Icons.event_seat, 
                _rideType == 'request' ? 'Personas' : 'Plazas',
                '$_numberOfPeople',
                Colors.purple),
            _buildSummaryRow(Icons.euro, 'Precio',
                _priceController.text.isEmpty ? '-' : '€${_priceController.text}',
                Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
