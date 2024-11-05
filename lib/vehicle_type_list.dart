// lib/vehicle_type_list.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'package:dio/dio.dart'; // Importa Dio
import 'api_service.dart'; // Importa ApiService
import 'custom_drawer.dart'; // Importa CustomDrawer si lo usas

class VehicleTypeListPage extends StatefulWidget {
  const VehicleTypeListPage({Key? key}) : super(key: key);

  @override
  _VehicleTypeListPageState createState() => _VehicleTypeListPageState();
}

class _VehicleTypeListPageState extends State<VehicleTypeListPage> {
  List<dynamic> vehicleTypes = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicleTypes(); // Llamada automática al cargar la página
  }

  /// Obtiene la lista de tipos de vehículos desde la API y las ordena alfabéticamente
  Future<void> _fetchVehicleTypes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/vehicle-types/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        setState(() {
          vehicleTypes = data.map((vehicleType) {
            return {
              'id': vehicleType['id'],
              'type_name': vehicleType['type_name'],
              'created_at': vehicleType['created_at'],
              'updated_at': vehicleType['updated_at'],
            };
          }).toList();
        });
      } else {
        setState(() {
          errorMessage = 'Error al obtener los tipos de vehículos. Estado: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Actualiza un tipo de vehículo
  Future<void> _updateVehicleType(int id, String newTypeName) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.put(
        '/api/vehicle-types/$id',
        data: {'type_name': newTypeName},
      );

      if (response.statusCode == 200) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualización exitosa')),
        );
        _fetchVehicleTypes(); // Actualizar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el tipo de vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el tipo de vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Elimina un tipo de vehículo
  Future<void> _deleteVehicleType(int id) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.delete('/api/vehicle-types/$id');

      if (response.statusCode == 200) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eliminación exitosa')),
        );
        _fetchVehicleTypes(); // Actualizar la lista después de la eliminación
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el tipo de vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el tipo de vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Añade un nuevo tipo de vehículo
  Future<void> _addVehicleType(String typeName) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.post(
        '/api/vehicle-types/',
        data: {'type_name': typeName},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tipo de vehículo añadido exitosamente')),
        );
        _fetchVehicleTypes(); // Actualiza la lista de tipos después de añadir
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir el tipo de vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir el tipo de vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Muestra un diálogo con opciones para actualizar o eliminar un tipo
  void _showOptionsDialog(int id, String typeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            '¿Qué quieres hacer con "$typeName"?',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUpdateDialog(id, typeName); // Mostrar el diálogo de actualización
              },
              child: Text('Actualizar', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteDialog(id, typeName); // Mostrar el diálogo de eliminación
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para actualizar el nombre de un tipo de vehículo
  void _showUpdateDialog(int id, String currentTypeName) {
    final TextEditingController _controller = TextEditingController(text: currentTypeName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Actualizar Tipo de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre del tipo de vehículo',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(color: Colors.white), // Texto del campo blanco
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Actualizar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                String newTypeName = _controller.text.trim();
                if (newTypeName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _updateVehicleType(id, newTypeName); // Llamar a la API para actualizar
                } else {
                  // Muestra un mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El nombre del tipo de vehículo no puede estar vacío'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para confirmar la eliminación de un tipo de vehículo
  void _showDeleteDialog(int id, String typeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Eliminar Tipo de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "$typeName"?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await _deleteVehicleType(id); // Llama a la función para eliminar el tipo
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para añadir un nuevo tipo de vehículo
  void _showAddDialog() {
    TextEditingController typeNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Añadir Nuevo Tipo de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: TextField(
            controller: typeNameController,
            decoration: InputDecoration(
              hintText: 'Nombre del tipo de vehículo',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            style: TextStyle(color: Colors.white), // Texto del campo blanco
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Añadir', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                String typeName = typeNameController.text.trim();
                if (typeName.isNotEmpty) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  await _addVehicleType(typeName); // Llama a la función para añadir el tipo
                } else {
                  // Muestra un mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El nombre del tipo de vehículo no puede estar vacío'),
                    ),
                  );
                }
              },
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
        centerTitle: true,
      ),
      drawer: CustomDrawer(
        userName: 'Nombre del usuario',
        onProfileTap: () {
          // Lógica para ver el perfil
        },
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage, style: TextStyle(color: Colors.red)),
                )
              : ListView.builder(
                  itemCount: vehicleTypes.length,
                  itemBuilder: (context, index) {
                    final vehicleType = vehicleTypes[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Align(
                          alignment: Alignment.center, // Centramos el texto dentro del ListTile
                          child: Text(vehicleType['type_name']),
                        ),
                        onTap: () {
                          _showOptionsDialog(vehicleType['id'], vehicleType['type_name']);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(); // Llamamos a _showAddDialog cuando se presiona el botón
        },
        tooltip: 'Añadir nuevo tipo de vehículo',
        backgroundColor: Colors.blue, // Cambiar color de fondo a azul
        child: Icon(Icons.add, color: Colors.white), // Ícono blanco
      ),
    );
  }
}
