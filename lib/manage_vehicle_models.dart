// lib/manage_vehicle_models.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'package:dio/dio.dart'; // Importa Dio
import 'api_service.dart'; // Importa ApiService
import 'custom_drawer.dart'; // Importa CustomDrawer si lo usas

class VehicleModelManagePage extends StatefulWidget {
  const VehicleModelManagePage({Key? key}) : super(key: key);

  @override
  _VehicleModelManagePageState createState() => _VehicleModelManagePageState();
}

class _VehicleModelManagePageState extends State<VehicleModelManagePage> {
  List<dynamic> vehicleModels = [];
  List<dynamic> vehicleBrands = [];
  List<dynamic> vehicleTypes = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVehicleBrands(); // Obtener marcas primero
    _fetchVehicleTypes();  // Obtener tipos de vehículos
    _fetchVehicleModels(); // Obtener modelos después
  }

  /// Obtiene la lista de marcas de vehículos desde la API
  Future<void> _fetchVehicleBrands() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/brands/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        List<dynamic> sortedBrands = data.map((brand) {
          return {
            'id': brand['id'],
            'name': brand['name'],
            'created_at': brand['created_at'],
            'updated_at': brand['updated_at'],
          };
        }).toList();

        sortedBrands.sort((a, b) =>
            a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));

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
    }
  }

  /// Obtiene la lista de tipos de vehículos desde la API
  Future<void> _fetchVehicleTypes() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/vehicle-types/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        List<dynamic> sortedTypes = data.map((type) {
          return {
            'id': type['id'],
            'type_name': type['type_name'],
            'created_at': type['created_at'],
            'updated_at': type['updated_at'],
          };
        }).toList();

        sortedTypes.sort((a, b) =>
            a['type_name'].toString().toLowerCase().compareTo(b['type_name'].toString().toLowerCase()));

        setState(() {
          vehicleTypes = sortedTypes;
        });
      } else {
        setState(() {
          errorMessage =
              'Error al obtener los tipos de vehículos. Estado: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
    }
  }

  /// Obtiene la lista de modelos de vehículos desde la API y los ordena alfabéticamente
  Future<void> _fetchVehicleModels() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.dio.get('/api/models/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // Mapear y ordenar los modelos alfabéticamente por nombre
        List<dynamic> sortedModels = data.map((model) {
          return {
            'id': model['id'],
            'name': model['name'], // Usar 'name' en lugar de 'Model_name'
            'brand_id': model['brand_id'],
            'brand_name': model['brand']['name'], // Nombre de la marca asociada
            'type_id': model['type_id'],
            'type_name': _getTypeNameById(model['type_id']), // Nombre del tipo asociado
            'created_at': model['created_at'],
            'updated_at': model['updated_at'],
          };
        }).toList();

        sortedModels.sort((a, b) =>
            a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));

        setState(() {
          vehicleModels = sortedModels;
        });
      } else {
        setState(() {
          errorMessage =
              'Error al obtener los modelos de vehículos. Estado: ${response.statusCode}';
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

  /// Obtiene el nombre del tipo de vehículo por su ID
  String _getTypeNameById(int typeId) {
    final type = vehicleTypes.firstWhere(
        (element) => element['id'] == typeId,
        orElse: () => {'type_name': 'Desconocido'});
    return type['type_name'];
  }

  /// Actualiza un modelo de vehículo
  Future<void> _updateVehicleModel(int id, String newModelName, int newBrandId, int newTypeId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.put(
        '/api/models/$id',
        data: {
          'name': newModelName,
          'brand_id': newBrandId,
          'type_id': newTypeId,
        },
      );

      if (response.statusCode == 200) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualización exitosa')),
        );
        _fetchVehicleModels(); // Actualizar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el modelo de vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el modelo de vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Elimina un modelo de vehículo
  Future<void> _deleteVehicleModel(int id) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.delete('/api/models/$id');

      if (response.statusCode == 200) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eliminación exitosa')),
        );
        _fetchVehicleModels(); // Actualizar la lista después de la eliminación
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el modelo de vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el modelo de vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Añade un nuevo modelo de vehículo
  Future<void> _addVehicleModel(String modelName, int brandId, int typeId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final response = await apiService.dio.post(
        '/api/models/',
        data: {
          'name': modelName,
          'brand_id': brandId,
          'type_id': typeId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Muestra un mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modelo de vehículo añadido exitosamente')),
        );
        _fetchVehicleModels(); // Actualiza la lista de modelos después de añadir
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir el modelo de vehículo')),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir el modelo de vehículo')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Muestra un diálogo con opciones para actualizar o eliminar un modelo
  void _showOptionsDialog(int id, String modelName, int brandId, int typeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            '¿Qué quieres hacer con "$modelName"?',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUpdateDialog(id, modelName, brandId, typeId); // Mostrar el diálogo de actualización
              },
              child: Text('Actualizar', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteDialog(id, modelName); // Mostrar el diálogo de eliminación
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para actualizar el nombre, marca y tipo de un modelo
  void _showUpdateDialog(int id, String currentModelName, int currentBrandId, int currentTypeId) {
    final TextEditingController _controller =
        TextEditingController(text: currentModelName);
    int selectedBrandId = currentBrandId;
    int selectedTypeId = currentTypeId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Actualizar Modelo de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Nuevo nombre del modelo',
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
                SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedBrandId,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Marca',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  iconEnabledColor: Colors.white,
                  items: vehicleBrands.map<DropdownMenuItem<int>>((brand) {
                    return DropdownMenuItem<int>(
                      value: brand['id'],
                      child: Text(
                        brand['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      selectedBrandId = newValue;
                    }
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedTypeId,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Tipo',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  iconEnabledColor: Colors.white,
                  items: vehicleTypes.map<DropdownMenuItem<int>>((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'],
                      child: Text(
                        type['type_name'],
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      selectedTypeId = newValue;
                    }
                  },
                ),
              ],
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
              child: Text('Actualizar',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                String newModelName = _controller.text.trim();
                if (newModelName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _updateVehicleModel(id, newModelName, selectedBrandId, selectedTypeId);
                } else {
                  // Muestra un mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'El nombre del modelo no puede estar vacío')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para confirmar la eliminación de un modelo
  void _showDeleteDialog(int id, String modelName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Eliminar Modelo de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "$modelName"?',
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
                await _deleteVehicleModel(id); // Llama a la función para eliminar el modelo
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para añadir un nuevo modelo
  void _showAddDialog() {
    final TextEditingController _modelNameController = TextEditingController();
    int? selectedBrandId;
    int? selectedTypeId;

    if (vehicleBrands.isNotEmpty) {
      selectedBrandId = vehicleBrands[0]['id'];
    }

    if (vehicleTypes.isNotEmpty) {
      selectedTypeId = vehicleTypes[0]['id'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Fondo oscuro para mejor contraste
          title: Text(
            'Añadir Nuevo Modelo de Vehículo',
            style: TextStyle(color: Colors.white), // Título blanco
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _modelNameController,
                  decoration: InputDecoration(
                    hintText: 'Nombre del modelo',
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
                SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedBrandId,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Marca',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  iconEnabledColor: Colors.white,
                  items: vehicleBrands.map<DropdownMenuItem<int>>((brand) {
                    return DropdownMenuItem<int>(
                      value: brand['id'],
                      child: Text(
                        brand['name'],
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      selectedBrandId = newValue;
                    }
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedTypeId,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Tipo',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  iconEnabledColor: Colors.white,
                  items: vehicleTypes.map<DropdownMenuItem<int>>((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'],
                      child: Text(
                        type['type_name'],
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      selectedTypeId = newValue;
                    }
                  },
                ),
              ],
            ),
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
                  Text('Añadir', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                String modelName = _modelNameController.text.trim();
                if (modelName.isNotEmpty && selectedBrandId != null && selectedTypeId != null) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  await _addVehicleModel(modelName, selectedBrandId!, selectedTypeId!); // Llama a la función para añadir el modelo
                } else {
                  // Muestra un mensaje de error si los campos están vacíos
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'El nombre del modelo, la marca y el tipo no pueden estar vacíos')),
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
        title: Text('Modelos de Vehículos'),
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
                  itemCount: vehicleModels.length,
                  itemBuilder: (context, index) {
                    final vehicleModel = vehicleModels[index];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Align(
                          alignment:
                              Alignment.center, // Centramos el texto dentro del ListTile
                          child: Text('${vehicleModel['name']} - ${vehicleModel['brand_name']} - ${vehicleModel['type_name']}'),
                        ),
                        onTap: () {
                          _showOptionsDialog(
                            vehicleModel['id'],
                            vehicleModel['name'],
                            vehicleModel['brand_id'],
                            vehicleModel['type_id'],
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (vehicleBrands.isNotEmpty && vehicleTypes.isNotEmpty) {
            _showAddDialog(); // Llamamos a _showAddDialog cuando se presiona el botón
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No hay marcas o tipos disponibles. Añade primero una marca y un tipo.')),
            );
          }
        },
        tooltip: 'Añadir nuevo modelo de vehículo',
        backgroundColor: Colors.blue, // Cambiar color de fondo a azul
        child: Icon(Icons.add, color: Colors.white), // Ícono blanco
      ),
    );
  }
}
