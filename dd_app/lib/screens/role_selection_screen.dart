import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

/// Pantalla de selección de rol después del registro
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _authService = AuthService();
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _selectRole(String role) async {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _confirmRole() async {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await _authService.updateUserRole(userId, _selectedRole!);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Quién eres?'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              Text(
                'Selecciona tu rol',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Puedes cambiarlo más adelante',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),

              // Opción Pasajero
              _RoleCard(
                icon: Icons.person,
                title: 'Pasajero',
                description: 'Necesito un conductor designado',
                isSelected: _selectedRole == AppConstants.rolePassenger,
                onTap: () => _selectRole(AppConstants.rolePassenger),
              ),

              const SizedBox(height: 16),

              // Opción Conductor
              _RoleCard(
                icon: Icons.directions_car,
                title: 'Conductor',
                description: 'Quiero ofrecer mis servicios',
                isSelected: _selectedRole == AppConstants.roleDriver,
                onTap: () => _selectRole(AppConstants.roleDriver),
              ),

              const Spacer(),

              // Botón confirmar
              CustomButton(
                text: 'Continuar',
                onPressed: _selectedRole != null && !_isLoading
                    ? _confirmRole
                    : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de tarjeta de rol
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 20,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
