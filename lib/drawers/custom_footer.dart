import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomFooter({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.car_crash),
          label: 'Nuevo Vehiculo',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Color(0xFFA64F03),
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFFF2F2F2),
      onTap: onTap,
    );
  }
}
