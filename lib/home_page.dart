import 'package:flutter/material.dart';
import 'vehicle_type_list.dart';
import 'camera_page.dart';
import 'custom_drawer.dart';  // Importa el CustomDrawer
import 'custom_footer.dart';  // Importa el CustomFooter

class HomePage extends StatefulWidget {
  final String token;  // El token es pasado a la pantalla HomePage

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
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
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
        drawer: CustomDrawer(
          userName: 'Nombre del usuario',
          onProfileTap: () {
            // Lógica para ver el perfil
          },
          token: widget.token,  // Aquí pasamos el token requerido por el CustomDrawer
        ),
        body: Center(
          child: Text(
            'Bienvenido a la página de inicio',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        bottomNavigationBar: CustomFooter(
          selectedIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
