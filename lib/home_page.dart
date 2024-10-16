import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'custom_drawer.dart';
import 'custom_footer.dart';
import 'camera_page.dart';
import 'vehicle_detail_page.dart'; // Import the new detail page
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Si usas SharedPreferences
import 'custom_drawer.dart';
import 'custom_footer.dart';
import 'main.dart';
import 'vehicle_detail_page.dart';

class HomePage extends StatefulWidget {
  final String token;  // Añadido para pasar el token

  const HomePage({
    Key? key,
    required this.token,  // Añadido para usar el token en la navegación
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _vehicles = [];  // Lista para almacenar los vehículos

  @override
  void initState() {
    super.initState();
    _fetchVehicles();  // Llamada para obtener los vehículos
  }

  // Función para cerrar sesión
  Future<void> _logout() async {
    // Si estás usando SharedPreferences, puedes borrar el token aquí
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // Borrar el almacenamiento

    // Navegar a la página de inicio de sesión y limpiar el stack de navegación
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _fetchVehicles() async {
    var url = Uri.parse('http://127.0.0.1:8000/api/vehicles');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      List<dynamic> vehiclesJson = jsonDecode(response.body);
      setState(() {
        _vehicles = vehiclesJson.map((vehicle) {
          return {
            'vin': vehicle['vin'],
            'brand': vehicle['model']['brand']['name'],
            'model': vehicle['model']['name'],
            'is_urgent': vehicle['is_urgent'],
            'status': vehicle['status'],
          };
        }).toList();
      });
    } else {
      print('Error fetching vehicles. Status: ${response.statusCode}');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Lógica de navegación según el índice seleccionado
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(token: widget.token),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark().copyWith(
          primary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: Colors.black87,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Home', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
        ),
        drawer: CustomDrawer(
          userName: 'Nombre del usuario',
          token: widget.token,
          onProfileTap: () {
            // Lógica para ver el perfil
          },
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: _vehicles.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return GestureDetector(
                      onTap: () {
                        // Navegar a la página de detalles del vehículo
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleDetailPage(
                              vin: vehicle['vin'],
                              brand: vehicle['brand'],
                              model: vehicle['model'],
                              isUrgent: vehicle['is_urgent'],
                              status: vehicle['status'],
                              token: widget.token
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VIN: ${vehicle['vin']}',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              Text(
                                'Marca y Modelo: ${vehicle['brand']} ${vehicle['model']}',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Urgente: ',
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                  Icon(
                                    vehicle['is_urgent']
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle,
                                    color: vehicle['is_urgent'] ? Colors.redAccent : Colors.greenAccent,
                                    size: 18,
                                  ),
                                ],
                              ),
                              Text(
                                'Estado: ${vehicle['status']}',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        bottomNavigationBar: CustomFooter(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
