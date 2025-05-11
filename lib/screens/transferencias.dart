import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Transferencias extends StatefulWidget {
  const Transferencias({super.key});

  @override
  State<Transferencias> createState() => _TransferenciasState();
}

class _TransferenciasState extends State<Transferencias> {
  static const Color bbvaBlue = Color(0xFF0033A0);
  final TextEditingController _emailController = TextEditingController();
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

  Future<void> _transfer() async {
    final recipientEmail = _emailController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (recipientEmail.isEmpty || amount == null || amount <= 0) {
      _showMessage("Verifica los campos");
      return;
    }

    if (uid == null || _balance < amount) {
      _showMessage("Saldo insuficiente");
      return;
    }

    final recipientQuery = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: recipientEmail)
        .limit(1)
        .get();

    if (recipientQuery.docs.isEmpty) {
      _showMessage("Usuario no encontrado");
      return;
    }

    final recipientDoc = recipientQuery.docs.first;
    final recipientId = recipientDoc.id;

    if (recipientId == uid) {
      _showMessage("No puedes transferirte a ti mismo");
      return;
    }

    final senderRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final recipientRef = FirebaseFirestore.instance.collection("users").doc(recipientId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final senderSnap = await transaction.get(senderRef);
      final newSenderBalance = (senderSnap.data()?["balance"] ?? 0).toDouble() - amount;

      if (newSenderBalance < 0) {
        throw Exception("Saldo insuficiente durante transacción");
      }

      transaction.update(senderRef, {"balance": newSenderBalance});
      transaction.update(recipientRef, {
        "balance": FieldValue.increment(amount),
      });
    });

    await _registerTransaction("Transferencia", amount, recipientEmail, recipientId);

    setState(() {
      _balance -= amount;
      _emailController.clear();
      _amountController.clear();
    });

    _showMessage("Transferencia exitosa");
  }

  Future<void> _registerTransaction(String type, double amount, String recipientEmail, String recipientId) async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null) return;

    final now = Timestamp.now();

    final senderRef = FirebaseFirestore.instance
        .collection("users")
        .doc(sender.uid)
        .collection("transactions");

    final recipientRef = FirebaseFirestore.instance
        .collection("users")
        .doc(recipientId)
        .collection("transactions");

    await senderRef.add({
      "type": type,
      "amount": amount,
      "date": now,
      "description": "A: $recipientEmail",
    });

    await recipientRef.add({
      "type": "Ingreso",
      "amount": amount,
      "date": now,
      "description": "De: ${sender.email}",
    });
  }


  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transferir")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Saldo disponible: \$${_balance.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bbvaBlue),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo del destinatario"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto a transferir"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _transfer,
              icon: const Icon(Icons.send),
              label: const Text("Transferir"),
              style: ElevatedButton.styleFrom(
                backgroundColor: bbvaBlue,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
