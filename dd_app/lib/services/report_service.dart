import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/rating_model.dart';

/// Servicio para gestionar reportes y valoraciones
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencias a colecciones
  CollectionReference get _reportsCollection => _firestore.collection('reports');
  CollectionReference get _ratingsCollection => _firestore.collection('ratings');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Crear un reporte de usuario
  Future<bool> createReport({
    required String reportedUserId,
    required String reporterUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final report = ReportModel(
        id: '',
        reportedUserId: reportedUserId,
        reporterUserId: reporterUserId,
        reason: reason,
        description: description,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _reportsCollection.add(report.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crear una valoración
  Future<bool> createRating({
    required String rideId,
    required String fromUserId,
    required String toUserId,
    required int stars,
    String? comment,
  }) async {
    try {
      final rating = RatingModel(
        id: '',
        rideId: rideId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        stars: stars,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _ratingsCollection.add(rating.toFirestore());

      // Actualizar promedio del usuario
      await _updateUserRating(toUserId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar el rating promedio de un usuario
  Future<void> _updateUserRating(String userId) async {
    try {
      final ratingsSnapshot = await _ratingsCollection
          .where('toUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      int totalStars = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalStars += (doc.data() as Map<String, dynamic>)['stars'] as int;
      }

      final averageRating = totalStars / ratingsSnapshot.docs.length;

      await _usersCollection.doc(userId).update({
        'rating': averageRating,
        'ratingCount': ratingsSnapshot.docs.length,
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Obtener valoraciones de un usuario
  Stream<List<RatingModel>> getUserRatings(String userId) {
    return _ratingsCollection
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc))
            .toList());
  }

  /// Verificar si ya existe una valoración para un ride
  Future<bool> hasRatedRide(String rideId, String fromUserId) async {
    try {
      final snapshot = await _ratingsCollection
          .where('rideId', isEqualTo: rideId)
          .where('fromUserId', isEqualTo: fromUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
