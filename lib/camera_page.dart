// lib/camera_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'custom_footer.dart';
import 'home_page.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final TextEditingController _vinController = TextEditingController();
  bool _isLoading = false;
  bool _isUrgent = false;
  int? _selectedModel;
  int? _selectedColor;
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _colors = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchModelsAndColors();
  }

  Future<void> _fetchModelsAndColors() async {
    setState(() {
      _isLoading = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final models = await apiService.getVehicleModels();
      final colors = await apiService.getVehicleColors();

      setState(() {
        _models = models.map((model) {
          return {
            'id': model['id'],
            'name': '${model['brand']['name']} ${model['name']}',
          };
        }).toList();

        _colors = colors.map((color) {
          return {
            'id': color['id'],
            'name': color['name'],
            'hex_code': color['hex_code'],
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Error al obtener los modelos y colores: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerVehicle() async {
    setState(() {
      _isLoading = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.createVehicle(
        vehicleModelId: _selectedModel!,
        vin: _vinController.text,
        colorId: _selectedColor!,
        isUrgent: _isUrgent,
      );

      _showSuccessDialog('Vehículo registrado exitosamente.');
    } catch (e) {
      _showErrorDialog('Error al registrar el vehículo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: source);

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

  void _showVinSelectionDialog(List<Map<String, dynamic>> detectedCodes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF2F2F2), // Fondo del diálogo
          title: Text(
            'Seleccionar VIN',
            style: TextStyle(
              color: Color(0xFFA64F03), // Color del título
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: detectedCodes.map((code) {
                return ListTile(
                  title: Text(
                    '${code['type']}: ${code['data']}',
                    style: TextStyle(color: Color(0xFF262626)), // Color del texto
                  ),
                  onTap: () {
                    setState(() {
                      _vinController.text = code['data'];
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF2CB05), // Fondo del botón
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF262626), // Color del texto del botón
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Éxito'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      backgroundColor: Color(0xFFF2F2F2), // Fondo del modal
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFFA64F03)),
                title: Text(
                  'Seleccionar de la Galería',
                  style: TextStyle(color: Color(0xFFA64F03)), // Color del texto
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Color(0xFFA64F03)),
                title: Text(
                  'Tomar Foto',
                  style: TextStyle(color: Color(0xFFA64F03)), // Color del texto
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2), // Fondo claro
      appBar: AppBar(
        title: Text('Registrar Vehículo', style: TextStyle(color: Color(0xFF262626))),
        backgroundColor: Color(0xFFF2F2F2), // Color principal en AppBar
        iconTheme: IconThemeData(color: Color(0xFF262626)),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _vinController,
                      style: TextStyle(color: Color(0xFFA64F03)), // Color del texto dentro del campo
                      decoration: InputDecoration(
                        labelText: 'VIN',
                        labelStyle: TextStyle(color: Color(0xFFA64F03)),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFA64F03)), // Borde inactivo
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFA64F03)), // Borde cuando no está seleccionado
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF2CB05)), // Borde cuando está seleccionado
                          ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.camera_alt, color: Color(0xFFA64F03)),
                          onPressed: _showImageSourceActionSheet,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: _selectedModel,
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedModel = newValue;
                        });
                      },
                      items: _models.map<DropdownMenuItem<int>>((model) {
                        return DropdownMenuItem<int>(
                          value: model['id'],
                          child: Text(model['name'], style: TextStyle(color: Color(0xFFA64F03))),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Modelo',
                        labelStyle: TextStyle(color: Color(0xFFA64F03)),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFA64F03)), // Borde inactivo
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFA64F03)), // Borde cuando no está seleccionado
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF2CB05)), // Borde cuando está seleccionado
                          ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down, // Icono de la flecha
                        color: Color(0xFFA64F03), // Color de la flecha
                      ),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: _selectedColor,
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedColor = newValue;
                        });
                      },
                      items: _colors.map<DropdownMenuItem<int>>((color) {
                        return DropdownMenuItem<int>(
                          value: color['id'],
                          child: Text(color['name'], style: TextStyle(color: Color(0xFFA64F03))),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Color',
                        labelStyle: TextStyle(color: Color(0xFFA64F03)),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFA64F03)), // Borde inactivo
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFA64F03)), // Borde cuando no está seleccionado
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF2CB05)), // Borde cuando está seleccionado
                          ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down, // Icono de la flecha
                        color: Color(0xFFA64F03), // Color de la flecha
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Urgente', style: TextStyle(color: Color(0xFF262626))),
                        Switch(
                          value: _isUrgent,
                          onChanged: (value) {
                            setState(() {
                              _isUrgent = value;
                            });
                          },
                          activeColor: Color(0xFFF2CB05),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_vinController.text.isNotEmpty && _selectedModel != null && _selectedColor != null)
                          ? _registerVehicle
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF2B33D),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Registrar Vehículo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF2B33D),
                ),
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
    }
  }
}
