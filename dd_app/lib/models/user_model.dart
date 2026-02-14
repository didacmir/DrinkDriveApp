import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuario para la aplicación DD
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String role; // 'passenger' | 'driver'
  final String currentMode; // 'passenger' | 'driver'
  final bool isDriverEligible;
  final double rating;
  final int ratingCount;
  final int totalRides;
  final bool verified;
  final String? licenseImageUrl;
  final String? carModel;
  final String? carPlate;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.role,
    this.currentMode = 'passenger',
    this.isDriverEligible = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.totalRides = 0,
    this.verified = false,
    this.licenseImageUrl,
    this.carModel,
    this.carPlate,
    required this.createdAt,
  });

  /// Crear UserModel desde documento de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'passenger',
      currentMode: data['currentMode'] ?? 'passenger',
      isDriverEligible: data['isDriverEligible'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      totalRides: data['totalRides'] ?? 0,
      verified: data['verified'] ?? false,
      licenseImageUrl: data['licenseImageUrl'],
      carModel: data['carModel'],
      carPlate: data['carPlate'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'currentMode': currentMode,
      'isDriverEligible': isDriverEligible,
      'rating': rating,
      'ratingCount': ratingCount,
      'totalRides': totalRides,
      'verified': verified,
      'licenseImageUrl': licenseImageUrl,
      'carModel': carModel,
      'carPlate': carPlate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crear copia con cambios
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    String? currentMode,
    bool? isDriverEligible,
    double? rating,
    int? ratingCount,
    int? totalRides,
    bool? verified,
    String? licenseImageUrl,
    String? carModel,
    String? carPlate,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      currentMode: currentMode ?? this.currentMode,
      isDriverEligible: isDriverEligible ?? this.isDriverEligible,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      totalRides: totalRides ?? this.totalRides,
      verified: verified ?? this.verified,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      carModel: carModel ?? this.carModel,
      carPlate: carPlate ?? this.carPlate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Verificar si es conductor
  bool get isDriver => role == 'driver';

  /// Verificar si es pasajero
  bool get isPassenger => role == 'passenger';
}
