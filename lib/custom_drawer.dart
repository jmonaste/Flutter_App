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
      await apiService.logout(); // Utiliza el método de logout de ApiService

      // Navegar de vuelta al LoginScreen y limpiar el stack de navegación
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Redirige a la página de login
        (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
      );
    } catch (e) {
      print('Error al cerrar sesión: $e');
      // Mostrar un diálogo de error al usuario
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Text('Error', style: TextStyle(color: Colors.white)),
          content: Text('No se pudo cerrar sesión. Por favor, intenta nuevamente.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      );
    }
  }

  // Ventana emergente para confirmar el cierre de sesión
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Text('Confirmar cierre de sesión', style: TextStyle(color: Colors.white)),
          content: Text('¿Seguro que quieres cerrar sesión?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();  // Cerrar el diálogo
              },
            ),
            TextButton(
              child: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();  // Cerrar el diálogo
                _logout(context);  // Llamar a la función de logout
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
      backgroundColor: Colors.grey[850],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[800],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[700],
                  child: Icon(Icons.person, color: Colors.white, size: 30),
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
                        style: TextStyle(color: Colors.blueAccent, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[600], thickness: 1),
          ListTile(
            leading: Icon(Icons.home, color: Colors.white),
            title: Text('Inicio', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()), // Navegar a HomePage sin pasar el token
                (route) => false, // Remueve todas las páginas anteriores
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_car, color: Colors.white),
            title: Text('Tipos de vehículos', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VehicleTypeListPage()),
              );
            },
          ),
          // Nueva opción "Marcas"
          ListTile(
            leading: Icon(Icons.business, color: Colors.white),
            title: Text('Marcas', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VehicleBrandManagePage()),
              );
            },
          ),
          // Nueva opción "Modelos"
          ListTile(
            leading: Icon(Icons.category, color: Colors.white),
            title: Text('Modelos', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VehicleModelManagePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add, color: Colors.white),
            title: Text('Nuevo vehículo', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraPage()),
              );
            },
          ),
          Divider(color: Colors.grey[600], thickness: 1),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text('Configuraciones', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Acción de configuración
              // Puedes implementar la navegación a una página de configuraciones si lo deseas
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.white),
            title: Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
            onTap: () {
              _showLogoutConfirmation(context);  // Mostrar la ventana de confirmación
            },
          ),
        ],
      ),
    );
  }
}
