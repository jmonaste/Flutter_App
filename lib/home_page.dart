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

  @override
  void initState() {
    super.initState();
    _fetchVehicles(); // Inicializa fetching de vehículos
  }

  // Método para mostrar el diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Método para obtener los vehículos desde la API
  Future<void> _fetchVehicles({String? vin}) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final vehiclesData = await apiService.getVehicles(vin: vin);

      List<Map<String, dynamic>> vehiclesWithState = [];

      for (var vehicle in vehiclesData) {
        vehiclesWithState.add({
          'vin': vehicle['vin'],
          'brand': vehicle['model']['brand']['name'],
          'model': vehicle['model']['name'],
          'status': vehicle['status']['name'],
          'is_urgent': vehicle['is_urgent'],
          'color': vehicle['color']['name'],
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

  // Método para construir las tarjetas de vehículos
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        title: Text('${vehicle['brand']} ${vehicle['model']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VIN: ${vehicle['vin']}'),
            Text('Estado: ${vehicle['status']}'),
            Text('Color: ${vehicle['color']}'),
            if (vehicle['is_urgent']) Text('¡Urgente!', style: TextStyle(color: Colors.red)),
          ],
        ),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailPage(vehicleId: vehicle['id']),
            ),
          );
        },
      ),
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
        title: Text('Vehículos'),
      ),
      drawer: CustomDrawer(
        userName: 'Nombre del usuario',
        onProfileTap: () {
          // Lógica para ver el perfil
        },        
      ),
      body: _vehicles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                return _buildVehicleCard(_vehicles[index]);
              },
            ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera_alt),
            label: 'Escanear QR',
            onTap: () async {
              if (await Permission.camera.request().isGranted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraPage()),
                );
              }
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.photo),
            label: 'Subir Imagen',
            onTap: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.getImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                // Manejar la imagen seleccionada
              }
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