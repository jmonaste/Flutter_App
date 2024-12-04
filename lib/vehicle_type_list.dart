// lib/vehicle_type_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';

class VehicleTypeListPage extends StatefulWidget {
  @override
  _VehicleTypeListPageState createState() => _VehicleTypeListPageState();
}

class _VehicleTypeListPageState extends State<VehicleTypeListPage> {
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicleTypes();
  }

  /// Obtiene los tipos de vehículos desde la API
  Future<void> _fetchVehicleTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final vehicleTypes = await apiService.getVehicleTypes();
      setState(() {
        _vehicleTypes = vehicleTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener los tipos de vehículos.';
        _isLoading = false;
      });
    }
  }

  /// Actualiza un tipo de vehículo
  Future<void> _updateVehicleType(int id, String typeName) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.updateVehicleType(id, typeName);
      _fetchVehicleTypes(); // Refrescar la lista de tipos de vehículos
    } catch (e) {
      _showErrorDialog('Error al actualizar el tipo de vehículo.');
    }
  }

  /// Elimina un tipo de vehículo
  Future<void> _deleteVehicleType(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.deleteVehicleType(id);
      _fetchVehicleTypes(); // Refrescar la lista de tipos de vehículos
    } catch (e) {
      _showErrorDialog('Error al eliminar el tipo de vehículo.');
    }
  }

  /// Crea un nuevo tipo de vehículo
  Future<void> _createVehicleType(String typeName) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.createVehicleType(typeName);
      _fetchVehicleTypes(); // Refrescar la lista de tipos de vehículos
    } catch (e) {
      _showErrorDialog('Error al crear el tipo de vehículo.');
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
        title: Text('Tipos de Vehículos'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _vehicleTypes.length,
                  itemBuilder: (context, index) {
                    final vehicleType = _vehicleTypes[index];
                    return ListTile(
                      title: Text(vehicleType['type_name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditVehicleTypeDialog(vehicleType['id'], vehicleType['type_name']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteVehicleType(vehicleType['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateVehicleTypeDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  /// Muestra un diálogo para editar un tipo de vehículo
  void _showEditVehicleTypeDialog(int id, String currentTypeName) {
    final TextEditingController _controller = TextEditingController(text: currentTypeName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Tipo de Vehículo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nombre del Tipo de Vehículo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateVehicleType(id, _controller.text);
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para crear un nuevo tipo de vehículo
  void _showCreateVehicleTypeDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crear Nuevo Tipo de Vehículo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nombre del Tipo de Vehículo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createVehicleType(_controller.text);
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}