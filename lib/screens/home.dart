import 'package:bbba/screens/ingresos.dart';
import 'package:bbba/screens/transferencias.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const Color bbvaBlue = Color(0xFF0033A0);
  static const Color bbvaLightGray = Color(0xFFF5F5F5);

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

  Stream<List<Map<String, dynamic>>> _getRecentTransactions() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .orderBy("date", descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  String _monthName(int month) {
    const months = [
      "Ene", "Feb", "Mar", "Abr", "May", "Jun",
      "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Inicio"),
        centerTitle: true,
        backgroundColor: bbvaBlue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Saldo dinámico
            const Text(
              "Saldo disponible",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              "\$${_balance.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: bbvaBlue,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Movimientos recientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getRecentTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final transactions = snapshot.data ?? [];

                  if (transactions.isEmpty) {
                    return const Center(child: Text("Sin movimientos recientes"));
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final type = tx["type"] ?? "";
                      final amount = tx["amount"] ?? 0.0;
                      final date = (tx["date"] as Timestamp?)?.toDate();
                      final formattedDate = date != null
                          ? "${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}"
                          : "";

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            type == "Ingreso" ? Icons.arrow_downward : Icons.arrow_upward,
                            color: type == "Ingreso" ? Colors.green : Colors.redAccent,
                          ),
                          title: Text(type),
                          subtitle: Text(formattedDate),
                          trailing: Text(
                            "${type == "Ingreso" ? "+" : "-"}\$${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: type == "Ingreso" ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => Ingresos(),
                      ));
                      _loadBalance(); // Actualiza el saldo al regresar
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text("Ingresar / Retirar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bbvaBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => Transferencias(),
                      ));
                      _loadBalance(); // Actualiza el saldo al regresar
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("Transferir"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bbvaBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
