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
      _changeVehicleState(newStateId);
      _fetchInitialData(); // Refrescar los datos del vehículo
      _showSuccessDialog('Estado actualizado correctamente.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedCommentId;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: primaryColor, // Fondo del diálogo más claro
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0), // Bordes más suaves
              ),
              title: Text(
                'Seleccionar Comentario',
                style: TextStyle(
                  color: textColor, // Color del título
                  fontSize: 20, // Tamaño de fuente más grande
                  fontWeight: FontWeight.w600, // Peso de fuente más ligero
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: comments.map((comment) {
                    return RadioListTile<int>(
                      title: Text(
                        comment['comment'],
                        style: TextStyle(
                          color: optionsColor, // Color del texto de opciones
                          fontSize: 16,
                        ),
                      ),
                      value: comment['id'],
                      groupValue: selectedCommentId,
                      activeColor: secondaryColor2, // Color activo del radio
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
                    style: TextStyle(
                      color: textColor, // Color del texto del botón
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor1, // Color de fondo del botón
                  ),
                  onPressed: selectedCommentId == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _changeVehicleState(newStateId, commentId: selectedCommentId!);
                          _showSuccessDialog('Estado actualizado correctamente.');
                        },
                  child: Text(
                    'Aceptar',
                    style: TextStyle(
                      color: primaryColor, // Texto del botón en blanco
                      fontSize: 16,
                    ),
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
  Future<void> _changeVehicleState(int newStateId, {int? commentId}) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.changeVehicleState(widget.vehicleId, newStateId, commentId: commentId);
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
          backgroundColor: primaryColor, // Fondo más claro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Error',
            style: TextStyle(
              color: secondaryColor1, // Color del título
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: textColor, // Color del contenido
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: secondaryColor1, // Color del texto del botón
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo de éxito
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor, // Fondo más claro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Bordes más suaves
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green, // Icono verde para indicar éxito
              ),
              SizedBox(width: 10),
              Text(
                'Éxito',
                style: TextStyle(
                  color: textColor, // Color del título
                  fontSize: 20, // Tamaño de fuente más grande
                  fontWeight: FontWeight.w600, // Peso de fuente más ligero
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: textColor, // Color del contenido
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: secondaryColor1, // Color del texto del botón
                  fontSize: 16,
                ),
              ),
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
