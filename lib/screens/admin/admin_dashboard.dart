import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<Map<String, dynamic>> fetchDashboardSummary() async {
    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final auctionsSnap =
          await FirebaseFirestore.instance
              .collection('crops')
              .where('isAuction', isEqualTo: true)
              .get();
      final bookingsSnap =
          await FirebaseFirestore.instance
              .collection('cold_storage_bookings')
              .get();
      final ordersSnap =
          await FirebaseFirestore.instance
              .collection('input_orders')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: DateTime.now().subtract(
                  Duration(days: 7),
                ),
              )
              .get();

      int farmers = 0, traders = 0, govt = 0;
      for (var doc in usersSnap.docs) {
        final type = doc.data()['role'];
        if (type == 'Farmer') {
          farmers++;
        } else if (type == 'Trader') {
          traders++;
        } else if (type == 'Government') {
          govt++;
        }
      }

      return {
        'farmers': farmers,
        'traders': traders,
        'government': govt,
        'totalUsers': farmers + traders + govt,
        'liveAuctions': auctionsSnap.size,
        'coldBookings': bookingsSnap.size,
        'ordersThisWeek': ordersSnap.size,
      };
    } catch (e, stacktrace) {
      print("❌ Error in fetchDashboardSummary: $e");
      print(stacktrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007AFF),
        title: const Text("Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Dashboard Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: fetchDashboardSummary(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("❌ Error: ${snapshot.error}"));
                }

                final data = snapshot.data!;
                //print(data);
                return Table(
                  border: TableBorder.all(color: Colors.grey),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFE7F0FF)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Metric",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Data",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Detail",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("👥 Total Users"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${data['totalUsers']} (Farmer: ${data['farmers']}, Trader: ${data['traders']}, Govt: ${data['government']})",
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Link",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("🌾 Live Auctions"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${data['liveAuctions']} active auctions",
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Link",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("❄️ Cold Storage Bookings"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("${data['coldBookings']} ongoing"),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Link",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("🛒 Input Orders"),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${data['ordersThisWeek']} placed this week",
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Link",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  adminCard("User Management", Icons.person, () {
                    Navigator.pushNamed(context, '/UserManagementScreen');
                  }),
                  adminCard("Manage Storage Units", Icons.warehouse, () {
                    Navigator.pushNamed(context, '/ManageStorageUnit');
                  }),
                  adminCard("Manage Input Inventory", Icons.shopping_cart, () {
                    Navigator.pushNamed(context, '/ManageInventory');
                  }),
                  adminCard("Auction Oversight", Icons.gavel, () {
                    Navigator.pushNamed(context, '/AuctionOversight');
                  }),
                  adminCard("Complaints", Icons.report_problem, () {
                    Navigator.pushNamed(context, '/Complaints');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: const Color(0xFFE7F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Color(0xFF007AFF)),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
