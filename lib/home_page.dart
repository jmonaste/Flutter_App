import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String token;

  HomePage({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login Successful!',
              style: TextStyle(fontSize: 24, color: Colors.green),
            ),
            SizedBox(height: 20),
            Text(
              'Your token:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              token,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Puedes agregar acciones adicionales aquí
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
