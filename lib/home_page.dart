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
          title: Text('Error', style: TextStyle(color: Color(0xFF262626))),
          content: Text(message, style: TextStyle(color: Color(0xFF262626))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Color(0xFFA64F03))),
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
          'id': vehicle['id'], // Asegúrate de incluir el ID del vehículo
          'vin': vehicle['vin'],
          'brand': vehicle['model']['brand']['name'],
          'model': vehicle['model']['name'],
          'status': vehicle['status']['name'],
          'is_urgent': vehicle['is_urgent'],
          'color': vehicle['color']['name'],
          'hex_code': vehicle['color']['hex_code'],
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

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5)], // Degradado gris tenue
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8), // Bordes ligeramente redondeados para un aspecto más suave
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Color de la sombra
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 4), // Sombra en la parte inferior
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent, // Hacemos la Card transparente para mostrar el degradado del Container
        elevation: 0, // Eliminamos la elevación para que el sombreado sea el del Container
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          title: Text(
            '${vehicle['vin']}',
            style: TextStyle(color: Color(0xFF262626)),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${vehicle['brand']} ${vehicle['model']}', style: TextStyle(color: Color(0xFF262626).withOpacity(0.6))),
              Text('${vehicle['status']}', style: TextStyle(color: Color(0xFF262626).withOpacity(0.6))),
              if (vehicle['is_urgent']) Text('¡Urgente!', style: TextStyle(color: Colors.red)),
            ],
          ),
          trailing: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(int.parse('0xff${vehicle['hex_code'].substring(1)}')),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailPage(vehicleId: vehicle['id']),
              ),
            );
          },
        ),
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
      backgroundColor: Color(0xFFF2F2F2),
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Vehículos', style: TextStyle(color: Color(0xFF262626))),
        backgroundColor: Color(0xFFF2F2F2),
        iconTheme: IconThemeData(color: Color(0xFF262626)),
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
        backgroundColor: Color(0xFFF2CB05),
        foregroundColor: Color(0xFF262626),
        children: [
          SpeedDialChild(
            child: Icon(Icons.camera_alt, color: Color(0xFF262626)),
            backgroundColor: Color(0xFFF2CB05),
            label: 'Escanear QR',
            labelStyle: TextStyle(color: Color(0xFF262626)),
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
            child: Icon(Icons.photo, color: Color(0xFF262626)),
            backgroundColor: Color(0xFFF2CB05),
            label: 'Subir Imagen',
            labelStyle: TextStyle(color: Color(0xFF262626)),
            onTap: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
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