// lib/vehicle_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

class VehicleDetailPage extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailPage({Key? key, required this.vehicleId}) : super(key: key);

  @override
  VehicleDetailPageState createState() => VehicleDetailPageState();
}

class VehicleDetailPageState extends State<VehicleDetailPage> {
  Map<String, dynamic>? _vehicleData;
  List<Map<String, dynamic>> _allowedTransitions = [];
  bool _isLoading = true; // Variable para manejar el estado de carga
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// Obtiene datos del vehículo y transiciones permitidas
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // Realizar las llamadas a la API en paralelo
      final vehicleData = await apiService.getVehicleDetails(widget.vehicleId);
      final allowedTransitions = await apiService.getAllowedTransitions(widget.vehicleId);

      setState(() {
        _vehicleData = vehicleData;
        _allowedTransitions = allowedTransitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener los datos del vehículo.';
        _isLoading = false;
      });
    }
  }

  /// Muestra un modal para seleccionar un comentario y cambiar el estado del vehículo
  Future<void> _showCommentSelectionModal(int newStateId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    List<Map<String, dynamic>> comments = [];

    try {
      comments = await apiService.getCommentsForState(newStateId);
    } catch (e) {
      _showErrorDialog('Error al obtener los comentarios.');
      return;
    }

    if (comments.isEmpty) {
      _showErrorDialog('No hay comentarios disponibles para este estado.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedCommentId;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Seleccionar Comentario'),
              content: SingleChildScrollView(
                child: Column(
                  children: comments.map((comment) {
                    return RadioListTile<int>(
                      title: Text(comment['comment']),
                      value: comment['id'],
                      groupValue: selectedCommentId,
                      onChanged: (int? value) {
                        setState(() {
                          selectedCommentId = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedCommentId == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _changeVehicleState(newStateId, selectedCommentId!);
                        },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Cambia el estado del vehículo
  Future<void> _changeVehicleState(int newStateId, int commentId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.changeVehicleState(widget.vehicleId, newStateId, commentId);
      _fetchInitialData(); // Refrescar los datos del vehículo
    } catch (e) {
      _showErrorDialog('Error al cambiar el estado del vehículo.');
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
        title: Text('Detalles del Vehículo'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _vehicleData != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_vehicleData!['model']['brand']['name']} ${_vehicleData!['model']['name']}',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Text('VIN: ${_vehicleData!['vin']}', style: TextStyle(fontSize: 18)),
                                  Text('Estado: ${_vehicleData!['status']['name']}', style: TextStyle(fontSize: 18)),
                                  Text('Color: ${_vehicleData!['color']['name']}', style: TextStyle(fontSize: 18)),
                                  if (_vehicleData!['is_urgent']) Text('¡Urgente!', style: TextStyle(fontSize: 18, color: Colors.red)),
                                  SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse('0xff${_vehicleData!['color']['hex_code'].substring(1)}')),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text('Transiciones Permitidas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ..._allowedTransitions.map((transition) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('${transition['to_state']['name']}', style: TextStyle(fontSize: 16)),
                                trailing: ElevatedButton(
                                  onPressed: () => _showCommentSelectionModal(transition['to_state_id']),
                                  child: Text('Cambiar Estado'),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  : Center(child: Text('No se encontraron datos del vehículo.')),
    );
  }
}