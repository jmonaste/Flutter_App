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
  Uint8List? _webImage;
  String? _vin;
  List<Map<String, dynamic>> detectedCodes = [];
  final picker = ImagePicker();

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
                        });
                        Navigator.of(context).pop();
                        _showSelectedVinDialog();
                      },
                    );
                  }).toList(),
                ),
          actions: <Widget>[
            if (detectedCodes.isEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSelectedVinDialog();
                },
                child: Text('Introducir VIN manualmente'),
              ),
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
                print('VIN Confirmado: $_vin');
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
                _showSelectedVinDialog();
              },
              child: Text('Introducir VIN manualmente'),
            ),
          ],
        ),
      ),
    );
  }
}
