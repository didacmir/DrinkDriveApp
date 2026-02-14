import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de solicitud de viaje (Ride)
/// 
/// Hay dos tipos de rides:
/// - 'request': Un pasajero busca conductor (crea solicitud)
/// - 'offer': Un conductor ofrece plazas disponibles
/// 
/// Estados del viaje:
/// - 'open': Abierto, esperando participantes
/// - 'accepted': Todas las plazas ocupadas, listo para iniciar
/// - 'in_progress': Viaje iniciado (todos confirmaron inicio)
/// - 'completed': Viaje completado (todos confirmaron fin)
/// - 'cancelled': Cancelado
class RideModel {
  final String id;
  final String creatorId;
  final String? driverId;
  final String rideType; // 'request' | 'offer'
  final String location;
  final String? destination;
  final DateTime time;
  final double price;
  final int numberOfPeople; // Personas que van (para request) o plazas totales (para offer)
  final int acceptedCount; // Número de personas ya aceptadas
  final List<String> acceptedPassengers; // IDs de pasajeros que se han unido
  final List<String> startedBy; // IDs de usuarios que confirmaron inicio
  final List<String> completedBy; // IDs de usuarios que confirmaron fin
  final String status; // 'open' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'
  final DateTime createdAt;

  RideModel({
    required this.id,
    required this.creatorId,
    this.driverId,
    this.rideType = 'request',
    required this.location,
    this.destination,
    required this.time,
    required this.price,
    this.numberOfPeople = 1,
    this.acceptedCount = 0,
    this.acceptedPassengers = const [],
    this.startedBy = const [],
    this.completedBy = const [],
    required this.status,
    required this.createdAt,
  });

  /// Crear RideModel desde documento de Firestore
  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      driverId: data['driverId'],
      rideType: data['rideType'] ?? 'request',
      location: data['location'] ?? '',
      destination: data['destination'],
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (data['price'] ?? 0.0).toDouble(),
      numberOfPeople: data['numberOfPeople'] ?? 1,
      acceptedCount: data['acceptedCount'] ?? 0,
      acceptedPassengers: List<String>.from(data['acceptedPassengers'] ?? []),
      startedBy: List<String>.from(data['startedBy'] ?? []),
      completedBy: List<String>.from(data['completedBy'] ?? []),
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'driverId': driverId,
      'rideType': rideType,
      'location': location,
      'destination': destination,
      'time': Timestamp.fromDate(time),
      'price': price,
      'numberOfPeople': numberOfPeople,
      'acceptedCount': acceptedCount,
      'acceptedPassengers': acceptedPassengers,
      'startedBy': startedBy,
      'completedBy': completedBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crear copia con cambios
  RideModel copyWith({
    String? id,
    String? creatorId,
    String? driverId,
    String? rideType,
    String? location,
    String? destination,
    DateTime? time,
    double? price,
    int? numberOfPeople,
    int? acceptedCount,
    List<String>? acceptedPassengers,
    List<String>? startedBy,
    List<String>? completedBy,
    String? status,
    DateTime? createdAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      driverId: driverId ?? this.driverId,
      rideType: rideType ?? this.rideType,
      location: location ?? this.location,
      destination: destination ?? this.destination,
      time: time ?? this.time,
      price: price ?? this.price,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      acceptedPassengers: acceptedPassengers ?? this.acceptedPassengers,
      startedBy: startedBy ?? this.startedBy,
      completedBy: completedBy ?? this.completedBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Es una solicitud de pasajero buscando conductor
  bool get isRequest => rideType == 'request';

  /// Es una oferta de conductor con plazas
  bool get isOffer => rideType == 'offer';

  /// Plazas restantes (solo para offers)
  int get spotsRemaining => numberOfPeople - acceptedCount;

  /// Verificar si hay plazas disponibles
  bool get hasAvailableSpots => spotsRemaining > 0;

  /// Verificar si está abierto
  bool get isOpen => status == 'open';

  /// Verificar si está aceptado (listo para iniciar)
  bool get isAccepted => status == 'accepted';

  /// Verificar si está en progreso
  bool get isInProgress => status == 'in_progress';

  /// Verificar si está completado
  bool get isCompleted => status == 'completed';

  /// Verificar si está cancelado
  bool get isCancelled => status == 'cancelled';

  /// Verificar si un usuario ya confirmó inicio
  bool hasUserStarted(String userId) => startedBy.contains(userId);

  /// Verificar si un usuario ya confirmó fin
  bool hasUserCompleted(String userId) => completedBy.contains(userId);

  /// Total de participantes (conductor + pasajeros)
  int get totalParticipants => isOffer 
      ? 1 + acceptedPassengers.length  // conductor + pasajeros
      : (driverId != null ? 2 : 1);    // request: creador + conductor si existe

  /// Lista de todos los participantes del viaje
  List<String> get allParticipants {
    if (isOffer) {
      return [creatorId, ...acceptedPassengers];
    } else {
      return driverId != null ? [creatorId, driverId!] : [creatorId];
    }
  }

  /// Verificar si todos confirmaron inicio
  bool get allStarted => allParticipants.every((id) => startedBy.contains(id));

  /// Verificar si todos confirmaron fin
  bool get allCompleted => allParticipants.every((id) => completedBy.contains(id));

  /// Formatear precio
  String get formattedPrice => '€${price.toStringAsFixed(2)}';

  /// Descripción del tipo
  String get typeDescription => isRequest ? 'Busco conductor' : 'Ofrezco plazas';
}
