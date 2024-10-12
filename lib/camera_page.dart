import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';  // Importar para manejar tipos MIME

class CameraPage extends StatefulWidget {
  final String token;

  const CameraPage({Key? key, required this.token}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  Uint8List? _webImage;  // Para almacenar la imagen en Flutter Web
  String? _vin;   // Variable para almacenar el VIN seleccionado
  List<Map<String, dynamic>> detectedCodes = [];  // Cambiar el tipo a List<Map<String, dynamic>>
  final picker = ImagePicker();

  // Método para seleccionar una imagen desde la cámara y subirla automáticamente
  Future<void> _scanQRorBarcode() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          pickedFile.readAsBytes().then((bytes) {
            _webImage = bytes;
            _uploadImage(); // Subir automáticamente después de seleccionar la imagen
          });
        } else {
          _imageFile = File(pickedFile.path);
          _uploadImage(); // Subir automáticamente después de seleccionar la imagen
        }
      });
    } else {
      print('No image selected.');
    }
  }

  // Método para subir la imagen a la API
  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) {
      print('No image selected.');
      return;
    }

    var uri = Uri.parse('http://192.168.1.45:8000/scan');
    var request = http.MultipartRequest('POST', uri);

    // Enviar el archivo con el tipo MIME correcto
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _webImage!,
        filename: 'qr_sample.jpeg',
        contentType: MediaType('image', 'jpeg'), // Especificar el tipo MIME manualmente
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
        contentType: MediaType('image', 'jpeg'), // Especificar el tipo MIME manualmente
      ));
    }

    // Añadir el encabezado Authorization con el token
    request.headers['Authorization'] = 'Bearer ${widget.token}';  // Usar el token recibido

    // Enviar la solicitud y obtener la respuesta
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      setState(() {
        // Extraer los códigos detectados
        List<dynamic> detectedCodesJson = decodedResponse['detected_codes'];
        detectedCodes = detectedCodesJson.map((code) {
          return {
            'type': code['type'],
            'data': code['data'],
          };
        }).toList();
        
        // Mostrar los códigos detectados en el modal
        _showDetectedCodesDialog();
      });
    } else {
      setState(() {
        detectedCodes = [];
        print('Error al subir la imagen. Código de estado: ${response.statusCode}');
      });
    }
  }

  // Método para mostrar el modal con los códigos detectados y permitir que el usuario elija uno
  void _showDetectedCodesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecciona un código'),
          content: detectedCodes.isEmpty
              ? Text('No se detectaron códigos')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: detectedCodes.map((code) {
                    return ListTile(
                      title: Text('Tipo: ${code['type']}'),
                      subtitle: Text('Código: ${code['data']}'),
                      onTap: () {
                        setState(() {
                          _vin = code['data'];
                        });
                        Navigator.of(context).pop();
                        _showSelectedVinDialog();
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

  // Mostrar el VIN seleccionado en un nuevo modal para confirmar o editar
  void _showSelectedVinDialog() {
    TextEditingController _controller = TextEditingController(text: _vin);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar VIN'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Introduce o edita el VIN'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () {
                setState(() {
                  _vin = _controller.text;
                });
                Navigator.of(context).pop();
                print('VIN Confirmado: $_vin'); // Aquí puedes usar el VIN para el siguiente paso
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _scanQRorBarcode,
              child: Text('Escanear QR o BarCode'),
            ),
            ElevatedButton(
              onPressed: () {
                _showSelectedVinDialog();  // Permitir ingresar el VIN manualmente
              },
              child: Text('Introducir VIN manualmente'),
            ),
          ],
        ),
      ),
    );
  }
}
