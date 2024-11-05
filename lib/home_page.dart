// lib/home_page.dart
import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'custom_footer.dart';
import 'camera_page.dart';
import 'vehicle_detail_page.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _vehicles = [];

  // Lista para almacenar los colores
  List<Map<String, dynamic>> _colors = [];

  @override
  void initState() {
    super.initState();
    _initialize(); // Inicializa fetching de colores y vehículos
  }

  // Método para mostrar el diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87, // Fondo oscuro
          title: Text('Error', style: TextStyle(color: Colors.white)),
          content: Text(message, style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Método para inicializar la obtención de colores y luego vehículos
  Future<void> _initialize() async {
    await _fetchColors(); // Primero, obtener colores
    await _fetchVehicles(); // Luego, obtener vehículos
  }

  // Método para obtener los colores de vehículos desde la API
  Future<void> _fetchColors() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final colorsData = await apiService.getColors();

      setState(() {
        _colors = colorsData.map((color) {
          return {
            'id': color['id'],             // Guardamos el id del color
            'name': color['name'],         // Nombre del color
            'hex_code': color['hex_code'], // Código hexadecimal del color
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching colors: $e');
      _showErrorDialog('Error al obtener los colores de vehículos.');
    }
  }

  // Método para obtener los vehículos desde la API
  Future<void> _fetchVehicles({String? vin}) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final vehiclesData = await apiService.getVehicles(vin: vin);

      List<Map<String, dynamic>> vehiclesWithState = [];

      for (var vehicle in vehiclesData) {
        // Obtener el estado del vehículo
        final stateName = vehicle['status'] ?? 'Desconocido';

        vehiclesWithState.add({
          'id': vehicle['id'] ?? -1,
          'vin': vehicle['vin'] ?? 'Sin VIN',
          'brand': vehicle['brand'] ?? 'Marca Desconocida',
          'model': vehicle['model'] ?? 'Modelo Desconocido',
          'is_urgent': vehicle['is_urgent'] ?? false,
          'status': stateName,
          'color_id': vehicle['color_id'], // Añadido color_id
        });
      }

      setState(() {
        _vehicles = vehiclesWithState;
      });
    } catch (e) {
      print('Error fetching vehicles: $e');
      _showErrorDialog('Error al obtener los vehículos.');
    }
  }

  // Método para convertir hex_code a Color
  Color _getColorFromHex(String hexCode) {
    final buffer = StringBuffer();
    if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
    buffer.write(hexCode.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _showSearchDialog() async {
    String vinSearch = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87, // Fondo oscuro
          title: Text('Buscar Vehículo por VIN', style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (value) {
              vinSearch = value;
            },
            decoration: InputDecoration(
              hintText: 'Introduce el VIN o parte de él',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Buscar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _fetchVehicles(vin: vinSearch); // Realiza la búsqueda con el VIN ingresado
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onProfileTap: () {
          // Lógica para ver el perfil
        },
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: _vehicles.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];

                      // Obtener el color correspondiente basado en color_id
                      String hexCode = '#FF0000'; // Color por defecto (rojo)
                      if (vehicle['color_id'] != null) {
                        var color = _colors.firstWhere(
                          (c) => c['id'] == vehicle['color_id'],
                          orElse: () => {'hex_code': '#FF0000'}, // Fallback a rojo si no se encuentra
                        );
                        hexCode = color['hex_code'] ?? '#FF0000';
                      }

                      return GestureDetector(
                        onTap: () {
                          if (vehicle['id'] != -1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleDetailPage(
                                  vehicleId: vehicle['id'],
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
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: Stack(
                            children: [
                              // Contenido principal de la Card
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    SizedBox(height: 5),
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
                                    SizedBox(height: 5),
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
                                          vehicle['is_urgent'] ? Icons.warning_amber_rounded : Icons.check_circle,
                                          color: vehicle['is_urgent'] ? Colors.redAccent : Colors.greenAccent,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
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
                              // Franja de color en el lado derecho de la Card
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10, // Ancho de la franja
                                  decoration: BoxDecoration(
                                    color: _getColorFromHex(hexCode), // Color dinámico basado en hex_code
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Spinner de carga si está cargando
          if (_vehicles.isEmpty)
            Center(child: CircularProgressIndicator()),
        ],
      ),
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
            onTap: _showSearchDialog, // Abre el diálogo de búsqueda
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Añadir Vehículo',
            backgroundColor: Colors.blueAccent,
            labelStyle: TextStyle(color: Colors.white),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraPage(),
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
    );
  }
}
