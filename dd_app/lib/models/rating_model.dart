import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de valoración
class RatingModel {
  final String id;
  final String rideId;
  final String fromUserId;
  final String toUserId;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      rideId: data['rideId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      stars: data['stars'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'stars': stars,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
