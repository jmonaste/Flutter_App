import 'package:flutter/material.dart';
import 'custom_drawer.dart'; // Import CustomDrawer
import 'custom_footer.dart'; // Import CustomFooter
import 'home_page.dart';

class VehicleDetailPage extends StatelessWidget {
  final String vin;
  final String brand;
  final String model;
  final bool isUrgent;
  final String status;
  final String token; // Añadido para manejar el token

  const VehicleDetailPage({
    Key? key,
    required this.vin,
    required this.brand,
    required this.model,
    required this.isUrgent,
    required this.status,
    required this.token, // Recibimos el token desde la pantalla anterior
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$brand $model'),
        backgroundColor: Colors.blueGrey[900], // Color de fondo del AppBar
      ),
      drawer: CustomDrawer(
        userName: 'Nombre del usuario',
        onProfileTap: () {
          // Lógica para ver el perfil
        },
        token: token, // Pasamos el token al CustomDrawer
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.blueGrey[800], // Fondo de la tarjeta
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$brand $model', // Mostrar marca y modelo concatenados
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto en blanco
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  vin, // Mostrar el VIN directamente sin la etiqueta
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[300], // Texto en gris claro para contraste
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Urgente: ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white, // Texto en blanco
                      ),
                    ),
                    Text(
                      isUrgent ? "Sí" : "No",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.redAccent : Colors.greenAccent, // Texto en rojo o verde
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Estado: $status',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Texto en blanco
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: 0, // Set accordingly
        onTap: (index) {
          // Manejo de la navegación con el token
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(token: token), // Volver a HomePage con el token
              ),
            );
          }
          // Agregar más lógica de navegación si es necesario
        },
      ),
    );
  }
}
