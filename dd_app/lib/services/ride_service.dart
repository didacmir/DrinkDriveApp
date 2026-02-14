import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../core/constants.dart';

/// Servicio para gestionar rides/solicitudes
class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia a la colección de rides
  CollectionReference get _ridesCollection =>
      _firestore.collection(AppConstants.ridesCollection);

  /// Crear nueva solicitud de ride
  Future<RideModel?> createRide({
    required String creatorId,
    required String rideType, // 'request' o 'offer'
    required String location,
    String? destination,
    required DateTime time,
    required double price,
    int numberOfPeople = 1,
  }) async {
    try {
      final ride = RideModel(
        id: '',
        creatorId: creatorId,
        driverId: rideType == 'offer' ? creatorId : null,
        rideType: rideType,
        location: location,
        destination: destination,
        time: time,
        price: price,
        numberOfPeople: numberOfPeople,
        acceptedCount: 0,
        acceptedPassengers: [],
        status: AppConstants.statusOpen,
        createdAt: DateTime.now(),
      );

      final docRef = await _ridesCollection.add(ride.toFirestore());
      
      return ride.copyWith(id: docRef.id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener todas las solicitudes abiertas (requests de pasajeros buscando conductor)
  Stream<List<RideModel>> getOpenRequests() {
    return _ridesCollection
        .where('status', isEqualTo: AppConstants.statusOpen)
        .where('rideType', isEqualTo: 'request')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time)));
  }

  /// Obtener todas las ofertas abiertas (conductores ofreciendo plazas)
  Stream<List<RideModel>> getOpenOffers() {
    return _ridesCollection
        .where('status', isEqualTo: AppConstants.statusOpen)
        .where('rideType', isEqualTo: 'offer')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromFirestore(doc))
            .where((ride) => ride.hasAvailableSpots)
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time)));
  }

  /// Obtener rides creados por un usuario (mis solicitudes)
  Stream<List<RideModel>> getUserRides(String userId) {
    return _ridesCollection
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Obtener rides donde el usuario es conductor asignado
  Stream<List<RideModel>> getDriverRides(String driverId) {
    return _ridesCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Obtener rides donde el usuario es pasajero aceptado
  Stream<List<RideModel>> getPassengerRides(String passengerId) {
    return _ridesCollection
        .where('acceptedPassengers', arrayContains: passengerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Obtener un ride específico
  Future<RideModel?> getRide(String rideId) async {
    try {
      final doc = await _ridesCollection.doc(rideId).get();
      if (doc.exists) {
        return RideModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream de un ride específico (para actualizaciones en tiempo real)
  Stream<RideModel?> getRideStream(String rideId) {
    return _ridesCollection
        .doc(rideId)
        .snapshots()
        .map((doc) => doc.exists ? RideModel.fromFirestore(doc) : null);
  }

  /// Conductor acepta una solicitud de pasajero (request)
  Future<bool> acceptRequest(String rideId, String driverId) async {
    try {
      await _ridesCollection.doc(rideId).update({
        'status': AppConstants.statusAccepted,
        'driverId': driverId,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pasajero se une a una oferta de conductor
  Future<bool> joinOffer(String rideId, String passengerId, int numberOfPeople) async {
    try {
      final doc = await _ridesCollection.doc(rideId).get();
      if (!doc.exists) return false;

      final ride = RideModel.fromFirestore(doc);
      
      // Verificar que hay plazas suficientes
      if (ride.spotsRemaining < numberOfPeople) return false;
      
      // Verificar que no esté ya en la lista
      if (ride.acceptedPassengers.contains(passengerId)) return false;

      final newAcceptedCount = ride.acceptedCount + numberOfPeople;
      final newAcceptedPassengers = [...ride.acceptedPassengers, passengerId];
      
      // Si se llenaron todas las plazas, marcar como aceptado
      final newStatus = newAcceptedCount >= ride.numberOfPeople 
          ? AppConstants.statusAccepted 
          : AppConstants.statusOpen;

      await _ridesCollection.doc(rideId).update({
        'acceptedCount': newAcceptedCount,
        'acceptedPassengers': newAcceptedPassengers,
        'status': newStatus,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pasajero abandona una oferta
  Future<bool> leaveOffer(String rideId, String passengerId, int numberOfPeople) async {
    try {
      final doc = await _ridesCollection.doc(rideId).get();
      if (!doc.exists) return false;

      final ride = RideModel.fromFirestore(doc);
      
      if (!ride.acceptedPassengers.contains(passengerId)) return false;

      final newAcceptedCount = (ride.acceptedCount - numberOfPeople).clamp(0, ride.numberOfPeople);
      final newAcceptedPassengers = ride.acceptedPassengers.where((id) => id != passengerId).toList();

      await _ridesCollection.doc(rideId).update({
        'acceptedCount': newAcceptedCount,
        'acceptedPassengers': newAcceptedPassengers,
        'status': AppConstants.statusOpen,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar un ride
  Future<bool> updateRide(String rideId, {
    String? location,
    String? destination,
    DateTime? time,
    double? price,
    int? numberOfPeople,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (location != null) updates['location'] = location;
      if (destination != null) updates['destination'] = destination;
      if (time != null) updates['time'] = Timestamp.fromDate(time);
      if (price != null) updates['price'] = price;
      if (numberOfPeople != null) updates['numberOfPeople'] = numberOfPeople;

      await _ridesCollection.doc(rideId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Completar un ride (legacy - usar confirmComplete)
  Future<bool> completeRide(String rideId) async {
    try {
      await _ridesCollection.doc(rideId).update({
        'status': AppConstants.statusCompleted,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Usuario confirma inicio del trayecto (usando transacción para atomicidad)
  Future<bool> confirmStart(String rideId, String userId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final docRef = _ridesCollection.doc(rideId);
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) return false;

        final ride = RideModel.fromFirestore(doc);
        
        // Verificar que el viaje está en estado aceptado
        if (ride.status != AppConstants.statusAccepted) return false;
        
        // Verificar que hay al menos 2 participantes
        final participants = ride.allParticipants;
        if (participants.length < 2) return false;
        
        // Verificar que el usuario es participante
        if (!participants.contains(userId)) return false;
        
        // Ya confirmó?
        if (ride.startedBy.contains(userId)) return true;

        final newStartedBy = [...ride.startedBy, userId];
        
        // Verificar si TODOS han confirmado inicio
        final allStarted = participants.every((id) => newStartedBy.contains(id));
        
        final updates = <String, dynamic>{
          'startedBy': newStartedBy,
        };
        
        // Solo cambiar estado si TODOS confirmaron
        if (allStarted) {
          updates['status'] = AppConstants.statusInProgress;
        }
        
        transaction.update(docRef, updates);
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Usuario confirma fin del trayecto (usando transacción para atomicidad)
  Future<bool> confirmComplete(String rideId, String userId) async {
    try {
      List<String>? participantsToUpdate;
      
      final success = await _firestore.runTransaction<bool>((transaction) async {
        final docRef = _ridesCollection.doc(rideId);
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) return false;

        final ride = RideModel.fromFirestore(doc);
        
        // Verificar que el viaje está en progreso
        if (ride.status != AppConstants.statusInProgress) return false;
        
        // Verificar que hay al menos 2 participantes
        final participants = ride.allParticipants;
        if (participants.length < 2) return false;
        
        // Verificar que el usuario es participante
        if (!participants.contains(userId)) return false;
        
        // Ya confirmó?
        if (ride.completedBy.contains(userId)) return true;

        final newCompletedBy = [...ride.completedBy, userId];
        
        // Verificar si TODOS han confirmado fin
        final allCompleted = participants.every((id) => newCompletedBy.contains(id));
        
        final updates = <String, dynamic>{
          'completedBy': newCompletedBy,
        };
        
        // Solo cambiar estado si TODOS confirmaron
        if (allCompleted) {
          updates['status'] = AppConstants.statusCompleted;
          participantsToUpdate = participants;
        }
        
        transaction.update(docRef, updates);
        return true;
      });
      
      // Incrementar totalRides FUERA de la transacción
      if (success && participantsToUpdate != null) {
        for (final participantId in participantsToUpdate!) {
          await _firestore.collection(AppConstants.usersCollection).doc(participantId).update({
            'totalRides': FieldValue.increment(1),
          });
        }
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Cancelar un ride
  Future<bool> cancelRide(String rideId) async {
    try {
      await _ridesCollection.doc(rideId).update({
        'status': AppConstants.statusCancelled,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Eliminar un ride
  Future<bool> deleteRide(String rideId) async {
    try {
      await _ridesCollection.doc(rideId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
