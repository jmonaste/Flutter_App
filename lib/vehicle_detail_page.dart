// lib/vehicle_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'package:dio/dio.dart'; // Importa Dio
import 'api_service.dart'; // Importa ApiService
import 'custom_drawer.dart'; // Importa CustomDrawer si lo usas
import 'custom_footer.dart'; // Importa CustomFooter si lo usas
import 'home_page.dart'; // Importa HomePage si lo necesitas

// Modelo para representar un comentario predefinido
class StateComment {
  final int id;
  final int stateId;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  StateComment({
    required this.id,
    required this.stateId,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StateComment.fromJson(Map<String, dynamic> json) {
    return StateComment(
      id: json['id'],
      stateId: json['state_id'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// Modelo para representar una transición permitida
class Transition {
  final int id;
  final int fromStateId;
  final int toStateId;
  final String name; // Nombre del estado de destino

  Transition({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required this.name,
  });

  factory Transition.fromJson(Map<String, dynamic> json) {
    return Transition(
      id: json['id'],
      fromStateId: json['from_state_id'],
      toStateId: json['to_state_id'],
      name: json['name'] ?? 'Estado Desconocido',
    );
  }
}

class VehicleDetailPage extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailPage({
    Key? key,
    required this.vehicleId,
  }) : super(key: key);

  @override
  VehicleDetailPageState createState() => VehicleDetailPageState();
}

class VehicleDetailPageState extends State<VehicleDetailPage> {
  Map<String, dynamic>? _vehicleData;
  Map<String, dynamic>? _currentState;
  List<Transition> _allowedTransitions = [];
  Map<int, String> _stateNames = {}; // Cache de nombres de estados
  bool _isLoading = true; // Variable para manejar el estado de carga
  String _errorMessage = '';

  // Variables para manejar los comentarios predefinidos
  List<StateComment> _stateComments = [];
  bool _isCommentsLoading = false;
  String _commentsErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// Obtiene datos del vehículo, detalles de estados y estado actual
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // Realizar las llamadas a la API en paralelo
      await Future.wait([
        _fetchVehicleData(apiService),
        _fetchStatesDetails(apiService),
        _fetchCurrentState(apiService),
      ]);

      // Una vez obtenidos los nombres de los estados, obtener las transiciones permitidas
      await _fetchAllowedTransitions(apiService);
    } catch (e) {
      print('Error al obtener los datos iniciales: $e');
      _showErrorDialog('Error al cargar los datos. Por favor, inténtelo más tarde.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Obtiene los datos del vehículo desde la API
  Future<void> _fetchVehicleData(ApiService apiService) async {
    try {
      final response = await apiService.dio.get('/api/vehicles/${widget.vehicleId}/');

      if (response.statusCode == 200) {
        final vehicleJson = response.data;
        setState(() {
          _vehicleData = vehicleJson;
        });
      } else {
        throw Exception('Error al obtener los datos del vehículo. Estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener los datos del vehículo: $e');
    }
  }

  /// Obtiene los detalles de los estados desde la API
  Future<void> _fetchStatesDetails(ApiService apiService) async {
    try {
      final response = await apiService.dio.get('/api/states/');

      if (response.statusCode == 200) {
        final List<dynamic> statesJson = response.data;
        final Map<int, String> statesMap = {
          for (var state in statesJson)
            if (state['id'] != null && state['name'] != null) state['id']: state['name'],
        };
        setState(() {
          _stateNames = statesMap;
        });
      } else {
        throw Exception('Error al obtener los detalles de los estados. Estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener los detalles de los estados: $e');
    }
  }

  /// Obtiene el estado actual del vehículo desde la API
  Future<void> _fetchCurrentState(ApiService apiService) async {
    try {
      final response = await apiService.dio.get('/api/vehicles/${widget.vehicleId}/current_state/');

      if (response.statusCode == 200) {
        final currentStateJson = response.data;
        setState(() {
          _currentState = currentStateJson;
        });
      } else {
        throw Exception('Error al obtener el estado actual del vehículo. Estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener el estado actual del vehículo: $e');
    }
  }

  /// Obtiene las transiciones permitidas desde la API
  Future<void> _fetchAllowedTransitions(ApiService apiService) async {
    try {
      final response = await apiService.dio.get('/api/vehicles/${widget.vehicleId}/allowed_transitions/');

      if (response.statusCode == 200) {
        final List<dynamic> transitionsJson = response.data;
        final List<Transition> transitions = transitionsJson.map((transition) {
          return Transition.fromJson({
            'id': transition['id'],
            'from_state_id': transition['from_state_id'],
            'to_state_id': transition['to_state_id'],
            'name': _stateNames[transition['to_state_id']] ?? 'Estado Desconocido',
          });
        }).toList();

        setState(() {
          _allowedTransitions = transitions;
        });
      } else {
        print('Error al obtener las transiciones permitidas. Estado: ${response.statusCode}');
        // No lanzamos una excepción aquí para permitir que la página se cargue incluso si las transiciones fallan
      }
    } catch (e) {
      print('Error al obtener las transiciones permitidas: $e');
      // No lanzamos una excepción aquí para permitir que la página se cargue incluso si las transiciones fallan
    }
  }

  /// Maneja la navegación en la barra de navegación inferior
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } else if (index == 2) {
      // Lógica para el botón "Cuenta" (puedes implementar esto según tus necesidades)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Funcionalidad de Cuenta en desarrollo.')),
      );
    }
    // Actualizar el estado solo si se cambia el índice
    setState(() {
      // _selectedIndex = index; // Si tienes un estado de índice seleccionado
    });
  }

  /// Muestra un diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Error', style: TextStyle(color: Colors.white)),
          content: Text(message, style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Regresa a la página anterior
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para seleccionar un comentario y cambiar el estado
  void _showChangeStateDialog(int toStateId) async {
    // Obtiene los comentarios predefinidos para el estado de destino
    await _fetchStateComments(toStateId);

    if (_stateComments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay comentarios predefinidos para este estado.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        StateComment? selectedComment; // Variable local para la selección

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text('Selecciona un comentario', style: TextStyle(color: Colors.white)),
              content: _isCommentsLoading
                  ? SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _commentsErrorMessage.isNotEmpty
                      ? Text(_commentsErrorMessage, style: TextStyle(color: Colors.redAccent))
                      : Container(
                          width: double.maxFinite, // Asegura que el desplegable ocupe el ancho disponible
                          child: DropdownButtonFormField<StateComment>(
                            isExpanded: true, // Permite que el desplegable ocupe todo el ancho
                            items: _stateComments.map((StateComment comment) {
                              return DropdownMenuItem<StateComment>(
                                value: comment,
                                child: Text(
                                  comment.comment,
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (StateComment? newValue) {
                              setState(() {
                                selectedComment = newValue;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Comentario',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: Colors.grey[850],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
                  onPressed: selectedComment == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await _changeVehicleState(toStateId, selectedComment!.comment);
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Obtiene los comentarios predefinidos para un estado específico
  Future<void> _fetchStateComments(int stateId) async {
    setState(() {
      _isCommentsLoading = true;
      _commentsErrorMessage = '';
      _stateComments = [];
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.get('/api/states/$stateId/comments/');

      if (response.statusCode == 200) {
        final List<dynamic> commentsJson = response.data;
        final List<StateComment> comments = commentsJson.map((comment) {
          return StateComment.fromJson(comment);
        }).toList();

        setState(() {
          _stateComments = comments;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _commentsErrorMessage = 'Estado no encontrado.';
        });
      } else {
        setState(() {
          _commentsErrorMessage = 'Error al obtener los comentarios del estado.';
        });
      }
    } catch (e) {
      setState(() {
        _commentsErrorMessage = 'Error al obtener los comentarios del estado.';
      });
    }

    setState(() {
      _isCommentsLoading = false;
    });
  }

  /// Cambia el estado del vehículo mediante una llamada a la API
  Future<void> _changeVehicleState(int toStateId, String commentText) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print('Vehicle ID: ${widget.vehicleId}');
    print('New State ID: $toStateId');
    print('Comment Text: $commentText');

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // Construir la URL con los query parameters
      final response = await apiService.dio.post(
        '/api/vehicles/${widget.vehicleId}/change_state/',
        queryParameters: {
          'vehicle_id': widget.vehicleId.toString(),
          'new_state_id': toStateId.toString(),
          'comments': commentText,
        },
      );

      if (response.statusCode == 200) {
        // Estado cambiado exitosamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado del vehículo actualizado exitosamente')),
        );
        await _fetchVehicleData(apiService); // Actualiza los datos del vehículo
        await _fetchAllowedTransitions(apiService); // Actualiza las transiciones permitidas
        await _fetchCurrentState(apiService); // Actualiza el estado actual
      } else if (response.statusCode == 400) {
        final errorJson = response.data;
        _showErrorDialog(errorJson['detail'] ?? 'Error al cambiar el estado del vehículo.');
      } else if (response.statusCode == 404) {
        final errorJson = response.data;
        _showErrorDialog(errorJson['detail'] ?? 'Estado o comentario no encontrado.');
      } else {
        print('Error al cambiar el estado del vehículo. Estado: ${response.statusCode}');
        _showErrorDialog('Error al cambiar el estado del vehículo. Por favor, inténtelo más tarde.');
      }
    } catch (e) {
      print('Excepción al cambiar el estado del vehículo: $e');
      _showErrorDialog('Error al cambiar el estado del vehículo. Por favor, inténtelo más tarde.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalles del Vehículo',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      drawer: CustomDrawer(
        userName: 'Nombre del usuario', // Reemplaza con el nombre real del usuario
        onProfileTap: () {
          // Lógica para ver el perfil (puedes implementarla según tus necesidades)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Funcionalidad de perfil en desarrollo.')),
          );
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : _vehicleData == null || _currentState == null
                  ? Center(
                      child: Text(
                        'No se pudieron cargar los datos del vehículo.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tarjeta con información básica del vehículo
                            Card(
                              color: Colors.grey[850],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      label: 'VIN',
                                      value: _vehicleData?['vin'] ?? 'Sin VIN',
                                    ),
                                    _buildDetailRow(
                                      label: 'Marca y Modelo',
                                      value:
                                          '${_stateNames[_vehicleData?['model']?['brand']?['id']] ?? 'Marca Desconocida'} ${_vehicleData?['model']?['name'] ?? 'Modelo Desconocido'}',
                                    ),
                                    _buildUrgentRow(),
                                    _buildDetailRow(
                                      label: 'Estado Actual',
                                      value: _currentState?['name'] ?? 'Estado Desconocido',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Sección de transiciones permitidas
                            Text(
                              'Transiciones Permitidas:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            _allowedTransitions.isEmpty
                                ? Center(
                                    child: Text(
                                      'No hay transiciones permitidas disponibles.',
                                      style: TextStyle(color: Colors.white70, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Column(
                                    children: _allowedTransitions.map((transition) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _showChangeStateDialog(transition.toStateId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue, // Color del botón
                                              foregroundColor: Colors.white, // Color del texto
                                              padding: EdgeInsets.symmetric(vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Ir a ${transition.name}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: 1, // Índice seleccionado (puedes ajustar esto según tu lógica)
        onTap: _onItemTapped,
      ),
    );
  }

  /// Construye una fila de detalle con etiqueta y valor
  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una fila para mostrar si el vehículo es urgente
  Widget _buildUrgentRow() {
    bool isUrgent = _vehicleData?['is_urgent'] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            'Urgente: ',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Icon(
            isUrgent ? Icons.warning_amber_rounded : Icons.check_circle,
            color: isUrgent ? Colors.redAccent : Colors.greenAccent,
            size: 18,
          ),
        ],
      ),
    );
  }
}
