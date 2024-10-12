import 'package:flutter/material.dart';
import 'dart:io';


class ScanResultPage extends StatelessWidget {
  final String imagePath;

  const ScanResultPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultado del Escaneo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Aquí se procesará la imagen para escanear el código.'),
            SizedBox(height: 20),
            Image.file(File(imagePath)),
          ],
        ),
      ),
    );
  }
}
