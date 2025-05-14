import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Counter extends StatefulWidget {
  const Counter({super.key, required this.titulo});
  final String titulo;

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _counter = 0;
  String _randomText = "";
  String _replace = '*';
  String _toReplace = 'o';
  int _incrementSize = 1;
  double _emojiSize = 60.0;
  final Random _random = Random();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadCounterFromFirestore();
  }

  Future<void> _loadCounterFromFirestore() async {
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("data")
        .doc("Counter")
        .get();

    if (doc.exists) {
      setState(() {
        _counter = doc.data()?["counter"] ?? 0;
        _randomText = doc.data()?["randomText"] ?? "";
        _emojiSize = 60.0 + (_counter * _incrementSize).toDouble();
        _emojiSize = _emojiSize.clamp(40.0, 120.0);
      });
    }
  }

  Future<void> _saveCounterToFirestore() async {
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("data")
        .doc("Counter");
    try {
      await docRef.set({
        'counter': _counter,
        'randomText': _randomText,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error guardando datos: $e");
    }
  }



  String _getRandomChar() {
    int asciiCode = _random.nextInt(24) + 98; // de la a a la z
    return String.fromCharCode(asciiCode);
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      _randomText += _getRandomChar();
      _emojiSize += _incrementSize;
      _emojiSize = _emojiSize.clamp(40.0, 120.0);
    });
    _saveCounterToFirestore();
  }

  void _removeCharacter() {
    if (_randomText.isNotEmpty) {
      setState(() {
        _counter--;
        _randomText = _randomText.substring(0, _randomText.length - _incrementSize);
        _emojiSize -= 5;
        _emojiSize = _emojiSize.clamp(40.0, 120.0);
      });
      _saveCounterToFirestore();
    }
  }

  void _replaceG() {
    setState(() {
      _randomText = _randomText.replaceAll(_toReplace, _replace);
    });
    _saveCounterToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.titulo),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _removeCharacter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _emojiSize,
                height: _emojiSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber,
                ),
                child: Text(
                  "🐱",
                  style: TextStyle(fontSize: _emojiSize * 0.6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Contador: $_counter',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _randomText.isEmpty ? "Texto vacío" : _randomText,
              style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _replaceG,
              child: Text("Reemplazar '$_toReplace' por $_replace"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
