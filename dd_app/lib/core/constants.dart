/// Constantes de la aplicación DD App
class AppConstants {
  // Nombres de colecciones en Firestore
  static const String usersCollection = 'users';
  static const String ridesCollection = 'rides';
  
  // Roles de usuario
  static const String rolePassenger = 'passenger';
  static const String roleDriver = 'driver';
  
  // Estados de ride
  static const String statusOpen = 'open';
  static const String statusAccepted = 'accepted';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Colecciones adicionales
  static const String reviewsCollection = 'reviews';
  
  // Textos de la app
  static const String appName = 'DD App';
  static const String appTagline = 'Conductor Designado bajo demanda';
  
  // Mensajes
  static const String errorGeneric = 'Ha ocurrido un error. Intenta de nuevo.';
  static const String errorInvalidEmail = 'Email inválido';
  static const String errorWeakPassword = 'La contraseña debe tener al menos 6 caracteres';
  static const String errorEmailInUse = 'Este email ya está registrado';
  static const String errorUserNotFound = 'Usuario no encontrado';
  static const String errorWrongPassword = 'Contraseña incorrecta';
  
  // Validaciones
  static const int minPasswordLength = 6;
  static const int maxRating = 5;
  static const int minRating = 1;
}
