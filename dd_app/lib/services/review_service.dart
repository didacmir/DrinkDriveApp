import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../core/constants.dart';

/// Servicio para gestionar reviews/valoraciones
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reviewsCollection =>
      _firestore.collection(AppConstants.reviewsCollection);

  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  /// Crear una nueva review
  Future<ReviewModel?> createReview({
    required String rideId,
    required String fromUserId,
    required String toUserId,
    required int rating,
    String? comment,
  }) async {
    try {
      final review = ReviewModel(
        id: '',
        rideId: rideId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        rating: rating.clamp(1, 5),
        comment: comment,
        createdAt: DateTime.now(),
      );

      final docRef = await _reviewsCollection.add(review.toFirestore());
      
      // Actualizar rating promedio del usuario
      await _updateUserRating(toUserId);
      
      return ReviewModel(
        id: docRef.id,
        rideId: rideId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        rating: rating,
        comment: comment,
        createdAt: review.createdAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Verificar si ya existe una review de un usuario a otro en un ride
  Future<bool> hasReviewed({
    required String rideId,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final query = await _reviewsCollection
          .where('rideId', isEqualTo: rideId)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener reviews recibidas por un usuario
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    // Evitar índice compuesto - ordenar en cliente
    return _reviewsCollection
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          // Ordenar en cliente
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Obtener reviews de un ride específico
  Future<List<ReviewModel>> getRideReviews(String rideId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('rideId', isEqualTo: rideId)
          .get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualizar rating promedio de un usuario
  Future<void> _updateUserRating(String userId) async {
    try {
      final reviews = await _reviewsCollection
          .where('toUserId', isEqualTo: userId)
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
      }
      
      final averageRating = totalRating / reviews.docs.length;

      await _usersCollection.doc(userId).update({
        'rating': averageRating,
        'totalRatings': reviews.docs.length,
      });
    } catch (e) {
      // Silently fail
    }
  }
}
