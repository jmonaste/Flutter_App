import 'package:flutter/material.dart';
import 'vehicle_type_list.dart'; // Importa la página donde listarás los tipos de vehículos

class HomePage extends StatelessWidget {
  final String token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Llama directamente al fetch para cargar los tipos de vehículos
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleTypeListPage(token: token),
                  ),
                );
              },
              child: Text('Gestionar tipos de vehículos'),
            ),
            SizedBox(height: 20), // Añadido para espaciado
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Acción para gestionar marcas
              },
              child: Text('Gestionar marcas'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Acción para gestionar modelos
              },
              child: Text('Gestionar modelos'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Acción para gestionar vehículos
              },
              child: Text('Gestionar vehículos'),
            ),
          ],
        ),
      ),
    );
  }
}
