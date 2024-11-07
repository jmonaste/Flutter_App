import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('Por favor, introduzca tanto el nombre de usuario como la contraseña.');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.login(username, password);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      _showErrorDialog('Error al iniciar sesión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            SizedBox(height: screenHeight * .12),
            const Text(
              'Bienvenido,',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
            ),
            SizedBox(height: screenHeight * .01),
            Text(
              'Inicia sesión para continuar',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF262626).withOpacity(.6),
              ),
            ),
            SizedBox(height: screenHeight * .12),
            TextField(
              controller: _usernameController,
              style: TextStyle(color: Color(0xFFA64F03)), // Color del texto introducido
              decoration: InputDecoration(
                labelText: 'Nombre de usuario',
                labelStyle: TextStyle(color: Color(0xFFA64F03)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFA64F03)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFA64F03)),
                ),
              ),
            ),
            SizedBox(height: screenHeight * .025),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: Color(0xFFA64F03)), // Color del texto introducido
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: TextStyle(color: Color(0xFFA64F03)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFA64F03)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFA64F03)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Color(0xFF262626),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * .075,
            ),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF2CB05),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * .15,
            ),
            TextButton(
              onPressed: () {},
              child: RichText(
                text: const TextSpan(
                  text: 'Soy un nuevo usuario, ',
                  style: TextStyle(color: Color(0xFF262626)),
                  children: [
                    TextSpan(
                      text: 'Regístrate',
                      style: TextStyle(
                        color: Color(0xFFA64F03),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}