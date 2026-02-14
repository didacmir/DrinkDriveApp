import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/snackbar_helper.dart';

/// Pantalla para editar una solicitud/oferta existente
class EditRideScreen extends StatefulWidget {
  final RideModel ride;

  const EditRideScreen({super.key, required this.ride});

  @override
  State<EditRideScreen> createState() => _EditRideScreenState();
}

class _EditRideScreenState extends State<EditRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  
  final _rideService = RideService();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _numberOfPeople;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.ride.location;
    _destinationController.text = widget.ride.destination ?? '';
    _priceController.text = widget.ride.price.toString();
    _selectedDate = widget.ride.time;
    _selectedTime = TimeOfDay(
      hour: widget.ride.time.hour,
      minute: widget.ride.time.minute,
    );
    _numberOfPeople = widget.ride.numberOfPeople;
  }

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rideTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final success = await _rideService.updateRide(
        widget.ride.id,
        location: _locationController.text.trim(),
        destination: _destinationController.text.trim(),
        time: rideTime,
        price: double.parse(_priceController.text),
        numberOfPeople: _numberOfPeople,
      );

      if (success && mounted) {
        SnackBarHelper.showSuccess(context, 'Actualizado correctamente');
        Navigator.pop(context, true);
      } else if (mounted) {
        SnackBarHelper.showError(context, 'Error al actualizar');
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
    final isOffer = widget.ride.isOffer;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${isOffer ? "Oferta" : "Solicitud"}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tipo (solo lectura)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isOffer ? Colors.teal : Colors.amber).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOffer ? Colors.teal : Colors.amber,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOffer ? Icons.directions_car : Icons.hail,
                      color: isOffer ? Colors.teal : Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOffer ? 'Oferta de plazas' : 'Solicitud de conductor',
                      style: TextStyle(
                        color: isOffer ? Colors.teal : Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ubicación
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación de recogida',
                  prefixIcon: const Icon(Icons.trip_origin, color: Colors.green),
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

              // Fecha y hora
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
                  labelText: isOffer ? 'Precio por persona (€)' : 'Precio que ofreces (€)',
                  prefixIcon: const Icon(Icons.euro),
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
                      isOffer ? '¿Cuántas plazas ofreces?' : '¿Cuántas personas sois?',
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
              const SizedBox(height: 32),

              // Botón guardar
              CustomButton(
                text: 'Guardar cambios',
                onPressed: _isLoading ? null : _saveChanges,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
