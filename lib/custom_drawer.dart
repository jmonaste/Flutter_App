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
        backgroundColor: Color(0xFF262626),
        title: Text('Error', style: TextStyle(color: Color(0xFFF2CB05))),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Aceptar', style: TextStyle(color: Color(0xFFA64F03))),
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
          backgroundColor: Color(0xFF262626),
          title: Text('Confirmar cierre de sesión', style: TextStyle(color: Color(0xFFF2CB05))),
          content: Text('¿Seguro que quieres cerrar sesión?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Color(0xFFA64F03))),
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
      backgroundColor: Color(0xFFF2F2F2),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFA64F03),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFF2CB05),
                  child: Icon(Icons.person, color: Color(0xFF262626), size: 30),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Text(
                        'Ver perfil',
                        style: TextStyle(color: Color(0xFFF2CB05), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Color(0xFFA64F03), thickness: 1),
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
          Divider(color: Color(0xFFA64F03), thickness: 1),
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Cerrar sesión',
            color: Colors.red,
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
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFA64F03)),
      title: Text(text, style: TextStyle(color: Color(0xFFA64F03))),
      onTap: onTap,
    );
  }
}
