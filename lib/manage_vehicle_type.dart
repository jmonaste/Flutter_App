import 'dart:convert';  // Para manejar la conversión JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // Paquete http para hacer la solicitud HTTP
import 'vehicle_type_list.dart';  // Importa la nueva página para listar los tipos

class ManageVehicleTypePage extends StatefulWidget {
  final String token;

  const ManageVehicleTypePage({Key? key, required this.token}) : super(key: key);

  @override
  _ManageVehicleTypePageState createState() => _ManageVehicleTypePageState();
}

class _ManageVehicleTypePageState extends State<ManageVehicleTypePage> {
  List<dynamic> vehicleTypes = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> _fetchVehicleTypes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final response = await http.get(
      Uri.parse('http://192.168.1.45:8000/api/vehicle-types/'),
      headers: <String, String>{
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        vehicleTypes = data.map((vehicleType) {
          return {
            'id': vehicleType['id'],
            'type_name': vehicleType['type_name'],
            'created_at': vehicleType['created_at'],
            'updated_at': vehicleType['updated_at'],
          };
        }).toList();

        // Navegar a la página de la lista de tipos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleTypeListPage(vehicleTypes: vehicleTypes),
          ),
        );
      });
    } else {
      setState(() {
        errorMessage = 'Error fetching vehicle types';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Tipos de Vehículos'),
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
              onPressed: _fetchVehicleTypes,  // Llama a la función para listar tipos de vehículos
              child: Text('Listar tipos de vehículos existentes'),
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
                // Acción para actualizar tipo de vehículo
              },
              child: Text('Actualizar tipo de vehículo'),
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
                // Acción para crear un nuevo tipo de vehículo
              },
              child: Text('Crear tipo de vehículo nuevo'),
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
                // Acción para eliminar tipo de vehículo
              },
              child: Text('Eliminar tipo de vehículo'),
            ),
            SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
