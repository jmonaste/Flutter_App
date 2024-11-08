// lib/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'home_page.dart';
import 'vehicle_type_list.dart';
import 'manage_vehicle_models.dart';
import 'manage_vehicle_brand.dart';
import 'camera_page.dart';

class CustomDrawer extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;

  const CustomDrawer({
    Key? key,
    required this.userName,
    required this.onProfileTap,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showErrorDialog(context, 'No se pudo cerrar sesión. Por favor, intenta nuevamente.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Error', style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Aceptar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirmar cierre de sesión', style: TextStyle(color: Colors.redAccent)),
          content: Text('¿Seguro que quieres cerrar sesión?', style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Fondo claro y limpio
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header más minimalista
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueGrey[200],
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Text(
                          'Ver perfil',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildDrawerItem(
            icon: Icons.home,
            text: 'Inicio',
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            ),
          ),
          _buildDrawerItem(
            icon: Icons.directions_car,
            text: 'Tipos de vehículos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VehicleTypeListPage()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.business,
            text: 'Marcas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageVehicleBrandPage()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.category,
            text: 'Modelos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageVehicleModelsPage()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.add,
            text: 'Nuevo vehículo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraPage()),
            ),
          ),
          Divider(color: Colors.grey[300], thickness: 1),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Cerrar sesión',
            color: Colors.redAccent,
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(
        text,
        style: TextStyle(color: color, fontSize: 16),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }
}
