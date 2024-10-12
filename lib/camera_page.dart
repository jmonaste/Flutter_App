import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';  // Importar para manejar tipos MIME

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  Uint8List? _webImage;  // Para almacenar la imagen en Flutter Web
  String? _scanResult;   // Variable para almacenar el resultado del servidor
  final picker = ImagePicker();

  // Método para seleccionar una imagen desde la cámara
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              _webImage = bytes;
              _scanResult = null;  // Limpiar el resultado previo cuando se selecciona una nueva imagen
            });
          });
        } else {
          _imageFile = File(pickedFile.path);
          _scanResult = null;  // Limpiar el resultado previo
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

    // Enviar la solicitud y obtener la respuesta
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      setState(() {
        _scanResult = decodedResponse.toString();  // Almacenar la respuesta en _scanResult
      });
      print('Respuesta del servidor: $decodedResponse');
    } else {
      setState(() {
        _scanResult = 'Error al subir la imagen. Código de estado: ${response.statusCode}';
      });
      print('Error al subir la imagen. Código de estado: ${response.statusCode}');
    }
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
            if (kIsWeb)
              _webImage == null
                  ? Text('No image selected.')
                  : Image.memory(_webImage!),  // Mostrar la imagen en Flutter Web
            if (!kIsWeb)
              _imageFile == null
                  ? Text('No image selected.')
                  : Image.file(_imageFile!),  // Mostrar la imagen en plataformas móviles
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Capture Image'),
            ),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image'),
            ),
            SizedBox(height: 20),
            if (_scanResult != null)
              Text(
                'Resultado del servidor: $_scanResult',  // Mostrar el resultado del servidor
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
