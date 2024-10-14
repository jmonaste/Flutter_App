import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'home_page.dart';  // Importa HomePage para la navegación de "Inicio"

class CameraPage extends StatefulWidget {
  final String token;

  const CameraPage({Key? key, required this.token}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  Uint8List? _webImage;
  String? _vin;
  List<Map<String, dynamic>> detectedCodes = [];
  List<String> _models = [];  // Lista de modelos para el desplegable
  String? _selectedModel;  // Modelo seleccionado en el desplegable
  bool _isUrgent = false;  // Booleano para manejar la urgencia del vehículo
  final picker = ImagePicker();
  final TextEditingController _vinController = TextEditingController();
  int _selectedIndex = 1;  // Por defecto, el índice estará en "Administrar"

  @override
  void initState() {
    super.initState();
    _fetchModels();  // Llamada a la API para obtener los modelos de vehículos
  }

  Future<void> _fetchModels() async {
    var url = Uri.parse('http://192.168.1.45:8000/api/models');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      List<dynamic> modelsJson = jsonDecode(response.body);
      setState(() {
        _models = modelsJson.map((model) {
          return '${model['brand']['name']} ${model['name']}';  // Formato "Brand Model"
        }).toList();
      });
    } else {
      print('Error fetching models. Status: ${response.statusCode}');
    }
  }

  Future<void> _scanQRorBarcode() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          pickedFile.readAsBytes().then((bytes) {
            _webImage = bytes;
            _uploadImage();
          });
        } else {
          _imageFile = File(pickedFile.path);
          _uploadImage();
        }
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) {
      print('No image selected.');
      return;
    }

    var uri = Uri.parse('http://192.168.1.45:8000/scan');
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
    }
  }

  // Método para mostrar el diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
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
          title: Text('Selecciona un código'),
          content: detectedCodes.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No se detectó ningún código VIN.'),
                    SizedBox(height: 10),
                    Text('Por favor, introduzca el VIN manualmente.'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: detectedCodes.map((code) {
                    return ListTile(
                      title: Text('Tipo: ${code['type']}'),
                      subtitle: Text('Código: ${code['data']}'),
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
              child: Text('Cerrar'),
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
    } else if (index == 2) {
      // Lógica para el botón "Cuenta"
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
        appBar: AppBar(
          title: Text('Camera Page', style: Theme.of(context).textTheme.titleLarge),
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
                    onPressed: _scanQRorBarcode,  // Lógica del escaneo QR al presionar el ícono de cámara
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.black54,
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              // Dropdown para seleccionar el modelo de vehículo
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Seleccionar modelo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.black54,
                ),
                dropdownColor: Colors.black54,
                value: _selectedModel,
                items: _models.map((model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(model, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedModel = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),
              // Switch para indicar si el vehículo es urgente
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '¿Marcar como urgente?',
                    style: TextStyle(color: Colors.white),
                  ),
                  Switch(
                    value: _isUrgent,
                    onChanged: (bool value) {
                      setState(() {
                        _isUrgent = value;
                      });
                    },
                    activeColor: Colors.blueAccent,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Administrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Cuenta',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.black87,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
