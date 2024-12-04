// lib/manage_vehicle_brand.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';

class ManageVehicleBrandPage extends StatefulWidget {
  @override
  _ManageVehicleBrandPageState createState() => _ManageVehicleBrandPageState();
}

class _ManageVehicleBrandPageState extends State<ManageVehicleBrandPage> {
  List<Map<String, dynamic>> _vehicleBrands = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicleBrands();
  }

  /// Obtiene las marcas de vehículos desde la API
  Future<void> _fetchVehicleBrands() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final vehicleBrands = await apiService.getVehicleBrands();
      setState(() {
        _vehicleBrands = vehicleBrands;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener las marcas de vehículos.';
        _isLoading = false;
      });
    }
  }

  /// Actualiza una marca de vehículo
  Future<void> _updateVehicleBrand(int id, String name) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.updateVehicleBrand(id, name);
      _fetchVehicleBrands(); // Refrescar la lista de marcas de vehículos
    } catch (e) {
      _showErrorDialog('Error al actualizar la marca de vehículo.');
    }
  }

  /// Elimina una marca de vehículo
  Future<void> _deleteVehicleBrand(int id) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.deleteVehicleBrand(id);
      _fetchVehicleBrands(); // Refrescar la lista de marcas de vehículos
    } catch (e) {
      _showErrorDialog('Error al eliminar la marca de vehículo.');
    }
  }

  /// Crea una nueva marca de vehículo
  Future<void> _createVehicleBrand(String name) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.createVehicleBrand(name);
      _fetchVehicleBrands(); // Refrescar la lista de marcas de vehículos
    } catch (e) {
      _showErrorDialog('Error al crear la marca de vehículo.');
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
        title: Text('Gestionar Marcas de Vehículos'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _vehicleBrands.length,
                  itemBuilder: (context, index) {
                    final vehicleBrand = _vehicleBrands[index];
                    return ListTile(
                      title: Text(vehicleBrand['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditVehicleBrandDialog(vehicleBrand['id'], vehicleBrand['name']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteVehicleBrand(vehicleBrand['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateVehicleBrandDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  /// Muestra un diálogo para editar una marca de vehículo
  void _showEditVehicleBrandDialog(int id, String currentName) {
    final TextEditingController _controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Marca de Vehículo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nombre de la Marca de Vehículo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateVehicleBrand(id, _controller.text);
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para crear una nueva marca de vehículo
  void _showCreateVehicleBrandDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crear Nueva Marca de Vehículo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nombre de la Marca de Vehículo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createVehicleBrand(_controller.text);
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}