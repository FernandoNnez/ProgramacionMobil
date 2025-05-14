import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  final Function(int, String) cambiarPagina; // fx de nav
  const Welcome({super.key, required this.titulo, required this.cambiarPagina});
  final String titulo;

  @override
  State<Welcome> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Welcome> {
  final TextEditingController _controller = TextEditingController();

  void _irASaludo() {
    String nombre = _controller.text;
    if (nombre.isNotEmpty) {
      widget.cambiarPagina(2, nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "¡Hola! Escribe tu nombre:",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Tu nombre aquí",
                ),
              ),
            ),
            const SizedBox(height: 20),
            MaterialButton(
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
              onPressed: _irASaludo,
              child: const Text("Ir a Saludo"),
            ),
          ],
        ),
      ),
    );
  }
}
