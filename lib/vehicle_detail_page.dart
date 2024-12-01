// lib/vehicle_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

// Definición de la paleta de colores
const Color primaryColor = Colors.white; // Fondo principal
const Color secondaryColor1 = Colors.blue; // Color principal para botones y acentos
const Color secondaryColor2 = Colors.blueAccent; // Color secundario para acentos
const Color backgroundColor = Colors.white; // Fondo general
const Color textColor = Colors.grey; // Texto principal
const Color optionsColor = Colors.grey; // Texto de opciones

/// Convierte una cadena hexadecimal a un Color
Color hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF' + hex; // Añadir alpha si no está presente
  }
  return Color(int.parse('0x$hex'));
}

class VehicleDetailPage extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailPage({Key? key, required this.vehicleId}) : super(key: key);

  @override
  _VehicleDetailPageState createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _vehicleData;
  List<Map<String, dynamic>> _allowedTransitions = [];

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
      _changeVehicleState(newStateId);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: comments.map((comment) {
            return ListTile(
              title: Text(comment['text']),
              onTap: () {
                Navigator.pop(context);
                _changeVehicleState(newStateId, commentId: comment['id']);
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Cambia el estado del vehículo
  Future<void> _changeVehicleState(int newStateId, {int? commentId}) async {
    setState(() {
      _isLoading = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.changeVehicleState(widget.vehicleId, newStateId, commentId: commentId);
      _fetchInitialData();
    } catch (e) {
      _showErrorDialog('Error al cambiar el estado del vehículo.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Muestra un diálogo de error
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Fondo general
      appBar: AppBar(
        title: Text('Detalles del Vehículo', style: TextStyle(color: textColor)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0, // Sin sombra para un aspecto más limpio
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: secondaryColor1))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: textColor, fontSize: 16)))
              : _vehicleData != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: primaryColor, // Color de fondo del card
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_vehicleData!['model']['brand']['name']} ${_vehicleData!['model']['name']}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'VIN: ${_vehicleData!['vin']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: secondaryColor1,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Estado: ${_vehicleData!['status']['name']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Color: ${_vehicleData!['color']['name']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                                  if (_vehicleData!['is_urgent'])
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '¡Urgente!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: hexToColor(_vehicleData!['color']['hex_code']),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_vehicleData!['is_urgent'] == true)
                            Card(
                              color: Color(0xFFFFF9C4), // Fondo claro para la tarjeta de urgencia
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Razón de Urgencia: ${_vehicleData!['urgency_reason']}', style: TextStyle(color: Color(0xFF262626))),
                                    Text('Observaciones: ${_vehicleData!['observations']}', style: TextStyle(color: Color(0xFF262626))),
                                    Text('Fecha de Entrega: ${_vehicleData!['urgency_delivery_date']}', style: TextStyle(color: Color(0xFF262626))),
                                    Text('Hora de Entrega: ${_vehicleData!['urgency_delivery_time']}', style: TextStyle(color: Color(0xFF262626))),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 20),
                          Text(
                            'Cambiar de estado',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          SizedBox(height: 10),
                          ..._allowedTransitions.map((transition) {
                            return Card(
                              color: secondaryColor2, // Color de fondo del card
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15.0),
                                onTap: () => _showCommentSelectionModal(transition['to_state_id']),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${transition['to_state']['name']}',
                                          style: TextStyle(color: primaryColor, fontSize: 16),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: primaryColor,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  : Center(child: Text('No se encontraron datos del vehículo.', style: TextStyle(color: textColor, fontSize: 16))),
    );
  }
}
