import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'constants.dart';
import 'custom_drawer.dart';  // Importa el CustomDrawer
import 'custom_footer.dart';  // Importa el CustomFooter
import 'home_page.dart';      // Importa HomePage para la navegación de "Inicio"
import 'camera_page.dart';
import 'vehicle_detail_page.dart'; // Importa la página de detalle del vehículo

class VinSearchPage extends StatefulWidget {
  final String token;

  const VinSearchPage({Key? key, required this.token}) : super(key: key);

  @override
  _VinSearchPageState createState() => _VinSearchPageState();
}

class _VinSearchPageState extends State<VinSearchPage> {
  File? _imageFile;
  Uint8List? _webImage;
  String? _vin;
  List<Map<String, dynamic>> detectedCodes = [];
  final picker = ImagePicker();
  final TextEditingController _vinController = TextEditingController();
  int _selectedIndex = 0;  // Índice del BottomNavigationBar
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Agregamos un listener para actualizar el estado cuando cambie el texto
    _vinController.addListener(() {
      setState(() {}); // Actualiza el estado para habilitar o deshabilitar el botón
    });
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  Future<void> _scanQRorBarcode() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (kIsWeb) {
        _webImage = await pickedFile.readAsBytes();
        _uploadImage();
      } else {
        _imageFile = File(pickedFile.path);
        _uploadImage();
      }
    } else {
      print('No image selected.');
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) {
      print('No image selected.');
      return;
    }

    var uri = Uri.parse('$baseUrl/scan');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _webImage!,
        filename: 'qr_sample.jpeg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    request.headers['Authorization'] = 'Bearer ${widget.token}';

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        setState(() {
          List<dynamic> detectedCodesJson = decodedResponse['detected_codes'];
          detectedCodes = detectedCodesJson.map((code) {
            return {
              'type': code['type'],
              'data': code['data'],
            };
          }).toList();

          _showDetectedCodesDialog();
        });
      } else if (response.statusCode == 400) {
        var decodedResponse = jsonDecode(response.body);
        setState(() {
          detectedCodes = [];
          if (decodedResponse['error'] == 'No QR or Barcode detected') {
            _showErrorDialog('No se detectaron códigos QR o de barras. Introduzca el VIN manualmente.');
          } else if (decodedResponse['detail'] == 'Unsupported file type') {
            _showErrorDialog('El tipo de archivo no es compatible.');
          }
        });
      } else {
        print('Error al subir la imagen. Código de estado: ${response.statusCode}');
        _showErrorDialog('Error al subir la imagen. Por favor, inténtelo de nuevo.');
      }
    } catch (e) {
      _showErrorDialog('Error al conectar con el servidor. Por favor, inténtelo más tarde.');
    }
  }

  Future<void> _searchVehicle() async {
    String vinToSearch = _vinController.text.trim();
    if (vinToSearch.isEmpty) {
      _showErrorDialog('Por favor, introduzca un VIN.');
      return;
    }

    var url = Uri.parse('$baseUrl/api/vehicles/search_by_vin/$vinToSearch');
    try {
      var response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        var vehicleData = jsonDecode(response.body);

        // Navegar a la página de detalles del vehículo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailPage(
              vehicleId: vehicleData['id'],
              vin: vehicleData['vin'],
              brand: vehicleData['model']['brand']['name'],
              model: vehicleData['model']['name'],
              isUrgent: vehicleData['is_urgent'],
              status: vehicleData['current_state']['name'], // Ajusta según tu estructura de datos
              token: widget.token,
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        _showErrorDialog('No se encontró un vehículo con el VIN proporcionado.');
      } else {
        _showErrorDialog('Error al buscar el vehículo. Código: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error al conectar con el servidor. Por favor, inténtelo más tarde.');
    }
  }

  // Método para mostrar el diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,  // Fondo oscuro
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

  // Método para mostrar los códigos detectados y permitir que el usuario elija uno
  void _showDetectedCodesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,  // Fondo oscuro
          title: Text(
            'Selecciona un código',
            style: TextStyle(color: Colors.white),  // Texto blanco en el título
          ),
          content: detectedCodes.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No se detectó ningún código VIN.',
                      style: TextStyle(color: Colors.white70),  // Texto gris claro
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Por favor, introduzca el VIN manualmente.',
                      style: TextStyle(color: Colors.white70),  // Texto gris claro
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: detectedCodes.map((code) {
                    return ListTile(
                      title: Text(
                        'Tipo: ${code['type']}',
                        style: TextStyle(color: Colors.white),  // Texto blanco para el tipo
                      ),
                      subtitle: Text(
                        'Código: ${code['data']}',
                        style: TextStyle(color: Colors.white70),  // Texto gris claro para el código
                      ),
                      onTap: () {
                        setState(() {
                          _vin = code['data'];
                          _vinController.text = _vin!;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cerrar',
                style: TextStyle(color: Colors.blueAccent),  // Texto del botón
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
    } else if (index == 1) {
      // Navegar a la página para añadir vehículo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(token: widget.token),
        ),
      );
    } else if (index == 2) {
      // Lógica para el botón "Cuenta"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Buscar Vehículo', style: Theme.of(context).textTheme.titleLarge),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TextField para el VIN leído o manual
            TextField(
              controller: _vinController,
              decoration: InputDecoration(
                hintText: 'Introducir VIN',
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _scanQRorBarcode,  // Escaneo QR al presionar el ícono de cámara
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.black54,  // Fondo oscuro
              ),
              style: TextStyle(color: Colors.white),  // Texto en blanco
            ),
            SizedBox(height: 20),
            // Botón para buscar el vehículo
            ElevatedButton(
              onPressed: _vinController.text.isNotEmpty ? _searchVehicle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Buscar Vehículo', style: TextStyle(color: Colors.white)),
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
