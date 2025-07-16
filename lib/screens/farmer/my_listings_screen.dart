import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyListingScreen extends StatefulWidget {
  const MyListingScreen({super.key});

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen> {
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Auction Live', 'Sold'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Crop Listings'),
        actions: [
          DropdownButton<String>(
            value: selectedFilter,
            items:
                filters
                    .map(
                      (filter) =>
                          DropdownMenuItem(value: filter, child: Text(filter)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => selectedFilter = value!),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('crops')
                .where('farmerId', isEqualTo: user!.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final crops =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (selectedFilter == 'Auction Live') {
                  return data['isAuction'] == true &&
                      DateTime.now().isBefore(data['endAuction'].toDate());
                } else if (selectedFilter == 'Sold') {
                  return data['status'] == 'Sold';
                }
                return true;
              }).toList();

          if (crops.isEmpty) {
            return const Center(child: Text("No crops listed yet."));
          }

          return ListView.builder(
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final data = crops[index].data() as Map<String, dynamic>;
              final docId = crops[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.grass),
                  title: Text(data['cropType'] ?? 'Unknown Crop'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['variety'] != null && data['variety'] != '')
                        Text("Variety: ${data['variety']}"),
                      Text("Qty: ${data['quantity']} quintals"),
                      Text("Price: ₹${data['basePrice']} per quintal"),
                      Text("Status: ${data['status'] ?? 'Active'}"),
                    ],
                  ),
                  trailing:
                      data['isAuction'] == true
                          ? ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/auctionDetail',
                                arguments: {'cropId': docId, 'cropData': data},
                              );
                            },
                            child: const Text("View"),
                          )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
