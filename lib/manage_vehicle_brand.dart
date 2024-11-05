// lib/manage_vehicle_brand.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'package:dio/dio.dart'; // Importa Dio
import 'api_service.dart'; // Importa ApiService
import 'custom_drawer.dart'; // Importa CustomDrawer si lo usas

class VehicleBrandManagePage extends StatefulWidget {
  const VehicleBrandManagePage({Key? key}) : super(key: key);

  @override
  _VehicleBrandManagePageState createState() => _VehicleBrandManagePageState();
}

class _VehicleBrandManagePageState extends State<VehicleBrandManagePage> {
  List<dynamic> vehicleBrands = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicleBrands(); // Llamada automática al cargar la página
  }

  /// Obtiene la lista de marcas de vehículos desde la API y las ordena alfabéticamente
  Future<void> _fetchVehicleBrands() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/brands/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // Mapear y ordenar las marcas alfabéticamente por nombre
        List<dynamic> sortedBrands = data.map((brand) {
          return {
            'id': brand['id'],
            'name': brand['name'],
            'created_at': brand['created_at'],
            'updated_at': brand['updated_at'],
          };
        }).toList();

        sortedBrands.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));

        setState(() {
          vehicleBrands = sortedBrands;
        });
      } else {
        setState(() {
          errorMessage =
              'Error al obtener las marcas de vehículos. Estado: ${response.statusCode}';
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

  /// Actualiza una marca de vehículo
  Future<void> _updateVehicleBrand(int id, String newBrandName) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.put(
        '/api/brands/$id',
        data: {'name': newBrandName},
      );

      if (response.statusCode == 200) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualización exitosa')),
        );
        _fetchVehicleBrands(); // Actualizar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la marca del vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la marca del vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Elimina una marca de vehículo
  Future<void> _deleteVehicleBrand(int id) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.delete('/api/brands/$id');

      if (response.statusCode == 200) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eliminación exitosa')),
        );
        _fetchVehicleBrands(); // Actualizar la lista después de la eliminación
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la marca del vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la marca del vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Añade una nueva marca de vehículo
  Future<void> _addVehicleBrand(String brandName) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.post(
        '/api/brands/',
        data: {'name': brandName},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marca de vehículo añadida exitosamente')),
        );
        _fetchVehicleBrands(); // Actualiza la lista de marcas después de añadir
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir la marca del vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir la marca del vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Muestra un diálogo con opciones para actualizar o eliminar una marca
  void _showOptionsDialog(int id, String brandName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            '¿Qué quieres hacer con "$brandName"?',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUpdateDialog(id, brandName); // Mostrar el diálogo de actualización
              },
              child: Text('Actualizar', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteDialog(id, brandName); // Mostrar el diálogo de eliminación
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para actualizar el nombre de una marca
  void _showUpdateDialog(int id, String currentBrandName) {
    final TextEditingController _controller =
        TextEditingController(text: currentBrandName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Actualizar Marca de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Nuevo nombre de la marca',
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
              child:
                  Text('Actualizar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                String newBrandName = _controller.text.trim();
                if (newBrandName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _updateVehicleBrand(id, newBrandName); // Llamar a la API para actualizar
                } else {
                  // Muestra un mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('El nombre de la marca no puede estar vacío')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para confirmar la eliminación de una marca
  void _showDeleteDialog(int id, String brandName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Eliminar Marca de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "$brandName"?',
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
              child:
                  Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await _deleteVehicleBrand(id); // Llama a la función para eliminar la marca
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para añadir una nueva marca
  void _showAddDialog() {
    TextEditingController brandNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Añadir Nueva Marca de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: TextField(
            controller: brandNameController,
            decoration: InputDecoration(
              hintText: 'Nombre de la marca',
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
                String brandName = brandNameController.text.trim();
                if (brandName.isNotEmpty) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  await _addVehicleBrand(brandName); // Llama a la función para añadir la marca
                } else {
                  // Muestra un mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('El nombre de la marca no puede estar vacío')),
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
        title: Text('Marcas de Vehículos'),
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
                  child:
                      Text(errorMessage, style: TextStyle(color: Colors.red)),
                )
              : ListView.builder(
                  itemCount: vehicleBrands.length,
                  itemBuilder: (context, index) {
                    final vehicleBrand = vehicleBrands[index];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Align(
                          alignment:
                              Alignment.center, // Centramos el texto dentro del ListTile
                          child: Text(vehicleBrand['name']),
                        ),
                        onTap: () {
                          _showOptionsDialog(
                              vehicleBrand['id'], vehicleBrand['name']);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(); // Llamamos a _showAddDialog cuando se presiona el botón
        },
        tooltip: 'Añadir nueva marca de vehículo',
        backgroundColor: Colors.blue, // Cambiar color de fondo a azul
        child: Icon(Icons.add, color: Colors.white), // Ícono blanco
      ),
    );
  }
}
