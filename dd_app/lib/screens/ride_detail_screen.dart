import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ride_service.dart';
import '../services/review_service.dart';
import '../services/chat_service.dart';
import '../core/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/snackbar_helper.dart';
import 'edit_ride_screen.dart';
import 'chat_screen.dart';

/// Pantalla de detalle de un viaje/solicitud
class RideDetailScreen extends StatefulWidget {
  final RideModel ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final _authService = AuthService();
  final _rideService = RideService();
  final _reviewService = ReviewService();
  final _chatService = ChatService();
  
  late RideModel _ride;
  UserModel? _currentUser;
  UserModel? _creatorUser;
  Map<String, UserModel> _participants = {};
  Map<String, bool> _hasReviewed = {};
  bool _isLoading = true;
  
  // Para el sistema de reviews
  String? _reviewingUserId;
  int _rating = 0;
  final _commentController = TextEditingController;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _loadData();
    _listenToRide();
  }

  void _listenToRide() {
    _rideService.getRideStream(_ride.id).listen((updatedRide) {
      if (updatedRide != null && mounted) {
        setState(() {
          _ride = updatedRide;
        });
        _loadParticipants();
      }
    });
  }

  Future<void> _loadData() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _currentUser = await _authService.getUserData(userId);
      _creatorUser = await _authService.getUserData(_ride.creatorId);
      await _loadParticipants();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadParticipants() async {
    final participants = <String, UserModel>{};
    final userId = _currentUser?.id;
    
    for (final participantId in _ride.allParticipants) {
      final user = await _authService.getUserData(participantId);
      if (user != null) {
        participants[participantId] = user;
      }
      
      // Verificar reviews existentes
      if (userId != null && participantId != userId) {
        final hasReviewed = await _reviewService.hasReviewed(
          rideId: _ride.id,
          fromUserId: userId,
          toUserId: participantId,
        );
        _hasReviewed[participantId] = hasReviewed;
      }
    }
    
    setState(() {
      _participants = participants;
    });
  }

  bool get _isCreator => _currentUser?.id == _ride.creatorId;
  
  bool get _hasJoined => _ride.acceptedPassengers.contains(_currentUser?.id);

  bool get _isParticipant => _ride.allParticipants.contains(_currentUser?.id);

  bool get _hasConfirmedStart => _currentUser != null && _ride.hasUserStarted(_currentUser!.id);

  bool get _hasConfirmedComplete => _currentUser != null && _ride.hasUserCompleted(_currentUser!.id);

  Future<void> _acceptRequest() async {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) return;

    setState(() => _isLoading = true);

    final success = await _rideService.acceptRequest(_ride.id, driverId);
    
    if (success) {
      setState(() {
        _ride = _ride.copyWith(
          status: AppConstants.statusAccepted,
          driverId: driverId,
        );
      });
      await _loadData();
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Solicitud aceptada');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _joinOffer() async {
    final passengerId = _authService.currentUser?.uid;
    if (passengerId == null) return;

    setState(() => _isLoading = true);

    final success = await _rideService.joinOffer(_ride.id, passengerId, 1);
    
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Te has unido a la oferta');
      Navigator.pop(context);
    } else if (mounted) {
      SnackBarHelper.showError(context, 'No se pudo unir (sin plazas)');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _leaveOffer() async {
    final passengerId = _authService.currentUser?.uid;
    if (passengerId == null) return;

    setState(() => _isLoading = true);

    final success = await _rideService.leaveOffer(_ride.id, passengerId, 1);
    
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Has abandonado la oferta');
      Navigator.pop(context);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _confirmStart() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final success = await _rideService.confirmStart(_ride.id, userId);
    
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Has confirmado el inicio del trayecto');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _confirmComplete() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final success = await _rideService.confirmComplete(_ride.id, userId);
    
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Has confirmado el fin del trayecto');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitReview(String toUserId) async {
    if (_rating == 0) return;
    final userId = _currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final review = await _reviewService.createReview(
      rideId: _ride.id,
      fromUserId: userId,
      toUserId: toUserId,
      rating: _rating,
    );

    if (review != null && mounted) {
      SnackBarHelper.showSuccess(context, 'Valoración enviada');
      setState(() {
        _rating = 0;
        _reviewingUserId = null;
        _hasReviewed[toUserId] = true;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _startChat(String otherUserId) async {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null || currentUserId == otherUserId) return;

    setState(() => _isLoading = true);

    final chat = await _chatService.getOrCreateChat(currentUserId, otherUserId);
    
    setState(() => _isLoading = false);

    if (chat != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.id,
            otherUserId: otherUserId,
          ),
        ),
      );
    } else if (mounted) {
      SnackBarHelper.showError(context, 'Error al iniciar chat');
    }
  }

  Future<void> _cancelRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Estás seguro de que quieres cancelar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await _rideService.cancelRide(_ride.id);
    
    if (success && mounted) {
      Navigator.pop(context);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitRating() async {
    if (_rating == 0 || _creatorUser == null) return;

    // Calcular nuevo promedio (simplificado)
    final newRating = _creatorUser!.rating == 0
        ? _rating.toDouble()
        : (_creatorUser!.rating + _rating) / 2;

    await _authService.updateUserRating(_creatorUser!.id, newRating);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias por tu puntuación')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _editRide() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditRideScreen(ride: _ride)),
    );
    if (result == true) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar esta ${_ride.isRequest ? "solicitud" : "oferta"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await _rideService.cancelRide(_ride.id);
    
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Eliminado correctamente');
      Navigator.pop(context);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ride.isRequest ? 'Detalle Solicitud' : 'Detalle Oferta'),
        actions: [
          if (_isCreator && _ride.isOpen) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editRide,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteRide,
              tooltip: 'Eliminar',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tipo y Estado
                  Row(
                    children: [
                      Expanded(child: _buildTypeBadge()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusBadge()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Información del viaje
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.trip_origin, 'Origen', _ride.location, Colors.green),
                          const Divider(),
                          _buildInfoRow(Icons.location_on, 'Destino', 
                            (_ride.destination?.isNotEmpty ?? false) ? _ride.destination! : 'Sin definir', Colors.red),
                          const Divider(),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fecha',
                            '${_ride.time.day}/${_ride.time.month}/${_ride.time.year}',
                            Colors.blue,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.access_time,
                            'Hora',
                            '${_ride.time.hour.toString().padLeft(2, '0')}:${_ride.time.minute.toString().padLeft(2, '0')}',
                            Colors.orange,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            _ride.isOffer ? Icons.event_seat : Icons.group, 
                            _ride.isOffer ? 'Plazas' : 'Personas', 
                            _ride.isOffer 
                              ? '${_ride.spotsRemaining} disponibles de ${_ride.numberOfPeople}'
                              : '${_ride.numberOfPeople}',
                            Colors.purple,
                          ),
                          const Divider(),
                          _buildInfoRow(Icons.euro, 'Precio', _ride.formattedPrice, Colors.teal),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info del creador
                  if (_creatorUser != null && !_isCreator)
                    _buildUserCard(_creatorUser!, _ride.isOffer ? 'Conductor' : 'Pasajero'),
                  
                  const SizedBox(height: 20),

                  // Indicador de progreso (confirmaciones de inicio/fin)
                  if (_ride.isAccepted || _ride.isInProgress)
                    _buildProgressIndicator(),
                  
                  const SizedBox(height: 20),

                  // Sección de rating (solo si está completado)
                  if (_ride.isCompleted)
                    _buildRatingSection(),

                  const SizedBox(height: 20),

                  // Botones de acción
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeBadge() {
    final isRequest = _ride.isRequest;
    final color = isRequest ? Colors.amber : Colors.teal;
    final text = isRequest ? 'Solicitud' : 'Oferta';
    final icon = isRequest ? Icons.hail : Icons.directions_car;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (_ride.status) {
      case AppConstants.statusOpen:
        color = Colors.blue;
        text = 'Abierto';
        icon = Icons.hourglass_empty;
        break;
      case AppConstants.statusAccepted:
        color = Colors.orange;
        text = 'Listo para iniciar';
        icon = Icons.check_circle;
        break;
      case AppConstants.statusInProgress:
        color = Colors.indigo;
        text = 'En trayecto';
        icon = Icons.directions_car;
        break;
      case AppConstants.statusCompleted:
        color = Colors.green;
        text = 'Completado';
        icon = Icons.done_all;
        break;
      case AppConstants.statusCancelled:
        color = Colors.red;
        text = 'Cancelado';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, String role) {
    final isCurrentUser = user.id == _currentUser?.id;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            user.rating > 0
                                ? user.rating.toStringAsFixed(1)
                                : 'Sin puntuación',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón de chat (solo si no es el usuario actual)
                if (!isCurrentUser)
                  IconButton(
                    onPressed: () => _startChat(user.id),
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Iniciar chat',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    // Solo mostrar si el viaje está completado y el usuario es participante
    if (!_ride.isCompleted || !_isParticipant) {
      return const SizedBox.shrink();
    }

    final currentUserId = _currentUser?.id;
    if (currentUserId == null) return const SizedBox.shrink();

    // Obtener usuarios a los que se puede dar review (todos menos el actual)
    final usersToReview = _participants.entries
        .where((e) => e.key != currentUserId && !(_hasReviewed[e.key] ?? false))
        .toList();

    if (usersToReview.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                'Ya has valorado a todos los participantes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valora tu experiencia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...usersToReview.map((entry) {
              final user = entry.value;
              final isReviewing = _reviewingUserId == entry.key;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isReviewing 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                user.id == _ride.creatorId 
                                    ? (_ride.isOffer ? 'Conductor' : 'Pasajero')
                                    : 'Pasajero',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!isReviewing)
                          TextButton(
                            onPressed: () => setState(() {
                              _reviewingUserId = entry.key;
                              _rating = 0;
                            }),
                            child: const Text('Valorar'),
                          ),
                      ],
                    ),
                    if (isReviewing) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () => setState(() => _rating = index + 1),
                          );
                        }),
                      ),
                      if (_rating > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() {
                                    _reviewingUserId = null;
                                    _rating = 0;
                                  }),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _submitReview(entry.key),
                                  child: const Text('Enviar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (!_ride.isAccepted && !_ride.isInProgress) {
      return const SizedBox.shrink();
    }

    final totalParticipants = _ride.allParticipants.length;
    final startedCount = _ride.startedBy.length;
    final completedCount = _ride.completedBy.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ride.isAccepted ? 'Confirmaciones de inicio' : 'Confirmaciones de fin',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _ride.isAccepted 
                  ? startedCount / totalParticipants
                  : completedCount / totalParticipants,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              _ride.isAccepted 
                  ? '$startedCount de $totalParticipants han confirmado inicio'
                  : '$completedCount de $totalParticipants han confirmado fin',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Lista de participantes y su estado
            ...(_ride.allParticipants.map((participantId) {
              final user = _participants[participantId];
              final hasStarted = _ride.startedBy.contains(participantId);
              final hasCompleted = _ride.completedBy.contains(participantId);
              final isDriver = participantId == _ride.creatorId && _ride.isOffer;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _ride.isAccepted
                          ? (hasStarted ? Icons.check_circle : Icons.radio_button_unchecked)
                          : (hasCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                      color: (_ride.isAccepted ? hasStarted : hasCompleted)
                          ? Colors.green
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.name ?? 'Usuario',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (isDriver) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Conductor',
                          style: TextStyle(fontSize: 10, color: Colors.teal),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final widgets = <Widget>[];

    // Solicitud abierta - conductor puede aceptarla
    if (_ride.isRequest && _ride.isOpen && _currentUser?.isDriver == true && !_isCreator) {
      widgets.add(CustomButton(
        text: 'Aceptar Solicitud',
        onPressed: _acceptRequest,
      ));
    }

    // Oferta abierta - pasajero puede unirse si hay plazas
    if (_ride.isOffer && _ride.isOpen && !_isCreator && !_hasJoined && _ride.hasAvailableSpots) {
      widgets.add(CustomButton(
        text: 'Unirme (${_ride.spotsRemaining} plazas)',
        onPressed: _joinOffer,
      ));
    }

    // Pasajero ya unido - puede abandonar (solo si está open)
    if (_ride.isOffer && _hasJoined && _ride.isOpen) {
      widgets.add(CustomButton(
        text: 'Abandonar Oferta',
        onPressed: _leaveOffer,
        backgroundColor: Colors.red,
      ));
    }

    // Viaje aceptado (listo para iniciar) - participantes confirman inicio
    if (_ride.isAccepted && _isParticipant && !_hasConfirmedStart) {
      widgets.add(CustomButton(
        text: 'Confirmar Inicio del Trayecto',
        onPressed: _confirmStart,
        icon: Icons.play_arrow,
      ));
    }

    // Ya confirmó inicio, esperando a otros
    if (_ride.isAccepted && _isParticipant && _hasConfirmedStart) {
      widgets.add(Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Esperando a que todos confirmen inicio...',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ],
        ),
      ));
    }

    // Viaje en progreso - participantes confirman fin
    if (_ride.isInProgress && _isParticipant && !_hasConfirmedComplete) {
      widgets.add(CustomButton(
        text: 'Confirmar Fin del Trayecto',
        onPressed: _confirmComplete,
        icon: Icons.flag,
      ));
    }

    // Ya confirmó fin, esperando a otros
    if (_ride.isInProgress && _isParticipant && _hasConfirmedComplete) {
      widgets.add(Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_bottom, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              'Esperando a que todos confirmen llegada...',
              style: TextStyle(color: Colors.indigo[700]),
            ),
          ],
        ),
      ));
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: widgets.map((w) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: w,
      )).toList(),
    );
  }
}
