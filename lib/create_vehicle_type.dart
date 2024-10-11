import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateVehicleTypePage extends StatefulWidget {
  final String token;

  const CreateVehicleTypePage({Key? key, required this.token}) : super(key: key);

  @override
  _CreateVehicleTypePageState createState() => _CreateVehicleTypePageState();
}

class _CreateVehicleTypePageState extends State<CreateVehicleTypePage> {
  final _typeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _createVehicleType() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final String typeName = _typeController.text;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.45:8000/api/vehicle-types'), // Ajusta la URL de tu API
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Usa el token
        },
        body: jsonEncode(<String, String>{
          'type_name': typeName,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Vehículo creado exitosamente!')),
        );
        Navigator.pop(context); // Cierra la página si se crea exitosamente
      } else {
        setState(() {
          _errorMessage = 'Error al crear el tipo de vehículo. Código: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear tipo de vehículo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Nombre del tipo de vehículo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _createVehicleType,
                    child: Text('Crear'),
                  ),
            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
