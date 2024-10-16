import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences
import 'package:http/http.dart' as http; // Para realizar la llamada de logout
import 'vehicle_type_list.dart';
import 'camera_page.dart';
import 'home_page.dart';
import 'main.dart'; // Importa para redirigir al LoginScreen

class CustomDrawer extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  final String token;  // Añadido para pasar el token

  const CustomDrawer({
    Key? key,
    required this.userName,
    required this.onProfileTap,
    required this.token,  // Añadido para usar el token en la navegación
  }) : super(key: key);

  // Función para manejar el logout
  Future<void> _logout(BuildContext context) async {
    // Realizar la llamada al endpoint de logout
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/logout'),  // URL del logout
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Eliminar el token de SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();  // Elimina el token guardado

        // Navegar de vuelta al LoginScreen y limpiar el stack de navegación
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()), // Redirige a la página de login
          (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
        );
      } else {
        print('Error al cerrar sesión en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud de cierre de sesión: $e');
    }
  }

  // Ventana emergente para confirmar el cierre de sesión
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar cierre de sesión'),
          content: Text('¿Seguro que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
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
                    Text(userName,
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Text('Ver perfil',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
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
                MaterialPageRoute(
                  builder: (context) => HomePage(token: token), // Navegar a HomePage
                ),
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
                MaterialPageRoute(
                  builder: (context) => VehicleTypeListPage(token: token),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add, color: Colors.white),
            title: Text('Nuevo vehículo', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraPage(token: token),
                ),
              );
            },
          ),
          Divider(color: Colors.grey[600], thickness: 1),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text('Configuraciones', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Acción de configuración
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
