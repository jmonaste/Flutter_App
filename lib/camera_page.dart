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
          title: Text('Seleccionar VIN'),
          content: SingleChildScrollView(
            child: Column(
              children: detectedCodes.map((code) {
                return ListTile(
                  title: Text('${code['type']}: ${code['data']}'),
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
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Seleccionar de la Galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Tomar Foto'),
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
      appBar: AppBar(
        title: Text('Registrar Vehículo'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _vinController,
                    decoration: InputDecoration(
                      labelText: 'VIN',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: _showImageSourceActionSheet,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text('Tomar Foto'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text('Seleccionar de la Galería'),
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
                        child: Text(model['name']),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
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
                        child: Text(color['name']),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Urgente'),
                      Switch(
                        value: _isUrgent,
                        onChanged: (value) {
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
}