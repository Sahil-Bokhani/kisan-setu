import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_edit_storage_screen.dart';

class ManageStorageScreen extends StatelessWidget {
  const ManageStorageScreen({super.key});

  Stream<QuerySnapshot> fetchStorageUnits() {
    return FirebaseFirestore.instance
        .collection('cold_storages')
        .orderBy('storageUnitID')
        .snapshots();
  }

  Future<void> deleteStorage(String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('cold_storages')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Units'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditStorageScreen(isEdit: false),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fetchStorageUnits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final storages = snapshot.data?.docs ?? [];

          if (storages.isEmpty) {
            return const Center(child: Text('No storage units found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: storages.length,
            itemBuilder: (context, index) {
              final doc = storages[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unnamed';
              final location =
                  "${data['location']?['city'] ?? ''}, ${data['location']?['district'] ?? ''}, ${data['location']?['pincode'] ?? ''}";
              final capacity = data['capacity']?.toString() ?? '0';
              final available = data['availableSpace']?.toString() ?? '0';
              final rent = data['rent']?.toString() ?? '0';
              final status = data['status'] ?? 'Unknown';
              final imageUrl = data['imageUrl'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != "")
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        const Center(child: Icon(Icons.warehouse, size: 100)),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            status.toLowerCase(),
                            style: TextStyle(
                              color:
                                  status == 'Available'
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(location),
                      const SizedBox(height: 4),
                      Text("Capacity: $capacity quintals"),
                      Text("Available Space: $available quintals"),
                      Text("Rent: ₹$rent/day"),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AddEditStorageScreen(
                                        isEdit: true,
                                        docId: doc.id,
                                        existingData:
                                            doc.data() as Map<String, dynamic>,
                                      ),
                                ),
                              );
                            },
                            child: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => deleteStorage(doc.id, context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
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
