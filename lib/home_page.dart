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
  final TextEditingController _vinController = TextEditingController();
  int _selectedIndex = 0;
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _vehicles = [];

  // Variables para manejar el filtro
  bool _isFiltered = false;
  String? _currentFilterVin;

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
          backgroundColor: Colors.white, // Fondo más claro
          title: Text('Error', style: TextStyle(color: Colors.redAccent)),
          content: Text(message, style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Aceptar', style: TextStyle(color: Colors.blue)),
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
        if (vin != null && vin.trim().isNotEmpty) {
          _isFiltered = true;
          _currentFilterVin = vin.trim();
        } else {
          _isFiltered = false;
          _currentFilterVin = null;
        }
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

  void _showVinSelectionDialog(List<Map<String, dynamic>> detectedCodes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Fondo más claro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Bordes más suaves
          ),
          title: Text(
            'Seleccionar VIN',
            style: TextStyle(
              color: Colors.grey[800], // Color más sutil para el título
              fontSize: 20, // Tamaño de fuente más grande para resaltar el título
              fontWeight: FontWeight.w600, // Peso de fuente más ligero
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: detectedCodes.map((code) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        '${code['type']}: ${code['data']}',
                        style: TextStyle(
                          color: Colors.grey[800], // Color del texto
                          fontSize: 16, // Tamaño de fuente adecuado
                        ),
                      ),
                      onTap: () {
                        _updateVin(code['data']); // Actualizar el VIN correctamente
                        Navigator.of(context).pop(); // Cerrar el diálogo de selección
                      },
                    ),
                    Divider(color: Colors.grey[300], thickness: 1), // Separador suave
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo sin seleccionar
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.blueGrey, // Color del texto del botón
                  fontSize: 16, // Tamaño de fuente adecuado
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      final apiService = Provider.of<ApiService>(context, listen: false);

      try {
        final detectedCodes = await apiService.scanImage(pickedFile.path);
        _showVinSelectionDialog(detectedCodes);
      } catch (e) {
        _showErrorDialog('Error al escanear la imagen: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateVin(String vin) {
    setState(() {
      _vinController.text = vin;
    });
  }

  void _showSearchModal() {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar el diálogo tocando fuera de él
      builder: (BuildContext context) {
        // Obtener el tamaño de la pantalla para la responsividad
        var size = MediaQuery.of(context).size;

        return Dialog(
          backgroundColor: Colors.white, // Fondo del diálogo más claro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Bordes más suaves
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.9, // Máximo 90% del ancho de la pantalla
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título del diálogo
                    Text(
                      'Buscar Vehículo',
                      style: TextStyle(
                        color: Colors.grey[800], // Color más sutil para el título
                        fontSize: 20, // Tamaño de fuente más grande para resaltar el título
                        fontWeight: FontWeight.w600, // Peso de fuente más ligero
                      ),
                    ),
                    SizedBox(height: 20),
                    // Campo de texto para ingresar el VIN con ícono de cámara dentro
                    TextField(
                      controller: _vinController,
                      decoration: InputDecoration(
                        labelText: 'Ingrese VIN',
                        labelStyle: TextStyle(color: Colors.grey[600]), // Color más suave para la etiqueta
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.0), // Bordes más suaves
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2.0), // Bordes al enfocar
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.blueGrey),
                          onPressed: () {
                            _showImageSourceActionSheet(); // Mostrar las opciones de imagen sin cerrar el diálogo principal
                          },
                        ),
                      ),
                      style: TextStyle(color: Colors.grey[800]), // Color del texto ingresado
                      onChanged: (value) {
                        setState(() {}); // Actualizar el estado si es necesario
                      },
                    ),
                    SizedBox(height: 20),
                    // Botón para realizar la búsqueda (Siempre habilitado)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar el modal de búsqueda
                        _fetchVehicles(vin: _vinController.text.trim()); // Realizar la búsqueda
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Color profesional para el botón
                        minimumSize: Size(double.infinity, 50), // Botón de ancho completo
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Bordes redondeados
                        ),
                      ),
                      child: Text(
                        'Buscar',
                        style: TextStyle(color: Colors.white), // Texto del botón en blanco para mejor contraste
                      ),                      
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageSourceActionSheet() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Fondo del diálogo más claro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Bordes más suaves
          ),
          title: Text(
            'Seleccionar fuente de imagen',
            style: TextStyle(
              color: Colors.grey[800], // Color más sutil para el título
              fontSize: 20, // Tamaño de fuente más grande para resaltar el título
              fontWeight: FontWeight.w600, // Peso de fuente más ligero
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opción para seleccionar de la galería
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blueGrey),
                title: Text(
                  'Seleccionar de la Galería',
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Cerrar el diálogo de opciones
                  _pickImage(ImageSource.gallery);
                },
              ),
              Divider(color: Colors.grey[300], thickness: 1),
              // Opción para tomar una foto
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.blueGrey),
                title: Text(
                  'Tomar Foto',
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Cerrar el diálogo de opciones
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      body: Column(
        children: [
          // Botón para eliminar el filtro, visible solo cuando _isFiltered es true
          if (_isFiltered)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white, // Fondo blanco para destacar el botón
              child: ElevatedButton.icon(
                onPressed: () {
                  _fetchVehicles(); // Re-fetch sin filtro
                },
                icon: Icon(Icons.clear, color: Colors.white),
                label: Text(
                  'Eliminar Filtro',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey, // Color sobrio y profesional
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _vehicles.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      return _buildVehicleCard(_vehicles[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchModal,
        backgroundColor: Color(0xFFF2CB05),
        shape: CircleBorder(),
        child: Icon(Icons.search, color: Color(0xFF262626)),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
