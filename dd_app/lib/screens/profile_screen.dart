import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../models/user_model.dart';
import '../models/review_model.dart';
import 'login_screen.dart';

/// Pantalla de perfil de usuario
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _reviewService = ReviewService();
  UserModel? _user;
  List<ReviewModel> _reviews = [];
  Map<String, UserModel> _reviewAuthors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      final user = await _authService.getUserData(userId);
      
      // Cargar reviews recibidas
      _reviewService.getUserReviews(userId).listen((reviews) async {
        final authors = <String, UserModel>{};
        for (final review in reviews) {
          if (!authors.containsKey(review.fromUserId)) {
            final author = await _authService.getUserData(review.fromUserId);
            if (author != null) {
              authors[review.fromUserId] = author;
            }
          }
        }
        if (mounted) {
          setState(() {
            _reviews = reviews;
            _reviewAuthors = authors;
          });
        }
      });
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchRole() async {
    if (_user == null) return;
    
    final newRole = _user!.isDriver ? 'passenger' : 'driver';
    await _authService.updateUserRole(_authService.currentUser!.uid, newRole);
    await _loadUserData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cambiado a ${newRole == 'driver' ? 'Conductor' : 'Pasajero'}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Nombre
            Text(
              _user!.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // Email
            Text(
              _user!.email,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            
            // Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _user!.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    ' (${_user!.totalRides} viajes)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Rol actual
            _buildInfoCard(
              icon: _user!.isDriver ? Icons.directions_car : Icons.person,
              title: 'Rol actual',
              value: _user!.isDriver ? 'Conductor' : 'Pasajero',
              color: Theme.of(context).colorScheme.primary,
            ),
            
            const SizedBox(height: 12),
            
            // Total de viajes
            _buildInfoCard(
              icon: Icons.route,
              title: 'Total de viajes',
              value: _user!.totalRides.toString(),
              color: Colors.green,
            ),
            
            const SizedBox(height: 24),
            
            // Sección de valoraciones recibidas
            if (_reviews.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Valoraciones recibidas (${_reviews.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._reviews.take(5).map((review) => _buildReviewCard(review)),
              if (_reviews.length > 5)
                TextButton(
                  onPressed: () {
                    // TODO: Ver todas las valoraciones
                  },
                  child: Text('Ver todas (${_reviews.length})'),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rate_review_outlined, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(
                      'Aún no tienes valoraciones',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Botones de acción
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Cambiar rol'),
              subtitle: Text(
                _user!.isDriver ? 'Cambiar a Pasajero' : 'Cambiar a Conductor',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _switchRole,
            ),
            
            const Divider(),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text('Cerrar sesión'),
              subtitle: const Text('Salir de tu cuenta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final author = _reviewAuthors[review.fromUserId];
    final timeAgo = _formatTimeAgo(review.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Text(
                  author?.name.isNotEmpty == true ? author!.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author?.name ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} mes(es)';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} día(s)';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora(s)';
    } else {
      return 'Hace un momento';
    }
  }
}
