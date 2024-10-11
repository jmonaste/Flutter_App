import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VehicleTypeListPage extends StatefulWidget {
  final String token;

  const VehicleTypeListPage({Key? key, required this.token}) : super(key: key);

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

  Future<void> _fetchVehicleTypes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.45:8000/api/vehicle-types/'),
        headers: <String, String>{
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

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
          errorMessage = 'Error fetching vehicle types';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateVehicleType(int id, String newTypeName) async {
    final response = await http.put(
      Uri.parse('http://192.168.1.45:8000/api/vehicle-types/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode(<String, String>{'type_name': newTypeName}),
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
  }

  Future<void> _deleteVehicleType(int id) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.45:8000/api/vehicle-types/$id'),
      headers: <String, String>{
        'Authorization': 'Bearer ${widget.token}',
      },
    );

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
  }

  Future<void> _addVehicleType(String typeName) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.45:8000/api/vehicle-types'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode(<String, String>{
        'type_name': typeName,
      }),
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
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tipos de Vehículos'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                itemCount: vehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicleType = vehicleTypes[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Align(
                        alignment: Alignment.center,  // Centramos el texto dentro del ListTile
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
          _showAddDialog();  // Llamamos a _showAddDialog cuando se presiona el botón
        },
        
        tooltip: 'Añadir nuevo tipo de vehículo',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showOptionsDialog(int id, String typeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¿Qué quieres hacer con "$typeName"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUpdateDialog(id, typeName); // Mostrar el diálogo de actualización
              },
              child: Text('Actualizar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteDialog(id, typeName); // Lógica para eliminar el tipo de vehículo (puedes implementarla después)
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(int id, String currentTypeName) {
    final TextEditingController _controller = TextEditingController(text: currentTypeName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Actualizar Tipo de Vehículo'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Nuevo nombre del tipo de vehículo'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Actualizar'),
              onPressed: () {
                String newTypeName = _controller.text;
                Navigator.of(context).pop();
                _updateVehicleType(id, newTypeName); // Llamar a la API para actualizar
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(int id, String typeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Tipo de Vehículo'),
          content: Text('¿Estás seguro de que deseas eliminar "$typeName"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Eliminar'),
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

  void _showAddDialog() {
    TextEditingController typeNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Añadir Nuevo Tipo de Vehículo'),
          content: TextField(
            controller: typeNameController,
            decoration: InputDecoration(hintText: 'Nombre del tipo de vehículo'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Añadir'),
              onPressed: () async {
                String typeName = typeNameController.text.trim();
                if (typeName.isNotEmpty) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  await _addVehicleType(typeName); // Llama a la función para añadir el tipo
                } else {
                  // Muestra un mensaje de error si el campo está vacío
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('El nombre del tipo de vehículo no puede estar vacío')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  } 

}
