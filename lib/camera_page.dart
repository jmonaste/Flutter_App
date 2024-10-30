import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'constants.dart';
import 'custom_drawer.dart';  // Importa el CustomDrawer
import 'custom_footer.dart';  // Importa el CustomFooter
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
  List<Map<String, dynamic>> _models = [];  // Lista de modelos con id y name
  Map<String, dynamic>? _selectedModel;  // Modelo seleccionado en el desplegable
  bool _isUrgent = false;  // Booleano para manejar la urgencia del vehículo
  final picker = ImagePicker();
  final TextEditingController _vinController = TextEditingController();
  int _selectedIndex = 1;  // Por defecto, el índice estará en "Administrar"
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;  // Spinner de carga

  @override
  void initState() {
    super.initState();
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
    var url = Uri.parse('$baseUrl/api/models');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
    });

    if (response.statusCode == 200) {
      List<dynamic> modelsJson = jsonDecode(response.body);
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

    try {
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

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isLoading = false;  // Desactiva el spinner
      });

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
    // Usamos el valor del VIN que está en el TextField, no el seleccionado
    String vinToSend = _vinController.text.trim();
    if (vinToSend.isEmpty || _selectedModel == null) {
      _showErrorDialog('Por favor, ingrese el VIN y seleccione un modelo de vehículo.');
      return; // Evita hacer la petición si no hay VIN o modelo seleccionado
    }

    int modelId = _selectedModel!['id'];  // Recupera el ID del modelo seleccionado

    setState(() {
      _isLoading = true;  // Activa el spinner durante la solicitud
    });

    try {
      var url = Uri.parse('$baseUrl/api/vehicles');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'vehicle_model_id': modelId,
          'vin': vinToSend,  // Usar el VIN del TextField
          'is_urgent': _isUrgent,
        }),
      );

      setState(() {
        _isLoading = false;  // Desactiva el spinner
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        var decodedResponse = jsonDecode(response.body);
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
                    builder: (context) => HomePage(token: widget.token),
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
          builder: (context) => HomePage(token: widget.token),
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
        title: Text('Camera Page', style: Theme.of(context).textTheme.titleLarge),
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
        token: widget.token,
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
                    onPressed: (_vinController.text.isNotEmpty && _selectedModel != null)
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
