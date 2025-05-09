import 'dart:math';
import 'package:flutter/material.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key, required this.titulo});
  final String titulo;

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _input = "";
  String _output = "0";

  void _pressButton(String v) {
    setState(() {
      if (_esOperador(v) && (_input.isEmpty || _ultimoEsOperador())) {
        return;
      }
      if (v == "." && _ultimoNumeroTienePunto()) return;
      if (v == "=") {
        _calcula();
        return;
      }
      _input += v;
    });
  }

  dynamic convertirSiEsEntero(String numeroStr) {
    double numero = double.tryParse(numeroStr) ?? double.nan;

    if (numero.isNaN) return "Error: No es un número válido";

    return numero % 1 == 0 ? numero.toInt() : numero;
  }

  bool _esOperador(String v) {
    return ["+", "-", "x", "/", "%", "^"].contains(v);
  }

  bool _ultimoEsOperador() {
    if (_input.isEmpty) return false;
    String lastChar = _input[_input.length - 1];
    return _esOperador(lastChar);
  }

  bool _ultimoNumeroTienePunto() {
    List<String> partes = _input.split(RegExp(r"[+\-x/%^]"));
    if (partes.isEmpty) return false;
    return partes.last.contains(".");
  }

  void _calcula() {
    try {
      String expresion = _input.replaceAll("x", "*");
      List<String> tokens = expresion.split(RegExp(r"(\+|\-|\*|\/|\%|\^)"));
      List<String> operadores = expresion.split(RegExp(r"[0-9.]+")).where((e) => e.isNotEmpty).toList();
      if (tokens.length < 2 || operadores.length < 1) return;

      List<double> numeros = tokens.map((e) => double.parse(e)).toList();
      List<String> ops = List.from(operadores);

      while (ops.contains("^")) {
        int i = ops.indexOf("^");
        numeros[i] = pow(numeros[i], numeros[i + 1]).toDouble();
        numeros.removeAt(i + 1);
        ops.removeAt(i);
      }
      while (ops.contains("%")) {
        int i = ops.indexOf("%");
        numeros[i] = numeros[i] % numeros[i + 1];
        numeros.removeAt(i + 1);
        ops.removeAt(i);
      }
      while (ops.contains("*") || ops.contains("/")) {
        int i = ops.indexWhere((op) => op == "*" || op == "/");
        if (ops[i] == "/" && numeros[i + 1] == 0) {
          _output = "Error";
          return;
        }
        numeros[i] = ops[i] == "*" ? numeros[i] * numeros[i + 1] : numeros[i] / numeros[i + 1];
        numeros.removeAt(i + 1);
        ops.removeAt(i);
      }
      while (ops.isNotEmpty) {
        numeros[0] = ops[0] == "+" ? numeros[0] + numeros[1] : numeros[0] - numeros[1];
        numeros.removeAt(1);
        ops.removeAt(0);
      }
      _output = convertirSiEsEntero(numeros.first.toString()).toString();
    } catch (e) {
      print(e);
      _output = "Error";
    }
    setState(() {});
  }

  void _limpiar() {
    setState(() {
      _input = "";
      _output = "0";
    });
  }

  void _borrar() {
    setState(() {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 350,
              padding: const EdgeInsets.all(15),
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_input.isEmpty ? "0" : _input, style: const TextStyle(fontSize: 25, color: Colors.white)),
                  Text(_output, style: const TextStyle(fontSize: 40, color: Colors.lightGreenAccent)),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _crearFila(["C", "⌫", "%", "/"]),
                _crearFila(["7", "8", "9", "x"]),
                _crearFila(["4", "5", "6", "-"]),
                _crearFila(["1", "2", "3", "+"]),
                _crearFila(["0", ".", "^", "="]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearFila(List<String> valores) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: valores.map((texto) {
        return Padding(
          padding: const EdgeInsets.all(5),
          child: MaterialButton(
            height: 80,
            minWidth: 80,
            color: Theme.of(context).primaryColor,
            child: Text(
              texto,
              style: const TextStyle(fontSize: 35, color: Colors.white),
            ),
            onPressed: () {
              if (texto == "C") {
                _limpiar();
              } else if (texto == "⌫") {
                _borrar();
              } else {
                _pressButton(texto);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}