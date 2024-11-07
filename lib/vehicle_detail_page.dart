// lib/vehicle_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

// Definición de la paleta de colores
const Color primaryColor = Color(0xFFF2F2F2); // #A64F03
const Color secondaryColor1 = Color(0xFFF2CB05); // #F2CB05
const Color secondaryColor2 = Color(0xFFF2B33D); // #F2B33D
const Color backgroundColor = Color(0xFFF2F2F2); // #F2F2F2
const Color textColor = Color(0xFF262626); // #262626
const Color optionsColor = Colors.grey;

//const Color primaryColor = Color(0xFFA64F03); // #A64F03


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
              backgroundColor: backgroundColor, // Fondo del diálogo
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                'Seleccionar Comentario',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: comments.map((comment) {
                    return RadioListTile<int>(
                      title: Text(
                        comment['comment'],
                        style: TextStyle(
                          color: optionsColor
                          ),
                      ),
                      value: comment['id'],
                      groupValue: selectedCommentId,
                      activeColor: secondaryColor2,
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
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: textColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor2, // Color de fondo del botón
                  ),
                  onPressed: selectedCommentId == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _changeVehicleState(newStateId, selectedCommentId!);
                        },
                  child: Text(
                    'Aceptar',
                    style: TextStyle(color: textColor),
                  ),
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
          title: Text('Error', style: TextStyle(color: primaryColor)),
          content: Text(message, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
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
                              borderRadius: BorderRadius.circular(10),
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
                                  Text('VIN: ${_vehicleData!['vin']}', style: TextStyle(fontSize: 18, color: Color(0xFFA64F03))),
                                  Text('Estado: ${_vehicleData!['status']['name']}', style: TextStyle(fontSize: 18, color: textColor)),
                                  Text('Color: ${_vehicleData!['color']['name']}', style: TextStyle(fontSize: 18, color: textColor)),
                                  if (_vehicleData!['is_urgent'])
                                    Text(
                                      '¡Urgente!',
                                      style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _showCommentSelectionModal(transition['to_state_id']),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${transition['to_state']['name']}',
                                          style: TextStyle(color: backgroundColor, fontSize: 16),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: backgroundColor,
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
