import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_drawer.dart';
import 'custom_footer.dart';
import 'home_page.dart';  // Importa HomePage para la navegación de "Inicio"

class VehicleDetailPage extends StatefulWidget {
  final int vehicleId;
  final String vin;
  final String brand;
  final String model;
  final bool isUrgent;
  final String status;
  final String token;

  const VehicleDetailPage({
    Key? key,
    required this.vehicleId,
    required this.vin,
    required this.brand,
    required this.model,
    required this.isUrgent,
    required this.status,
    required this.token,
  }) : super(key: key);

  @override
  _VehicleDetailPageState createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  List<Map<String, dynamic>> _allowedTransitions = [];
  int _selectedIndex = 1;  // Por defecto, el índice estará en "Administrar"

  @override
  void initState() {
    super.initState();
    _fetchAllowedTransitions(); // Fetch the allowed transitions on init
  }

  Future<void> _fetchAllowedTransitions() async {
    var url = Uri.parse('http://127.0.0.1:8000/api/vehicles/${widget.vehicleId}/allowed_transitions');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      // Decodificar usando utf8.decode para evitar problemas de caracteres raros
      List<dynamic> transitionsJson = jsonDecode(utf8.decode(response.bodyBytes));

      setState(() {
        _allowedTransitions = transitionsJson.map((transition) {
          return {
            'to_state_id': transition['to_state_id'] ?? -1, // Asignar -1 si es nulo
            'name': null, // Este campo se rellenará en _fetchStatesDetails
          };
        }).toList();
      });

      _fetchStatesDetails();
    } else {
      print('Error fetching allowed transitions. Status: ${response.statusCode}');
    }
  }

  Future<void> _fetchStatesDetails() async {
    print(widget.token);
    var url = Uri.parse('http://127.0.0.1:8000/api/states/');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      // Decodificar usando utf8.decode para evitar problemas de caracteres raros
      List<dynamic> statesJson = jsonDecode(utf8.decode(response.bodyBytes));

      setState(() {
        _allowedTransitions = _allowedTransitions.map((transition) {
          // Buscamos el estado correspondiente al ID y manejamos si no se encuentra
          var state = statesJson.firstWhere(
            (state) => state['id'] == transition['to_state_id'],
            orElse: () => null, // Devuelve null si no se encuentra
          );

          // Manejar el caso donde 'state' es null
          return {
            'to_state_id': transition['to_state_id'],
            'name': state != null && state['name'] != null ? state['name'] : 'Estado Desconocido',
          };
        }).toList();
      });
    } else {
      print('Error fetching states details. Status: ${response.statusCode}');
    }
  }

  // Método para manejar la navegación del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(token: widget.token),
        ),
      );
    } else if (index == 2) {
      // Lógica para el botón "Cuenta"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Vehículo', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                      'VIN: ${widget.vin}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      'Marca y Modelo: ${widget.brand} ${widget.model}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Row(
                      children: [
                        Text(
                          'Urgente: ',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Icon(
                          widget.isUrgent ? Icons.warning_amber_rounded : Icons.check_circle,
                          color: widget.isUrgent ? Colors.redAccent : Colors.greenAccent,
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      'Estado Actual: ${widget.status}',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Transiciones Permitidas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 10),
            _allowedTransitions.isEmpty
                ? Center(
                    child: Text(
                      'No hay transiciones permitidas disponibles.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    children: _allowedTransitions.map((transition) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: SizedBox(
                          width: double.infinity, // Ancho completo del padre
                          child: ElevatedButton(
                            onPressed: () {
                              // Lógica para manejar el cambio de estado
                              print('Cambiar al estado: ${transition['name']}');
                            },
                            child: Text(
                              transition['name'],
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
