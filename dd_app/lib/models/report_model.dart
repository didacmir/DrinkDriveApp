import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de reporte de usuario
class ReportModel {
  final String id;
  final String reportedUserId;
  final String reporterUserId;
  final String reason;
  final String? description;
  final String status; // 'pending' | 'reviewed' | 'resolved'
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reportedUserId,
    required this.reporterUserId,
    required this.reason,
    this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reportedUserId: data['reportedUserId'] ?? '',
      reporterUserId: data['reporterUserId'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportedUserId': reportedUserId,
      'reporterUserId': reporterUserId,
      'reason': reason,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
