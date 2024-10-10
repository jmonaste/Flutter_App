import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart'; // Importa tu archivo de HomePage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

Future<void> _login() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  final String username = _usernameController.text;
  final String password = _passwordController.text;

  try {
    final response = await http.post(
      Uri.parse('http://192.168.1.45:8000/token'), // Ajusta la URL de tu API
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=password&username=$username&password=$password&scope=&client_id=&client_secret=',
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); // Decodifica la respuesta JSON
      final token = data['access_token'];
      final tokenType = data['token_type'];

      print('Token: $token');
      print('Token type: $tokenType');

      // Navegar a la página de inicio si el login es exitoso
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(token: token),  // Pasamos el token a la HomePage
        ),
      );
    } else if (response.statusCode == 401) {
      setState(() {
        _errorMessage = 'Login failed. Incorrect credentials.';
      });
    } else {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  } catch (error) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'An error occurred: $error';
    });
    print('Error: $error');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
