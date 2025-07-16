import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cold_storage_booking_screen.dart';

class ColdStorageListScreen extends StatefulWidget {
  const ColdStorageListScreen({super.key});

  @override
  State<ColdStorageListScreen> createState() => _ColdStorageListScreenState();
}

class _ColdStorageListScreenState extends State<ColdStorageListScreen> {
  bool showAvailableOnly = false;

  Stream<QuerySnapshot> fetchStorages() {
    var ref = FirebaseFirestore.instance.collection('cold_storages');
    if (showAvailableOnly) {
      return ref.where('isAvailable', isEqualTo: true).snapshots();
    }
    return ref.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cold Storage List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              setState(() {
                showAvailableOnly = !showAvailableOnly;
              });
            },
            tooltip: "Filter by Availability",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchStorages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final storages = snapshot.data?.docs ?? [];

          if (storages.isEmpty) {
            return const Center(child: Text("No cold storages available."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: storages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final storage = storages[index].data() as Map<String, dynamic>;

              final name = storage['name'] ?? 'N/A';
              final rent = storage['rent'] ?? 0;
              final status = storage['status'] ?? 'N/A';
              final available = storage['available_space'] ?? 0;
              final capacity = storage['capacity'] ?? 0;
              final location = storage['location']?['district'] ?? 'Unknown';
              final imageUrl = storage['imageUrl'];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Container(
                            height: 90,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.warehouse, size: 40),
                            ),
                          ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text("📍 $location"),
                            Text(
                              "Capacity: $capacity qtl",
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Available: $available qtl",
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Rent: ₹$rent/day",
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Status: $status",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ColdStorageBookingScreen(
                                      storageData: storage,
                                    ),
                              ),
                            );
                          },
                          child: const Text("Book Now"),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
