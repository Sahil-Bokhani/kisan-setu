import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_edit_inventory_screen.dart';

class ManageInputInventoryScreen extends StatelessWidget {
  const ManageInputInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditInventoryScreen(isEdit: false),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('store_items').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return const Center(child: Text("No inventory items available."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final id = items[index].id;

              final name = item['name'] ?? '';
              final type = item['type'] ?? '';
              final price = item['price']?.toString() ?? '0';
              final quantity = item['quantity']?.toString() ?? '0';
              final imageUrl = item['imageUrl'];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      imageUrl != ""
                          ? Image.network(
                            imageUrl,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                          : Container(
                            height: 100,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image, size: 40),
                            ),
                          ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        type,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      Text("₹$price", style: const TextStyle(fontSize: 14)),
                      Text(
                        "$quantity units",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AddEditInventoryScreen(
                                        isEdit: true,
                                        existingData: item,
                                        docId: id,
                                      ),
                                ),
                              );
                            },
                            child: const Text("Edit"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text("Delete Item"),
                                      content: const Text(
                                        "Are you sure you want to delete this item?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm) {
                                await FirebaseFirestore.instance
                                    .collection('store_items')
                                    .doc(id)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Item deleted")),
                                );
                              }
                            },
                            child: const Text("Delete"),
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
