import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/ride_service.dart';
import '../models/ride_model.dart';
import '../widgets/ride_card.dart';
import 'ride_detail_screen.dart';

/// Pantalla de historial de servicios
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _rideService = RideService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToDetail(RideModel ride) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Como Pasajero'),
            Tab(text: 'Como Conductor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Historial como pasajero
          _buildHistoryList(
            stream: _rideService.getUserRides(userId),
            emptyIcon: Icons.local_taxi,
            emptyTitle: 'Sin viajes como pasajero',
            emptySubtitle: 'Tus solicitudes completadas aparecerán aquí',
          ),
          // Historial como conductor
          _buildHistoryList(
            stream: _rideService.getDriverRides(userId),
            emptyIcon: Icons.directions_car,
            emptyTitle: 'Sin viajes como conductor',
            emptySubtitle: 'Los servicios que realices aparecerán aquí',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList({
    required Stream<List<RideModel>> stream,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    return StreamBuilder<List<RideModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rides = snapshot.data ?? [];
        final completedRides = rides
            .where((r) => r.status == 'completed' || r.status == 'cancelled')
            .toList();

        if (completedRides.isEmpty) {
          return _buildEmptyState(emptyIcon, emptyTitle, emptySubtitle);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedRides.length,
          itemBuilder: (context, index) {
            final ride = completedRides[index];
            return RideCard(
              ride: ride,
              onTap: () => _navigateToDetail(ride),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
