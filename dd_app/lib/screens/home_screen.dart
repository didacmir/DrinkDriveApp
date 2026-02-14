import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/ride_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../core/constants.dart';
import '../widgets/ride_card.dart';
import '../widgets/snackbar_helper.dart';
import 'login_screen.dart';
import 'create_ride_screen.dart';
import 'ride_detail_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'driver_verification_screen.dart';
import 'chat_list_screen.dart';

/// Pantalla principal de la app
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _rideService = RideService();
  final _chatService = ChatService();
  
  UserModel? _user;
  bool _isLoading = true;
  DateTime? _filterDate;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      final user = await _authService.getUserData(userId);
      
      // Escuchar mensajes no leídos
      _chatService.getTotalUnreadCount(userId).listen((count) {
        if (mounted) {
          setState(() {
            _unreadMessages = count;
          });
        }
      });
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToCreateRide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRideScreen()),
    );
  }

  void _navigateToRideDetail(RideModel ride) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
    );
  }

  Future<void> _selectFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.isDriver == true ? 'Solicitudes' : 'Mis Viajes'),
        actions: [
          // Indicador de rol
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _user?.isDriver == true ? Icons.directions_car : Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _user?.isDriver == true ? 'Conductor' : 'Pasajero',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Menú
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              } else if (value == 'switch_role') {
                _switchRole();
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              } else if (value == 'messages') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              } else if (value == 'verification') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverVerificationScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Mi Perfil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'messages',
                child: ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      if (_unreadMessages > 0)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _unreadMessages > 9 ? '9+' : _unreadMessages.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: const Text('Mensajes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Historial'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_user?.verified != true)
                const PopupMenuItem(
                  value: 'verification',
                  child: ListTile(
                    leading: Icon(Icons.verified_user, color: Colors.blue),
                    title: Text('Verificar conductor'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: 'switch_role',
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(
                    _user?.isDriver == true
                        ? 'Cambiar a Pasajero'
                        : 'Cambiar a Conductor',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _user?.isDriver == true
          ? _buildDriverView()
          : _buildPassengerView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateRide,
        icon: const Icon(Icons.add),
        label: Text(_user?.isDriver == true ? 'Nueva oferta' : 'Nueva solicitud'),
      ),
    );
  }

  /// Vista para pasajeros (ver ofertas de conductores y sus solicitudes)
  Widget _buildPassengerView() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('No hay usuario'));
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Ofertas'),
              Tab(text: 'Mis solicitudes'),
              Tab(text: 'Mis viajes'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Ofertas de conductores
                StreamBuilder<List<RideModel>>(
                  stream: _rideService.getOpenOffers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = snapshot.data ?? [];

                    if (rides.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.directions_car,
                        title: 'No hay ofertas disponibles',
                        subtitle: 'Las ofertas de conductores aparecerán aquí',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          ride: ride,
                          onTap: () => _navigateToRideDetail(ride),
                          showJoinButton: true,
                          onJoin: () => _joinOffer(ride),
                        );
                      },
                    );
                  },
                ),
                // Solicitudes propias del pasajero
                StreamBuilder<List<RideModel>>(
                  stream: _rideService.getUserRides(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = (snapshot.data ?? [])
                        .where((r) => r.rideType == 'request')
                        .toList();

                    if (rides.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.hail,
                        title: 'Sin solicitudes',
                        subtitle: 'Crea una solicitud para buscar conductor',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          ride: ride,
                          onTap: () => _navigateToRideDetail(ride),
                        );
                      },
                    );
                  },
                ),
                // Viajes donde el pasajero está aceptado
                StreamBuilder<List<RideModel>>(
                  stream: _rideService.getPassengerRides(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = snapshot.data ?? [];

                    if (rides.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.local_taxi,
                        title: 'Sin viajes confirmados',
                        subtitle: 'Únete a una oferta para ver tus viajes',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          ride: ride,
                          onTap: () => _navigateToRideDetail(ride),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vista para conductores (ver solicitudes de pasajeros y sus ofertas)
  Widget _buildDriverView() {
    final driverId = _authService.currentUser?.uid;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Filtro de fecha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectFilterDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 20,
                            color: _filterDate != null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _filterDate != null
                                ? '${_filterDate!.day}/${_filterDate!.month}/${_filterDate!.year}'
                                : 'Filtrar por fecha',
                            style: TextStyle(
                              color: _filterDate != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_filterDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _filterDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    tooltip: 'Limpiar filtro',
                  ),
                ],
              ],
            ),
          ),
          TabBar(
            tabs: const [
              Tab(text: 'Solicitudes'),
              Tab(text: 'Mis ofertas'),
              Tab(text: 'Mis viajes'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Solicitudes de pasajeros buscando conductor
                StreamBuilder<List<RideModel>>(
                  stream: _rideService.getOpenRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = snapshot.data ?? [];

                    if (rides.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.search_off,
                        title: _filterDate != null
                            ? 'No hay solicitudes para esta fecha'
                            : 'No hay solicitudes',
                        subtitle: _filterDate != null
                            ? 'Prueba con otra fecha'
                            : 'Las solicitudes de pasajeros aparecerán aquí',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          ride: ride,
                          onTap: () => _navigateToRideDetail(ride),
                          showAcceptButton: true,
                          onAccept: () => _acceptRequest(ride),
                        );
                      },
                    );
                  },
                ),
                // Ofertas propias del conductor
                StreamBuilder<List<RideModel>>(
                  stream: _rideService.getUserRides(driverId ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = (snapshot.data ?? [])
                        .where((r) => r.rideType == 'offer')
                        .toList();

                    if (rides.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.local_offer,
                        title: 'Sin ofertas publicadas',
                        subtitle: 'Crea una oferta de plazas disponibles',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          ride: ride,
                          onTap: () => _navigateToRideDetail(ride),
                        );
                      },
                    );
                  },
                ),
                // Viajes del conductor (solicitudes aceptadas)
                StreamBuilder<List<RideModel>>(
                  stream: _rideService.getDriverRides(driverId ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = snapshot.data ?? [];

                    if (rides.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.directions_car,
                        title: 'Sin viajes aceptados',
                        subtitle: 'Acepta solicitudes para verlas aquí',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          ride: ride,
                          onTap: () => _navigateToRideDetail(ride),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(RideModel ride) async {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) return;

    final success = await _rideService.acceptRequest(ride.id, driverId);
    
    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, 'Solicitud aceptada correctamente');
      } else {
        SnackBarHelper.showError(context, 'Error al aceptar la solicitud');
      }
    }
  }

  Future<void> _joinOffer(RideModel ride) async {
    final passengerId = _authService.currentUser?.uid;
    if (passengerId == null) return;

    final success = await _rideService.joinOffer(ride.id, passengerId, 1);
    
    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, 'Te has unido a la oferta');
      } else {
        SnackBarHelper.showError(context, 'Error al unirte (quizás no hay plazas)');
      }
    }
  }

  Future<void> _switchRole() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null || _user == null) return;

    final newRole = _user!.isDriver
        ? AppConstants.rolePassenger
        : AppConstants.roleDriver;

    await _authService.updateUserRole(userId, newRole);
    await _loadUserData();
  }
}
