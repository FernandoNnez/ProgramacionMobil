import 'package:flutter/material.dart';
import 'screens//welcome.dart';
import 'screens/calculator.dart';
import 'screens/locator.dart';
import 'screens/counter.dart';
import 'screens/handshake.dart';
import 'screens/calendar.dart';
import 'screens/person.dart';

class Navegador extends StatefulWidget {
  const Navegador({super.key});

  @override
  State<Navegador> createState() => _NavegadorState();
}

class _NavegadorState extends State<Navegador> {
  int _paginaActual = 0;
  String _nombreUsuario = "";
  
  void _cambiarPagina(int index, [String nombre = ""]) {
    setState(() {
      _paginaActual = index;
      if (nombre.isNotEmpty) {
        _nombreUsuario = nombre;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      Calculator(titulo: "Calculadora"),
      Welcome(titulo: "Bienvenida", cambiarPagina: _cambiarPagina),
      Handshake(titulo: "Saludo", nombre: _nombreUsuario, cambiarPagina: _cambiarPagina), // Pasa la fx
      Counter(titulo: "Contador"),
      Locator(titulo: "Localizador"),
      Calendar(titulo: "Calendario"),
      Person(titulo: "Person")
    ];

    return Scaffold(
      body: _screens[_paginaActual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _paginaActual,
        onTap: (index) => _cambiarPagina(index), // Cambiooooooo
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculadora',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Bienvenida',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Saludo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Contador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Localización',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Person',
          ),
        ],
      ),
    );
  }
}
