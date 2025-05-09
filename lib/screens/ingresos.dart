import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Ingresos extends StatefulWidget {
  const Ingresos({super.key});

  @override
  State<Ingresos> createState() => _IngresosState();
}

class _IngresosState extends State<Ingresos> {
  static const Color bbvaBlue = Color(0xFF0033A0);
  final TextEditingController _amountController = TextEditingController();
  double _balance = 0.0;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    setState(() {
      _balance = (doc.data()?["balance"] ?? 0).toDouble();
    });
  }

  Future<void> _updateBalance(double amount, bool isDeposit) async {
    if (uid == null) return;

    double newBalance = isDeposit ? _balance + amount : _balance - amount;
    if (newBalance < 0 && !isDeposit) {
      _showMessage("Saldo insuficiente");
      return;
    }

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "balance": newBalance,
    }, SetOptions(merge: true));

    await _registerTransaction(isDeposit ? "Ingreso" : "Retiro", amount);

    setState(() {
      _balance = newBalance;
      _amountController.clear();
    });

    _showMessage(isDeposit ? "Depósito exitoso" : "Retiro exitoso");
  }

  Future<void> _registerTransaction(String type, double amount) async {
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .add({
      "type": type,
      "amount": amount,
      "date": Timestamp.now(),
    });

    //Navigator.pop(context);
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingresar / Retirar")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Saldo actual: \$${_balance.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bbvaBlue),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monto",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final amount = double.tryParse(_amountController.text);
                      if (amount != null && amount > 0) {
                        _updateBalance(amount, true);
                      } else {
                        _showMessage("Ingresa un monto válido");
                      }
                    },
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text("Ingresar"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final amount = double.tryParse(_amountController.text);
                      if (amount != null && amount > 0) {
                        _updateBalance(amount, false);
                      } else {
                        _showMessage("Ingresa un monto válido");
                      }
                    },
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text("Retirar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
