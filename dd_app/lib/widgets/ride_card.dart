import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../core/constants.dart';

/// Tarjeta para mostrar información de un ride
class RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onTap;
  final bool showAcceptButton;
  final VoidCallback? onAccept;
  final bool showJoinButton;
  final VoidCallback? onJoin;

  const RideCard({
    super.key,
    required this.ride,
    this.onTap,
    this.showAcceptButton = false,
    this.onAccept,
    this.showJoinButton = false,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con tipo, estado y precio
              Row(
                children: [
                  _buildTypeChip(context),
                  const SizedBox(width: 8),
                  _buildStatusChip(context),
                  const Spacer(),
                  Text(
                    ride.formattedPrice,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Origen
              Row(
                children: [
                  const Icon(Icons.trip_origin, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.location,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Destino
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (ride.destination?.isNotEmpty ?? false) ? ride.destination! : 'Sin definir',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fecha y hora + personas/plazas
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(ride.time),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(
                    ride.isOffer ? Icons.event_seat : Icons.group, 
                    size: 20, 
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ride.isOffer 
                      ? '${ride.spotsRemaining}/${ride.numberOfPeople}' 
                      : '${ride.numberOfPeople}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              // Botón de aceptar (para conductores viendo solicitudes)
              if (showAcceptButton) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar solicitud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              // Botón de unirse (para pasajeros viendo ofertas)
              if (showJoinButton && ride.hasAvailableSpots) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.person_add),
                    label: Text('Unirme (${ride.spotsRemaining} plazas)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final isRequest = ride.isRequest;
    final color = isRequest ? Colors.amber : Colors.teal;
    final text = isRequest ? 'Solicitud' : 'Oferta';
    final icon = isRequest ? Icons.hail : Icons.directions_car;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String text;

    switch (ride.status) {
      case AppConstants.statusOpen:
        color = Colors.blue;
        text = 'Abierto';
        break;
      case AppConstants.statusAccepted:
        color = Colors.orange;
        text = 'Listo';
        break;
      case AppConstants.statusInProgress:
        color = Colors.indigo;
        text = 'En trayecto';
        break;
      case AppConstants.statusCompleted:
        color = Colors.green;
        text = 'Completado';
        break;
      case AppConstants.statusCancelled:
        color = Colors.red;
        text = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final rideDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (rideDate == today) {
      dateStr = 'Hoy';
    } else if (rideDate == tomorrow) {
      dateStr = 'Mañana';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dateStr a las $hour:$minute';
  }
}
