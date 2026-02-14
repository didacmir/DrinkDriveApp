import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Review/Valoración
class ReviewModel {
  final String id;
  final String rideId;
  final String fromUserId; // Quien da la review
  final String toUserId; // Quien recibe la review
  final int rating; // 1-5 estrellas
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      rideId: data['rideId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
