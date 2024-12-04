// lib/manage_vehicle_models.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';

class ManageVehicleModelsPage extends StatefulWidget {
  @override
  _ManageVehicleModelsPageState createState() => _ManageVehicleModelsPageState();
}

class _ManageVehicleModelsPageState extends State<ManageVehicleModelsPage> {
  List<Map<String, dynamic>> _vehicleModels = [];
  List<Map<String, dynamic>> _vehicleBrands = [];
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// Obtiene los datos iniciales necesarios (modelos, marcas y tipos de vehículos)
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final vehicleModels = await apiService.getVehicleModels();
      final vehicleBrands = await apiService.getVehicleBrands();
      final vehicleTypes = await apiService.getVehicleTypes();

      setState(() {
        _vehicleModels = vehicleModels ?? [];
        _vehicleBrands = vehicleBrands ?? [];
        _vehicleTypes = vehicleTypes ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener los datos iniciales.';
        _isLoading = false;
      });
    }
  }

  /// Actualiza un modelo de vehículo
  Future<void> _updateVehicleModel(int id, String name, int brandId, int typeId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.updateVehicleModel(id, name, brandId, typeId);
      _fetchInitialData(); // Refrescar la lista de modelos de vehículos
    } catch (e) {
      _showErrorDialog('Error al actualizar el modelo de vehículo.');
    }
  }

  /// Elimina un modelo de vehículo
  Future<void> _deleteVehicleModel(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.deleteVehicleModel(id);
      _fetchInitialData(); // Refrescar la lista de modelos de vehículos
    } catch (e) {
      _showErrorDialog('Error al eliminar el modelo de vehículo.');
    }
  }

  /// Crea un nuevo modelo de vehículo
  Future<void> _createVehicleModel(String name, int brandId, int typeId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.createVehicleModel(name, brandId, typeId);
      _fetchInitialData(); // Refrescar la lista de modelos de vehículos
    } catch (e) {
      _showErrorDialog('Error al crear el modelo de vehículo.');
    }
  }

  /// Muestra un diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
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
        title: Text('Gestionar Modelos de Vehículos'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _vehicleModels.length,
                  itemBuilder: (context, index) {
                    final vehicleModel = _vehicleModels[index];
                    return ListTile(
                      title: Text(vehicleModel['name']),
                      subtitle: Text('Marca: ${vehicleModel['brand']['name']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showUpdateDialog(vehicleModel['id'], vehicleModel['name'], vehicleModel['brand']['id'], vehicleModel['type_id']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteVehicleModel(vehicleModel['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateVehicleModelDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  /// Muestra un diálogo para actualizar el nombre, marca y tipo de un modelo
  void _showUpdateDialog(int id, String currentModelName, int currentBrandId, int currentTypeId) async {
    final TextEditingController _controller = TextEditingController(text: currentModelName);
    int selectedBrandId = currentBrandId;
    int selectedTypeId = currentTypeId;

    // Obtener las marcas y tipos de vehículos
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final vehicleBrands = await apiService.getVehicleBrands();
      final vehicleTypes = await apiService.getVehicleTypes();

      setState(() {
        _vehicleBrands = vehicleBrands ?? [];
        _vehicleTypes = vehicleTypes ?? [];
      });
    } catch (e) {
      _showErrorDialog('Error al obtener las marcas y tipos de vehículos.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Actualizar Modelo de Vehículo'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(labelText: 'Nombre del modelo'),
                    ),
                    SizedBox(height: 20),
                    DropdownButton<int>(
                      value: selectedBrandId,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedBrandId = newValue!;
                        });
                      },
                      items: _vehicleBrands.map<DropdownMenuItem<int>>((brand) {
                        return DropdownMenuItem<int>(
                          value: brand['id'],
                          child: Text(brand['name']),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    DropdownButton<int>(
                      value: selectedTypeId,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedTypeId = newValue!;
                        });
                      },
                      items: _vehicleTypes.map<DropdownMenuItem<int>>((type) {
                        return DropdownMenuItem<int>(
                          value: type['id'],
                          child: Text(type['type_name']),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateVehicleModel(id, _controller.text, selectedBrandId, selectedTypeId);
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra un diálogo para crear un nuevo modelo de vehículo
  void _showCreateVehicleModelDialog() {
    final TextEditingController _controller = TextEditingController();
    int selectedBrandId = _vehicleBrands.isNotEmpty ? _vehicleBrands[0]['id'] : 0;
    int selectedTypeId = _vehicleTypes.isNotEmpty ? _vehicleTypes[0]['id'] : 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crear Nuevo Modelo de Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(labelText: 'Nombre del modelo'),
                ),
                SizedBox(height: 20),
                DropdownButton<int>(
                  value: selectedBrandId,
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedBrandId = newValue!;
                    });
                  },
                  items: _vehicleBrands.map<DropdownMenuItem<int>>((brand) {
                    return DropdownMenuItem<int>(
                      value: brand['id'],
                      child: Text(brand['name']),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                DropdownButton<int>(
                  value: selectedTypeId,
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedTypeId = newValue!;
                    });
                  },
                  items: _vehicleTypes.map<DropdownMenuItem<int>>((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'],
                      child: Text(type['type_name']),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createVehicleModel(_controller.text, selectedBrandId, selectedTypeId);
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}