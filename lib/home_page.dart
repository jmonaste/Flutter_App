import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'custom_drawer.dart';
import 'custom_footer.dart';
import 'constants.dart';
import 'camera_page.dart';
import 'vehicle_detail_page.dart'; // Import the new detail page
import 'package:shared_preferences/shared_preferences.dart';  // Si usas SharedPreferences
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'main.dart';
import 'vin_search_page.dart';

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
    var url = Uri.parse('$baseUrl/api/vehicles');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      List<dynamic> vehiclesJson = jsonDecode(utf8.decode(response.bodyBytes));
      List<Map<String, dynamic>> vehiclesWithState = [];

      for (var vehicle in vehiclesJson) {
        var stateUrl = Uri.parse('$baseUrl/api/vehicles/${vehicle['id']}/current_state');
        var stateResponse = await http.get(stateUrl, headers: {
          'Authorization': 'Bearer ${widget.token}',
        });

        String stateName = 'Desconocido';
        if (stateResponse.statusCode == 200) {
          var stateJson = jsonDecode(utf8.decode(stateResponse.bodyBytes));
          stateName = stateJson['name'] ?? 'Desconocido';
        }

        vehiclesWithState.add({
          'id': vehicle['id'] ?? -1, // Asignar -1 si el id no está presente
          'vin': vehicle['vin'] ?? 'Sin VIN',
          'brand': vehicle['model']?['brand']?['name'] ?? 'Marca Desconocida',
          'model': vehicle['model']?['name'] ?? 'Modelo Desconocido',
          'is_urgent': vehicle['is_urgent'] ?? false,
          'status': stateName,
        });
      }

      setState(() {
        _vehicles = vehiclesWithState;
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
                        if (vehicle['id'] != -1) {
                          // Navegar a la página de detalles del vehículo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailPage(
                                vehicleId: vehicle['id'],
                                vin: vehicle['vin'],
                                brand: vehicle['brand'],
                                model: vehicle['model'],
                                isUrgent: vehicle['is_urgent'],
                                status: vehicle['status'],
                                token: widget.token,
                              ),
                            ),
                          );
                        } else {
                          print('ID de vehículo no válido');
                        }
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
                              // VIN
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'VIN: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: vehicle['vin'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Marca y Modelo
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Marca y Modelo: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${vehicle['brand']} ${vehicle['model']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Urgente
                              Row(
                                children: [
                                  Text(
                                    'Urgente: ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.white,
                                    ),
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
                              // Estado
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Estado: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: vehicle['status'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Dentro de tu método build, en el Scaffold
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          overlayColor: Colors.black,
          overlayOpacity: 0.8,
          children: [
            SpeedDialChild(
              child: Icon(Icons.search),
              label: 'Buscar Vehículo',
              backgroundColor: Colors.blueAccent,
              labelStyle: TextStyle(color: Colors.white),
              onTap: () {
                // Navegar a VinSearchPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VinSearchPage(token: widget.token),
                  ),
                );
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.add),
              label: 'Añadir Vehículo',
              backgroundColor: Colors.blueAccent,
              labelStyle: TextStyle(color: Colors.white),
              onTap: () {
                // Navegar a la página para añadir un vehículo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraPage(token: widget.token),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: CustomFooter(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
