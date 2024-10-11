import 'package:flutter/material.dart';

class VehicleTypeListPage extends StatelessWidget {
  final List<dynamic> vehicleTypes;

  const VehicleTypeListPage({Key? key, required this.vehicleTypes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tipos de Vehículos'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: vehicleTypes.length,
            itemBuilder: (context, index) {
              final vehicleType = vehicleTypes[index];
              final vehicleTypeId = vehicleType['id']; // Guardamos el ID para futuras operaciones
              final vehicleTypeName = vehicleType['type_name']; // Sólo mostramos el nombre

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    vehicleTypeName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.more_vert),
                  onTap: () {
                    // Muestra un diálogo con opciones de Actualizar o Eliminar
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Acciones'),
                          content: Text('¿Qué deseas hacer con este tipo de vehículo?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // Acción para actualizar el tipo de vehículo con el ID disponible
                                Navigator.of(context).pop(); // Cerrar el diálogo
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Función de actualizar no implementada')),
                                );
                              },
                              child: Text('Actualizar'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Acción para eliminar el tipo de vehículo con el ID disponible
                                Navigator.of(context).pop(); // Cerrar el diálogo
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Función de eliminar no implementada')),
                                );
                              },
                              child: Text('Eliminar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            bottom: 20, // Espacio desde la parte inferior de la pantalla
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Acción para añadir un nuevo tipo de vehículo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Función de añadir nuevo tipo no implementada')),
                  );
                },
                child: Text('Añadir nuevo tipo de vehículo'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
