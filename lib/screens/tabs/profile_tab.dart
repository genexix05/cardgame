import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/auth_modal.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de usuario
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFFF5722),
                        child: Text(
                          _getInitials(authProvider.user?.email ?? ""),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.user?.email ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Usuario desde: ${_formatDate(authProvider.user?.metadata.creationTime)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Estadísticas del coleccionista
              const Text(
                'Estadísticas de Colección',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'Cartas coleccionadas',
                        '${collectionProvider.userCardsWithDetails.length}',
                        Icons.collections_bookmark,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Monedas',
                        '${collectionProvider.userCollection?.coins ?? 0}',
                        Icons.monetization_on,
                        const Color(0xFFFFD700),
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Gemas',
                        '${collectionProvider.userCollection?.gems ?? 0}',
                        Icons.diamond,
                        const Color(0xFF1E88E5),
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Cartas favoritas',
                        '${collectionProvider.getFavoriteCards().length}',
                        Icons.favorite,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Acciones del usuario
              const Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingItem(
                      'Cambiar contraseña',
                      Icons.lock,
                      () {
                        // Implementar cambio de contraseña
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'Notificaciones',
                      Icons.notifications,
                      () {
                        // Implementar configuración de notificaciones
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'Ayuda y soporte',
                      Icons.help,
                      () {
                        // Implementar pantalla de ayuda
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      'Cerrar sesión',
                      Icons.exit_to_app,
                      () => _logout(context, authProvider),
                      Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Versión de la app
              Center(
                child: Text(
                  'Dragon Ball Card Collector v1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon,
      [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? const Color(0xFFFF5722),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap,
      [Color? textColor]) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return "?";
    return email.substring(0, 1).toUpperCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Desconocido";
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.signOut();
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
