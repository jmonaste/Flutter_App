import 'package:flutter/material.dart';
import 'create_vehicle_type.dart'; // Importa la nueva pantalla

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
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateVehicleTypePage(token: token),
              ),
            );
          },
          child: Text('Dar de alta un tipo de vehículo'),
        ),
      ),
    );
  }
}
