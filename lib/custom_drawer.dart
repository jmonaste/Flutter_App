import 'package:flutter/material.dart';
import 'vehicle_type_list.dart';
import 'camera_page.dart';

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
                          style:
                              TextStyle(color: Colors.blueAccent, fontSize: 14)),
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
              Navigator.pop(context); // Cerrar el drawer y volver a la pantalla de inicio
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
            leading: Icon(Icons.build, color: Colors.white),
            title: Text('Marcas', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Implementa la navegación para la gestión de marcas
            },
          ),
          ListTile(
            leading: Icon(Icons.model_training, color: Colors.white),
            title: Text('Modelos', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Implementa la navegación para la gestión de modelos
            },
          ),
          ListTile(
            leading: Icon(Icons.car_rental, color: Colors.white),
            title: Text('Vehículos', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Implementa la navegación para la gestión de vehículos
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
              // Acción de cerrar sesión
            },
          ),
        ],
      ),
    );
  }
}
