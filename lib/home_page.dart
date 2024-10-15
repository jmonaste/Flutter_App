import 'package:flutter/material.dart';
import 'vehicle_type_list.dart'; // Importa la página donde listarás los tipos de vehículos
import 'camera_page.dart'; // Importa la página de la cámara

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Lógica de navegación según el índice seleccionado
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleTypeListPage(token: widget.token),
        ),
      );
    } else if (index == 2) {
      // Lógica para el botón "Cuenta"
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark().copyWith(
          primary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: Colors.black87,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            backgroundColor: Colors.blueAccent, // Color de fondo del botón
            foregroundColor: Colors.white, // Color del texto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Home', style: Theme.of(context).textTheme.titleLarge),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
        ),
        drawer: Drawer(
          backgroundColor: Colors.grey[850], // Fondo gris oscuro del sidebar
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                ),
                child: Row(
                  children: [
                    // CircleAvatar para la imagen de perfil (comentado temporalmente)
                    /*
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/profile_picture.png'), // Comentado temporalmente
                    ),
                    */
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[700], // Color gris mientras no hay imagen
                      child: Icon(Icons.person, color: Colors.white, size: 30), // Ícono temporal
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Nombre del usuario',
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                        GestureDetector(
                          onTap: () {
                            // Lógica para ver el perfil
                          },
                          child: Text('Ver perfil',
                              style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[600], thickness: 1),
              ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text('Inicio', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text('Configuraciones', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Acción de configuración
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Acción de cerrar sesión
                },
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleTypeListPage(token: widget.token),
                    ),
                  );
                },
                child: Text('Gestionar tipos de vehículos', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20), // Espaciado entre botones
              ElevatedButton(
                onPressed: () {
                  // Acción para gestionar marcas
                },
                child: Text('Gestionar marcas', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Acción para gestionar modelos
                },
                child: Text('Gestionar modelos', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Acción para gestionar vehículos
                },
                child: Text('Gestionar vehículos', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(token: widget.token),
                    ),
                  );
                },
                child: Text('Añadir nuevo vehículo', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Administrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Cuenta',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.black87,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
