// lib/camera_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart'; // Importa Dio
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart'; // Importa ApiService
import 'custom_drawer.dart';  // Importa el CustomDrawer
import 'custom_footer.dart';  // Importa el CustomFooter
import 'home_page.dart';  // Importa HomePage para la navegación de "Inicio"

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  Uint8List? _webImage;
  String? _vin;
  List<Map<String, dynamic>> detectedCodes = [];

  List<Map<String, dynamic>> _models = [];  // Lista de modelos con id y name
  Map<String, dynamic>? _selectedModel;  // Modelo seleccionado en el desplegable

  List<Map<String, dynamic>> _colors = [];  // Lista de colores con id y name
  Map<String, dynamic>? _selectedColor;  // Color seleccionado en el desplegable

  bool _isUrgent = false;  // Booleano para manejar la urgencia del vehículo
  final picker = ImagePicker();
  final TextEditingController _vinController = TextEditingController();
  int _selectedIndex = 1;  // Por defecto, el índice estará en "Administrar"
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;  // Spinner de carga

  @override
  void initState() {
    super.initState();
    _fetchColors();  // Llamada a la API para obtener los colores de vehículos
    _fetchModels();  // Llamada a la API para obtener los modelos de vehículos
  }

  // Método para verificar y solicitar permisos de cámara
  Future<void> _checkPermissions() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  // Método para obtener los modelos de vehículos desde la API
  Future<void> _fetchModels() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/models');
      if (response.statusCode == 200) {
        List<dynamic> modelsJson = response.data;
        setState(() {
          _models = modelsJson.map((model) {
            return {
              'id': model['id'],  // Guardamos el id del modelo
              'name': '${model['brand']['name']} ${model['name']}',  // Formato "Brand Model"
            };
          }).toList();
        });
      } else {
        print('Error fetching models. Status: ${response.statusCode}');
        _showErrorDialog('Error al obtener los modelos de vehículos.');
      }
    } catch (e) {
      print('Exception while fetching models: $e');
      _showErrorDialog('Hubo un problema al obtener los modelos de vehículos.');
    }
  }

  // Método para obtener los colores de vehículos desde la API
  Future<void> _fetchColors() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/colors');

      if (response.statusCode == 200) {
        List<dynamic> colorsJson = response.data;
        setState(() {
          _colors = colorsJson.map((color) {
            return {
              'id': color['id'],  // Guardamos el id del color
              'name': color['name'],  // Nombre del color
              'hex_code': color['hex_code'],  // Código hexadecimal del color
            };
          }).toList();
        });
      } else {
        print('Error fetching colors. Status: ${response.statusCode}');
        _showErrorDialog('Error al obtener los colores de vehículos.');
      }
    } catch (e) {
      print('Exception while fetching colors: $e');
      _showErrorDialog('Hubo un problema al obtener los colores de vehículos.');
    }
  }

  // Método para mostrar el selector de origen de la imagen (Cámara o Galería)
  Future<void> _chooseImageSource() async {
    await _checkPermissions();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Usar Cámara"),
              onTap: () async {
                Navigator.of(context).pop();
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Seleccionar de Galería"),
              onTap: () async {
                Navigator.of(context).pop();
                await _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  // Método para seleccionar una imagen desde la cámara o la galería
  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
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
        _showErrorDialog('No se seleccionó ninguna imagen. Intente nuevamente.');
      }
    } catch (e) {
      print('Error al obtener la imagen: $e');
      _showErrorDialog('Hubo un problema al acceder a la cámara o galería. Intente nuevamente.');
    }
  }

  // Método para subir la imagen seleccionada al servidor
  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) {
      print('No image selected.');
      _showErrorDialog('No se seleccionó ninguna imagen. Intente nuevamente.');
      return;
    }

    setState(() {
      _isLoading = true;  // Activa el spinner
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      FormData formData;
      if (kIsWeb) {
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _webImage!,
            filename: 'qr_sample.jpeg',
            contentType: MediaType('image', 'jpeg'),
          ),
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            _imageFile!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        });
      }

      final response = await apiService.dio.post(
        '/scan',
        data: formData,
      );

      setState(() {
        _isLoading = false;  // Desactiva el spinner
      });

      if (response.statusCode == 200) {
        var decodedResponse = response.data;
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
        var decodedResponse = response.data;
        setState(() {
          detectedCodes = [];
          if (decodedResponse['error'] == 'No QR or Barcode detected') {
            _showErrorDialog('No se detectaron códigos QR o de barras. Introduzca el VIN manualmente.');
          } else if (decodedResponse['detail'] == 'Unsupported file type') {
            _showErrorDialog('El tipo de archivo no es compatible.');
          } else {
            _showErrorDialog('Error al subir la imagen. Código: ${response.statusCode}');
          }
        });
      } else {
        print('Error al subir la imagen. Código de estado: ${response.statusCode}');
        _showErrorDialog('Error al subir la imagen. Intente nuevamente.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;  // Desactiva el spinner en caso de error
      });
      print('Error durante la solicitud: $e');
      _showErrorDialog('Hubo un problema al procesar la imagen. Intente nuevamente.');
    }
  }

  // Método para registrar el vehículo en el servidor
  Future<void> _registerVehicle() async {
    String vinToSend = _vinController.text.trim();

    if (vinToSend.isEmpty || _selectedModel == null || _selectedColor == null) {
      _showErrorDialog('Por favor, ingrese el VIN y seleccione un modelo de vehículo.');
      return; // Evita hacer la petición si no hay VIN o modelo seleccionado
    }

    int modelId = _selectedModel!['id'];  // Recupera el ID del modelo seleccionado
    int colorId = _selectedColor!['id'];    // Recupera el ID del color seleccionado

    setState(() {
      _isLoading = true;  // Activa el spinner durante la solicitud
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.post(
        '/api/vehicles',
        data: {
          'vehicle_model_id': modelId,
          'vin': vinToSend,
          'color_id': colorId,
          'is_urgent': _isUrgent,
        },
      );

      setState(() {
        _isLoading = false;  // Desactiva el spinner
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        var decodedResponse = response.data;
        String errorMessage = 'Error al dar de alta el vehículo. Código: ${response.statusCode}';
        if (decodedResponse.containsKey('detail')) {
          errorMessage = decodedResponse['detail'];
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;  // Desactiva el spinner en caso de error
      });
      print('Error al registrar el vehículo: $e');
      _showErrorDialog('Hubo un problema al registrar el vehículo. Intente nuevamente.');
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
              : SingleChildScrollView(
                  child: Column(
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
                ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cerrar',
                style: TextStyle(color: Colors.blueAccent),  // Texto del botón con el color primario
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

  // Método para mostrar el diálogo de éxito
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Vehículo registrado', style: TextStyle(color: Colors.white)),
          content: Text('El vehículo ha sido dado de alta con éxito.', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                // Navega al HomePage después de cerrar el diálogo
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                  (Route<dynamic> route) => false,
                );
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
          builder: (context) => HomePage(),
        ),
      );
    } else if (index == 2) {
      // Lógica para el botón "Cuenta"
      // Puedes navegar a la página de cuenta aquí
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Añadir Vehículo', style: Theme.of(context).textTheme.titleLarge),
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
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(  // Añadido para evitar overflow en pantallas pequeñas
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
                        onPressed: _chooseImageSource,  // Lógica del escaneo QR al presionar el ícono de cámara
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.black54,  // Fondo oscuro
                    ),
                    style: TextStyle(color: Colors.white),  // Texto en blanco
                    onChanged: (value) {
                      setState(() {});  // Actualiza el estado para habilitar/deshabilitar el botón
                    },
                  ),
                  SizedBox(height: 20),
                  // Dropdown para seleccionar el modelo de vehículo
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: InputDecoration(
                      hintText: 'Seleccionar modelo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.black54,  // Fondo oscuro
                    ),
                    dropdownColor: Colors.black54,
                    value: _selectedModel,
                    items: _models.map((model) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: model,
                        child: Text(model['name'], style: TextStyle(color: Colors.white)),  // Texto en blanco
                      );
                    }).toList(),
                    onChanged: (Map<String, dynamic>? newValue) {
                      setState(() {
                        _selectedModel = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  // Dropdown para seleccionar el color del vehículo
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: InputDecoration(
                      hintText: 'Seleccionar color',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.black54,  // Fondo oscuro
                    ),
                    dropdownColor: Colors.black54,
                    value: _selectedColor,
                    items: _colors.map((color) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: color,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(int.parse(color['hex_code'].substring(1, 7), radix: 16) + 0xFF000000),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(color['name'], style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Map<String, dynamic>? newValue) {
                      setState(() {
                        _selectedColor = newValue!;
                      });
                    },
                  ),
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
                  SizedBox(height: 20),
                  // Botón para dar de alta el vehículo
                  ElevatedButton(
                    onPressed: (_vinController.text.isNotEmpty && _selectedModel != null && _selectedColor != null)
                        ? _registerVehicle
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Dar de alta el vehículo', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
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
